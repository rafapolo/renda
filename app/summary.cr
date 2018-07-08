class Summary

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
    openbuyorders: Int64,
    opensellorders: Int64,
    prevday: Float64,
    created: String
  })

  def self.updated
    Array(Summary).from_json(Broker.get("public/getmarketsummaries"))
  end

  def self.monitor!
    count = 0
    protos = Summary.updated
    protos.each{|p| count +=1 if p.marketname.starts_with?("btc") }
    btc_usd = select_by_market(protos, "usdt-btc").last
    puts "Observing #{count} markets...".colorize(:yellow)
    cache = {} of String => Float64
    loop do
      begin
        Summary.updated.each do |atual|
          market = atual.marketname

          #if market.starts_with?("btc")
            proto = select_by_market(protos, market)
            cache[market] = 0.0 unless cache.has_key?(market)
            perc = percentage(proto.last, atual.last)
            if atual.openbuyorders > atual.opensellorders * 2
        #    if perc > 5 && perc < 50 && cache[market] != perc
              cache[market] = perc
              ago = as_time_ago(as_time(atual.timestamp) - as_time(proto.timestamp))
              puts "#{ago} | #{market} | +#{perc}% | #{proto.last} -> #{atual.last}".colorize(:green)
              puts "#{atual.opensellorders} sell | #{atual.openbuyorders} buy".colorize(:blue)
              # orderbook = JSON.parse(Broker.get("/public/getorderbook", "market=#{market}&type=both"))
              # # analise sell offers
              # total = 0.0
              # count = 0
              # sells = orderbook["sell"].to_a.sort_by{|s| s["rate"].to_s.to_f64}.reverse
              # sells.each do |sell|
              #   rate = sell["rate"].to_s.to_f64
              #   if rate < atual.last
              #     qtd = sell["quantity"].to_s.to_f64
              #     selling = as_dolar(rate*qtd*btc_usd)
              #     puts "-> #{rate} | #{qtd}x | #{selling}...".colorize(:red)
              #     total += (rate*qtd)
              #     count+=1
              #   end
              # end
              # under_in_usd = as_dolar(total * btc_usd)
              # puts "##{count} offers at #{under_in_usd} < #{atual.last}".colorize(:yellow) if count > 0
              # # analise buy offers
              # total = 0.0
              # count = 0
              # buys = orderbook["buy"].to_a.sort_by{|s| s["rate"].to_s.to_f64}.reverse
              # buys.each do |buy|
              #   rate = buy["rate"].to_s.to_f64
              #   if rate > proto.last
              #     qtd = buy["quantity"].to_s.to_f64
              #     buying = as_dolar(rate*qtd*btc_usd)
              #     puts "+> #{rate} | #{qtd}x | #{buying}...".colorize(:green)
              #     total += (rate*qtd)
              #     count+=1
              #   end
              # end
              # atual_in_usd = as_dolar(total * btc_usd)
              # puts "##{count} offers at #{atual_in_usd} > #{proto.last}".colorize(:yellow) if count > 0
              # puts
              # pegar history
              # TODO : https://bittrex.com/api/v1.1/public/getmarkethistory?market=BTC-DOGE
            end
        #  end
        end
      rescue err
        puts err.colorize(:red)
      end
      sleep 1
    end
  end

  def self.select_by_market(array, marketname)
    selected = uninitialized Summary
    array.each do |m|
      if m.marketname == marketname
        selected = m
        break
      end
    end
    selected
  end

  # singleton class
  def self.instance
    @@instance ||= new
  end


end
