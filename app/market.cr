require "./helper"
require "./tick"

class Market
  @@all = [] of Market

  JSON.mapping({
    marketname: String,
    high: Float64,
    low: Float64,
    volume: Float64,
    last: Float64,
    basevolume: Float64,
    timestamp: String,
    bid: Float64,
    ask: Float64,
    openbuyorders: Float64,
    opensellorders: Float64,
    prevday: Float64,
    created: String
    # new attrs ?
  })

  def self.all(format=nil)
    return @@all unless @@all.empty?
    @@all = Array(Market).from_json(Broker.get("public/getmarketsummaries"))
    if format
      x = 0
      @@all.each do |m|
        puts "#{x+=1} # {m.marketname} \t #{percentage(m.openbuyorders, m.opensellorders)}% spread \t| change: #{percentage(m.prevday, m.last)}%".colorize(:yellow)
      end
    end
    @@all
  end

  def self.fetch(market) : Market
    Array(Market).from_json(Broker.get("public/getmarketsummary", "market=#{market}")).first
  end

  def self.exists?(market)
    self.all.each{|m| return true if m.marketname==market}
    false
  end

  def self.last_value_from(market)
    last_tick = Tick.from_json(Broker.get("public/getticker", "market=#{market.downcase}"))
    last_tick.last
  end

  def self.btc_to_dolar_of_date(datetime) : Float64
    result = 0.0
    begin
      # date_in_btc = JSON.parse(File.read("log/orders.json"))[currency][datetime.to_s].to_s.to_f64
      # result = date_in_btc * last_value_from("usdt-btc")
      url = "/public?command=returnChartData&currencyPair=USDT_BTC&start=#{(datetime - 1.hour).epoch}&end=#{datetime.epoch}&period=86400"
      client = HTTP::Client.new(URI.parse("https://poloniex.com"))
      Logger.log "-> #{url}"
      result = JSON.parse(client.get(url).body).first["weightedAverage"].to_s.to_f64.as(Float64)
      client.close
    rescue err
      Logger.log(err, error: true)
    end
    result
  end

  def self.convert(market, value : Float64)
    Market.fetch(market).last * value
  end

  def self.convert_to_dolar(currency, value)
    return value if currency == "usdt"
    value_in_btc = currency=="btc" ? value :  self.convert("btc-#{currency}", value)
    btc_in_dolar = Market.last_value_from("usdt-btc")
    value_in_btc * btc_in_dolar
  end

  def self.observe_all
    # btcs_markets = all.reject{|m| !m.marketname.starts_with?("btc")}
    # puts "=> observing #{all.size} markets"
    # btcs_markets.each do |m|
    #   spawn do
    #     Strategy.observe(m.marketname)
    #   end
    # end
    # Fiber.yield
    # sleep
  end

  def self.follow(market, invested=1, proto=nil)
    proto = Market.last_value_from(market) unless proto
    in_usd = Market.last_value_from("usdt-btc")
    puts "Follow #{market.upcase} at #{proto}...".colorize(:yellow)
    loop do
      value = Market.last_value_from(market)
      perc = percentage(proto, value)
      puts "#{perc}% | #{as_dolar(in_usd*value*invested)}"
      sleep 1
    end
  end

  def orderbook(market)
    #TODO: /public/getorderbook
  end

  def history(market)
    #TODO: /public/getmarkethistory
  end

  def self.currencies
    get("public/getcurrencies")
    #TODO: template as array
  end

end
