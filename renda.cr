# author: rafael polo

# require "kemal"
# require "http/web_socket"
require "option_parser"
require "./app/broker"
require "./app/helper"
require "./app/wallet"
require "./app/summary"
require "./app/arbitrage"

config = Config.params
OptionParser.parse! do |args|
  args.banner = "Usage: renda [arguments]"
  args.on("-l", "--log", "Show broker HTTP/JSON request/answer logs"){ config[:log] = true }
  args.on("-s", "--simulate", "Fake buy"){ config[:simulate] = true }
  args.on("-a", "--assets", "Show wallets"){ Wallet.assets(:format) }
  args.on("-t", "--total", "Sum wallets values and taxes in dolar"){ Wallet.total(:format) }
  args.on("-o", "--orders", "Show previous orders"){ Order.all(:format) }
  args.on("-obs", "--observe", "Observe markets"){ Summary.monitor! }
  args.on("-arb", "--arbitrage", "Arbitrage"){ Strategy.arbitrage }
  #TODO: args.on("-w", "--web", "Enable web mode localhost:5000"){ Web.start }
  args.on("-m MARKET", "--market=NAME", "Set market to buy"){ |m| config[:market] = m }
  args.on("-v VALUE", "--value=VALUE", "Set value to buy in dolars"){ |v| config[:value] = v }
  args.on("-b", "--buy", "Buy {market} and {value} from BTC") {
    Wallet.buy_in_dolar(config[:market].to_s.downcase, config[:value].to_s.to_f64)
  }
  args.on("-h", "--help", "Show this help") { puts args }
end

#test_colors

finish!
