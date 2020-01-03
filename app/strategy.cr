class Strategy
  CHANGE = 2 # %
  MINUTES = 10.minutes



  def self.arbitrage
    begin
      fastestes = ["xrp","nano","eos","steem","xlm","bits"]
      last_btc_in_usd = Market.last_value_from("usdt-btc")

     #loop do
       sleep 1

        cryptopia = get("https://www.cryptopia.co.nz", "/api/GetMarkets/BTC")
        bittrex = get("https://bittrex.com", "/api/v1.1/public/getmarketsummaries")

        cryptopia["Data"].each do |c|
          bittrex["result"].each do |b|
            coin = c["Label"].to_s.split("/")[0]
            # only fastests

          #  if fastestes.includes?(coin.downcase)
             market = b["MarketName"]

          #  hist[coin] = 0.0
            if b["MarketName"] == "BTC-#{coin}"
              last_c = c["LastPrice"].to_s.to_f64
              last_b = b["Last"].to_s.to_f64
              perc = from_value = to_value  = 0
              from = to = ""
              if last_c < last_b
                from = "c"; to = "b"
                perc = percentage(last_c, last_b)
                from_value = last_c
                to_value = last_b
              else
                from = "b"; to = "c"
                from_value = last_b
                to_value = last_c
                perc = percentage(last_b, last_c)
              end

              if perc > 5 && perc < 100
                count = total = 0
                puts "=> #{market} | #{from}->#{to} | #{from_value}->#{to_value} | +#{perc}%".colorize(:yellow)# if hist[coin]>0 || hist[coin]!=perc
              #  hist[coin] = perc
                cryptopia_history(coin)[0..15].each do |h|
                  price = h["Price"].to_s.to_f64
                  qtd = h["Total"].to_s.to_f64
                  ago = as_time_ago(Time.parse(h["Timestamp"].to_s, "%s") - (Time.now + 2.hours))
                  puts "#{ago} | #{price} | #{percentage(from_value, price)}% | #{percentage(to_value, price)}% | $#{qtd*last_btc_in_usd}".colorize(h["Type"] == "Sell" ? :red : :green)
                #end
                line
                  if price > last_c
                    count += 1
                    qtd = h["Total"].to_s.to_f64
                    puts "+#{percentage(last_c, price)}% | $#{qtd*last_btc_in_usd}"
                    total += qtd
                  end
                end
                puts total*last_btc_in_usd if total > 0
                line
               end
             end
            end

          #end
      #  end
      end

      #puts "#{bigger} #{market} +#{perc} | #{cryptopia} / #{bittrex}".colorize(:green) if perc > 10 && perc < 200 && bigger=="cryptopia"
    rescue e
      puts e.colorize(:red)
    end
  end

  def self.cryptopia_history(currency)
    json = get("https://www.cryptopia.co.nz", "/api/GetMarketHistory/#{currency.upcase}_BTC/2")
    Logger.log(json.to_pretty_json)
    json["Data"].to_a.sort_by!{|e| e["Timestamp"].to_s.to_i}.reverse
  end

  def self.market_exists?(market, markets)
    markets.each{|m| return true if m.marketname==market}
    false
  end

  def self.observe(market)
    from, currency = market.split("-")
    start = Time.now
    begin
      proto = Tick.from_market(market)
      # to avoid inconsistent ticket data, it needs to be confirmed 5x
      confirmations = 0
      loop do
        sleep 2
        actual = Tick.from_market(market)
        last_change = percentage(proto.last, actual.last)
        elapsed = Time.now - start

        # pump detector | comprar se subiu 3% em 5 minutos e TODO ha 10% mais buy orders
        if last_change >= CHANGE
          if elapsed < MINUTES
            diff = actual.last - proto.last
            unless diff.to_s.includes?("e") # avoid micro changes
              confirmations+=1
              if confirmations==5
                m_summary = Market.fetch(market)
                spread = actual.ask - actual.bid
                wall = percentage(m_summary.opensellorders, m_summary.openbuyorders)
                #Wallet.buy_in_dolar_from_btc(currency, 100)
                Logger.log("| #{market} | +#{last_change}% in #{as_time_ago(elapsed)} | +#{diff} | #{m_summary.openbuyorders - m_summary.opensellorders} buy/sell = #{wall}% | #{spread} spread", :sims)
                confirmations = 0
                break
              end
            end
          else
            # reset elapsed
            proto = Tick.from_market(market)
          end
        else
          # reset confirmations
          confirmations = 0
        end

        # TODO: sell orders if they drop 2%

      end
    rescue err
      #Logger.log "#{market} | #{err}", error: true
    end
  end


  def self.get(host, url)
    json = JSON.parse(HTTP::Client.new(URI.parse(host)).get(url).body)
    Logger.log(json.to_pretty_json)
    json
  end
end
