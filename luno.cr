require "colorize"

# is sell it in BRL profitable bringing back to EUR? no!

def profit!(invest)
  # euro_to_exchange | n26 -> luno
  puts "=> #{invest} EUR".colorize(:green)

  puts "euro -> btc".colorize(:blue)
  last_eur_btc = 8821.225 # @last_eur_btc = https://www.luno.com/ajax/1/price_chart?currency=XBTEUR
  btcs = (1/last_eur_btc) * invest
  puts "=> #{btcs} BTC".colorize(:green)

  puts "# btc_to_market".colorize(:blue) # | luno -> mercadobitcoin
  send_fee = (1/last_eur_btc) * 30 # 2018/01/20"),22.403 : https://bitinfocharts.com/comparison/bitcoin-transactionfees.html#3m
  puts "=> #{send_fee} BTC send fee".colorize(:red)
  sent = btcs - send_fee
  puts "=> #{sent} BTC sent".colorize(:green)

  puts "# sell_btc_for_BRL".colorize(:blue)
  received = sent
  last_btc_brl = 36996.0 # https://www.mercadobitcoin.net/api/BTC/ticker/
  in_brl = last_btc_brl * received
  puts "=> R$#{in_brl} conversion".colorize(:yellow)
  execution_fee = in_brl - (in_brl - (in_brl*0.01))
  puts "=> R$#{execution_fee} execution fee".colorize(:red)
  convertido = in_brl - execution_fee
  puts "=> R$#{convertido} convertido".colorize(:yellow)

  puts "# withdraw_real".colorize(:blue) # send to ITAU
  saque_fee = in_brl - (in_brl - (in_brl*0.02)) - 3 # R$ 2,90 + 1,99%
  puts "=> R$#{saque_fee} saque fee".colorize(:red)
  sacado = convertido - saque_fee
  puts "=> R$#{sacado} sacado".colorize(:yellow)

  puts "# EUR_in_BRL".colorize(:blue)
  cotacao = 0.25439 # brl-eur
  converted = (1/cotacao) * (invest - 30)
  puts "=> R$#{converted} EUR/BRL".colorize(:green)

  puts "# real_to_eur".colorize(:blue) # transferWise euros back

  puts "=> #{converted} EUR convertido".colorize(:yellow)
  reenvio_fee = converted - (converted - (converted*0.028))
  puts "=> #{reenvio_fee} BRL reenvio fee".colorize(:red)

  total = converted - reenvio_fee
  puts "=> #{total} EUR reconvertido".colorize(:yellow)
  puts "=> #{total-invest} EUR lucro".colorize(:green)

end

profit! 8821
