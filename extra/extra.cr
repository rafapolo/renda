require "colorize"
require "json"
require "http/client"
require "openssl/hmac"
require "terminal_table"

DEBUG = false
def log(str)
  pp str if DEBUG
end

def eur_brl
  get_json("https://economia.awesomeapi.com.br", "/eur")[0]["ask"].to_s.to_f64
end

def percentage(x, y)
  x, y = x.to_f64, y.to_f64
  pct = x < y ? ((y - x) / x) * 100.0 : - ((x - y) / y) * 100.0
  pct.round(2)
end

def profit_perct(x, por)
  (x.to_f64 * por.to_f64/100).round(2).to_s
end

def get_json(url, path)
  # result = 0
  # puts "http://51.15.63.128:2020/?url=#{url}#{path}"
  log "=> #{url}#{path}".colorize(:yellow)
  z = HTTP::Client.get("#{url}#{path}").body
  JSON.parse(z)
  # rescue e
  #   log "error: #{e}"
  # end
end

def ago(utc)
  date = utc ? Time.parse(utc, "%Y-%m-%dT%H:%M:%S.%6N", Time::Location::UTC) : Time.now
  span = (Time.now - date)
  "#{span.days}d#{span.hours}h#{span.minutes}m#{span.seconds}s"
end

class Order
  JSON.mapping(
   bids: Array(Float)
  )
end

# get_json("https://api.kraken.com", "/0/public/AssetPairs", "result").each_value do |market|
#   begin
#     from, to = market["wsname"].to_s.split("/")
#     puts "#{from} -> #{to};"
#   end
# end

# def arbitrage
  # euro = eur_brl
   # coins = ["xxbt", "eth", "ltc", "bch", "xrp", "xdg", "link", "ada", "eos", "xlm"]
    # coins.each do |c1|
      # coins.each do |c2|
        # begin
        # ticker = get_json("https://api.kraken.com", "/0/public/Depth?pair=#{c1}#{c2}")["result"]
        # key = /\"(\w+)\"/.match(ticker.to_s).try &.[1] || "eth"
        # next_c1 = ticker[key]["asks"][0][0].to_s.to_f64.round(4) || 0
#
#
				# c1 = (c1=="xbt") ? "btc" : c1
				# c1 = (c1=="xdg") ? "doge" : c1
#
        # c2 = (c2=="xbt") ? "btc" : c2
				# c2 = (c2=="xdg") ? "doge" : c2
				# json = get_json("https://api.novadax.com", "/v1/market/ticker?symbol=#{c1.upcase}_#{c2.upcase}")
				# last_c2 = json["data"]["lastPrice"].to_s.to_f64
				# perct = percentage(next_c1, last_c2)
#
				# puts "#{c1}:#{c2} #{next_c1} -> #{last_c2} | #{perct.to_s}"
				# rescue e
					# puts e
				# end
			# end
		# end
# end

