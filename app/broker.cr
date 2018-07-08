require "base64"
require "json"
require "time"
require "openssl/hmac"
require "colorize"
require "http/client"
require "pretty_print"
require "./config"

require "./market"
require "./order"
require "./helper"

class Broker
  @@requests_count = 0.as(Int32)

  HOST = "https://bittrex.com/api/v1.1"
  KEY = "ze41874d3706c4d98be6a2206bbbe41eaf" # example! change it.
  PVT = "d4b67bf4bbbca4f56bfe99103ee352671g" # example! change it.
  # for reference
  WALLET = "s15dTUuy2zawbcgkgrc9Cnsa13t9YWaVSJus" # example! change it.


  def self.get(method, params = nil, retry_count=0) #todo: retry as param++
    start_time = Time.now
    client = HTTP::Client.new(URI.parse(HOST))
    url = "#{HOST}/#{method}"
    Logger.log "-> #{method} #{params}"

    # sign non-public requests
    unless method.starts_with?("public")
      url += "?apikey=#{KEY}&nonce=#{start_time.epoch_ms}&#{params}"
      apisign = OpenSSL::HMAC.hexdigest(:sha512, PVT, url)
      headers = HTTP::Headers{"apisign" => apisign}
    else
      url += "?#{params}"
    end

    result = nil
    begin
      @@requests_count += 1
      response = client.get(url, headers: headers)
      return again!(method, params, retry_count) unless response && response.body
      json = JSON.parse(response.body.downcase)
      #TODO: fix downcase Hash keys | fucks wallet addrs
      if json["success"]
        result = json["result"]
        return again!(method, params, retry_count) if result.to_pretty_json == "null"
      else
        Logger.log "API error: #{json["message"]}", error: true
      end
      elapsed = Time.now - start_time
      Logger.log "(#{elapsed.seconds}s#{elapsed.milliseconds}ms)".colorize(:yellow)
      Logger.log "<- #{result.to_pretty_json}"
    rescue err
      puts
      Logger.log "=> #{err} on #{method}\nfor #{url}", error: true
      Logger.log json.to_pretty_json
      puts
      return again!(method, params, retry_count) if err.to_s.includes? "reset"
    end
    client.close
    result.to_json
  end

  def self.again!(method, params, retry_count)
    raise "Tryed to request 3x in vain" if retry_count==3
    # Logger.log "=> retry #{method} #{params}", error: true
    self.get(method, params, retry_count+=1)
  end

  def self.requests_count
    @@requests_count.as(Int32)
  end

  # singleton class
  def self.instance
    @@instance ||= new
  end

end
