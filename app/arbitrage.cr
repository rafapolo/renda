class Arbitrage

  def self.make(from_broker, to_broker, currency, value)
    puts "=> transfer $#{value} of #{currency.upcase} from #{from_broker} to #{to_broker}".colorize(:green)
    # actual values
    from_broker_value = to_broker_value = 0
    if from_broker == "cryptopia"
      from_broker_value = last_from_cryptopia(currency)
      to_broker_value = last_from_bittrex(currency)
    else
      from_broker_value = last_from_bittrex(currency)
      to_broker_value = last_from_cryptopia(currency)
    end
    perc = percentage(from_broker_value, to_broker_value)
    last_btc_in_usd = Market.last_value_from("usdt-btc")
    puts "=> #{from_broker} | #{from_broker_value} ฿ | $#{from_broker_value*last_btc_in_usd}".colorize(:yellow)
    puts "=> #{to_broker} | #{to_broker_value} ฿ | $#{to_broker_value*last_btc_in_usd}".colorize(:yellow)
    puts "=> +#{perc}% difference".colorize(:green)

    exchange_fee = value * 0.02 # 0.2%
    neto = value - exchange_fee
    #puts "=> -$#{exchange_fee} exchange fee | $#{neto}".colorize(:red)
    in_currency = ((1/from_broker_value)/last_btc_in_usd)*neto
    in_btc = neto/last_btc_in_usd
    puts "=> #{in_btc} ฿ => #{in_currency} #{currency.upcase}".colorize(:yellow)
    count = total = 0
    buy_orders = get_buy_orders(currency)
    #puts "#{buy_orders.size} buy orders:"
    buy_orders.each do |buy|
      price = buy["Price"].to_s.to_f64
      if price > from_broker_value
        count += 1
        qtd = buy["Total"].to_s.to_f64
        puts "+#{percentage(from_broker_value, price)}% | $#{qtd*last_btc_in_usd}"
        total += qtd
      end
    end
    line
    to_buy_usd = total*last_btc_in_usd
    # quanto investir?
    # (potencial / 2) + 0.25% exchange + 0.2 coin" transfer
    puts "0.2'' = #{(1/from_broker_value)*0.2} "
    puts "#{count} buyers with $#{to_buy_usd}" if total > 0
    line

    # transfer
    #TODO: API send
    #0.002
    #puts "=> -$#{exchange_fee} fee | $#{neto}".colorize(:red)
  end

  def self.get_buy_orders(currency)
    json = JSON.parse(get("https://www.cryptopia.co.nz", "/api/GetMarketOrders/#{currency.upcase}_BTC"))
    Logger.log(json.to_pretty_json)
    json["Data"]["Buy"]
  end

  def self.last_from_cryptopia(currency)
    json = JSON.parse(get("https://www.cryptopia.co.nz", "/api/GetMarket/#{currency}_BTC"))
    Logger.log(json.to_pretty_json)
    json["Data"]["LastPrice"].to_s.to_f64
  end

  def self.last_from_bittrex(market)
    json = JSON.parse(get("https://bittrex.com/", "/api/v1.1/public/getmarketsummary?market=btc-#{market}"))
    Logger.log(json.to_pretty_json)
    json["result"].first["Last"].to_s.to_f64
  end

  def self.get(host, url)
    HTTP::Client.new(URI.parse(host)).get(url).body
  end

  def self.market_exists?(market, markets)
    markets.each{|m| return true if m.marketname==market}
    false
  end
end
# 
# Arbitrage.potential_markets.each do |c|
#   Arbitrage.make("bittrex", "cryptopia", c, 100)
#   line
# end