# https://www.mercadobitcoin.net/api/eth/orderbook/
def arbitrage2
	euro = eur_brl
	puts "EUR:BRL : #{euro}"
	# braziliex x kraken
	table = nil
	big_total = big_invested = 0.0
	["xxbt", "eth", "bch", "xrp", "dash", "ltc"].each do |coin| 
	# ["xxbt", "eth", "ltc", "bch", "xrp", "xdg", "link", "ada", "eos", "xlm"].each do |coin| #
		table = TerminalTable.new
		table.headings =  ["Coin", "BRL->€", "€->BRL","Diff %",""]

		coin = "xbt" if coin == "xxbt"
		ticker = get_json("https://api.kraken.com", "/0/public/Depth?pair=#{coin}eur")["result"]
		key = /\"(\w+)\"/.match(ticker.to_s).try &.[1] || "eth"
		next_eur = ticker[key]["asks"][0][0].to_s.to_f64.round(4) || 0
		in_brl = (next_eur * euro).round(4)

		coin = (coin=="xbt") ? "btc" : coin
		coin = (coin=="xdg") ? "doge" : coin
    # last_brl = get_json("https://api.cryptomkt.com/", "v1/ticker?market=#{coin.upcase}BRL")["data"][0]["last_price"].to_s.to_f64
		# json = get_json("https://api.novadax.com", "/v1/market/ticker?symbol=#{coin.upcase}_BRL")
		# last_brl = json["data"]["lastPrice"].to_s.to_f64
		# last_brl =get_json("https://www.mercadobitcoin.net", "/api/#{coin.upcase}/ticker/")["ticker"]["last"].to_s.to_f64
		last_brl = get_json("https://omnitrade.io/", "api/v2/tickers/#{coin}brl")["ticker"]["last"].to_s.to_f64
		in_euro = (last_brl / euro).round(4)

		perct = percentage(next_eur, in_euro)
		table << [coin.to_s.upcase, "#{last_brl} -> #{in_euro}", "#{next_eur} -> #{in_brl}", perct.to_s, ""]
		# orderbook
		
		# data = get_json("https://www.mercadobitcoin.net", "/api/#{coin}/orderbook/")
		# data = get_json("https://api.cryptomkt.com","/v1/book?market=#{coin.upcase}BRL&type=buy&page=0")["data"]
		# data = get_json("https://api.novadax.com", "/v1/market/depth?symbol=#{coin.upcase}_BRL&limit=10")["data"]
		data = get_json("https://omnitrade.io/", "api/v2/order_book?market=#{coin}brl&bids_limit=200")
		buys = data["bids"]
		sells = data["asks"]
		count = 0
		total_price = total_perc = total = 0.0
		
		[sells, buys].each do |book|		
			table << ["Sell/Buy", "Ammount", "BRL","Diff %","Profit"]
			book.size.times do |i|
				price = book[i]["price"].to_s.to_f64
				amount = book[i]["volume"].to_s.to_f64
				perc = percentage(in_brl, price)
				# if perc >= 0.4
				count += 1
				total += amount
				total_price += price*amount
				total_perc += percentage(in_brl, price)
				totalt=(price*amount)
				profit_perc = profit_perct(totalt, perc)
				big_total += profit_perc.to_f64
				table << [price.round(4).to_s, amount.to_s, totalt.round(3).to_s, perc.to_s, profit_perc]
				# end
			end
		end

		tp = (total_price).round(2)
		big_invested += tp
		avg = (total_perc/count).round(2)
		table << ["Total", total.to_s, tp.to_s, avg, profit_perct(tp, avg)] if avg > 0

		table.separate_rows = true
		puts table.render
		puts
		# table.push ["Buy", "Ammount", "BRL","Diff %","Profit"]
		# buys = get_json("https://braziliex.com", "/api/v1/public/orderbook/#{coin}_brl")["bids"].to_json
		# Array(Order).from_json(buys)[0..8].each do |o|
		# price = o.price.to_f64
		# amount = o.amount.to_f64
		# perc = percentage(in_brl, price)
		# if price >= in_brl
		# totalt=(price*amount)
		# table.push [price.round(2).to_s, amount.to_s, totalt.round(2).to_s, perc.to_s, profit_perct(totalt, perc)]
		# end
		# end
	end
	puts 
	puts "#{big_total.round(2)} profit with #{big_invested.round(2)} invested"
end

# arbitrage
puts " = kraken x mercadobitcoin = "
arbitrage2
# puts Time.utc

# 0.68% to buy eos em mkt

# +------+---------------------+---------------------+--------+
# |  Coin |        BRL->€       |        €->BRL      | Diff % |
# +------+---------------------+---------------------+--------+
# |  eos |   21.765 -> 4.9354  |  4.6478 -> 20.4968  | 6.19   |
# +------+---------------------+---------------------+--------+
# |  btc | 21506.0 -> 4876.644 | 4718.3 -> 20807.703 | 3.36   |
# +------+---------------------+---------------------+--------+
# |  eth |  703.6 -> 159.5465  |  151.31 -> 667.2771 | 5.44   |
# +------+---------------------+---------------------+--------+
