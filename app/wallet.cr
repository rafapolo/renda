require "./order"
require "./strategy"
require "./helper"

# TODO: a wallet is array of assets
class Wallet

  @@total = 0.0
  @@taxes = 0.0

  JSON.mapping({
    currency: String,
    balance: Float64,
    available: Float64,
    pending: Float64,
    cryptoaddress: String | Nil,
    # new attrs
    as_dolar: {type: Float64, default: 0.to_f64}
  })

  def self.assets(format = nil)
    assets = Array(Wallet).from_json(Broker.get("account/getbalances"))
    # set Wallet.total & asset as_dolar & orders taxes
    @@total = 0
    assets.each do |a|
      a.as_dolar = Market.convert_to_dolar(a.currency, a.balance)
      @@total += a.as_dolar
    end
    # TODO: consider deposits
    @@taxes = Order.total_taxes
    return assets unless format
    assets.each do |a|
      puts "# #{a.currency.upcase} => #{a.balance} | #{as_dolar(a.as_dolar)}".colorize(:green) if a.balance > 0
    end
    line
    assets
  end

  def deposits
    #TODO: /account/getdeposithistory | account/getwithdrawalhistory?currency=BTC
  end

  def open_orders
    #TODO: ? | get /market/getopenorders
  end

  def self.simulate_buy(market, quantity)
    # store data sims and show as orders for post-analises
    Logger.log "#{market},#{quantity}", :sims
    puts "=> simulated buy #{market} #{quantity}".colorize(:yellow)
  end

  def self.sell(market, quantity, rate)
    if Market.exists?(market)
      puts "Selling #{market}..."
      order = Broker.get("market/selllimit", "market=#{market}&quantity=#{quantity}&rate=#{rate}")
      if order_id = JSON.parse(order)["uuid"]
        order = Order.from_json(Broker.get("account/getorder", "uuid=#{order_id}"))
        puts "Sould #{order.quantity} of #{market.upcase} for #{rate} BTC".colorize(:green)
        return order
      end
    else
      puts "error: market #{market} does not exist.".colorize(:red)
    end
  end

  def self.buy(market, quantity, rate=nil)
    if Market.exists?(market)
      return simulate_buy(market, quantity) if Config.params[:simulate]
      rate = Market.last_value_from(market) unless rate # use last asked price
      Logger.log "=> buy #{market} #{quantity} for #{rate}", :orders
      # TODO: better understand rate param on API | rate to place the order
      order = Broker.get("market/buylimit", "market=#{market}&quantity=#{quantity}&rate=#{rate}")
      # and if not return uuid? :O
      if order_id = JSON.parse(order)["uuid"]
        order = Order.from_json(Broker.get("account/getorder", "uuid=#{order_id}"))
        # TODO: add to orders.json
        # orders = JSON.parse(File.read("log/orders.json")).as(Hash)
        # timestamp = Time.parse(order.opened.to_s, "%Ft%T.%L").to_s
        # orders[timestamp][to]=quantity
        # save_json(orders, :orders)
        puts "Bought #{order.quantity} of #{market.upcase} for #{rate} BTC".colorize(:green)
        return order
      else
        puts "error: no order made.".colorize(:red)
      end
    else
      puts "error: market #{market} does not exist.".colorize(:red)
    end
  end

  def self.buy_in_dolar(market, value)
    if Market.exists?(market)
      to_btc = value / Market.last_value_from("usdt-btc")
      one_currency_in_btc = Market.last_value_from(market)
      currency_in_btc = to_btc / one_currency_in_btc
      self.buy(market, currency_in_btc, one_currency_in_btc)
    else
      puts "error: market #{market.upcase} does not exist.".colorize(:red)
    end
  end

  def self.withdraw
    # TODO: flush! send back to main external wallet
    # TODO: /account/getwithdrawalhistory
  end

  def self.flush_all(to = "btc")
    Wallet.assets.each do |w|
      market = "#{to}-#{w.currency}"
      Wallet.sell(market, w.available, Market.last_value_from(market)) if w.currency != to
    end
  end

  def self.total(format = nil)
    self.assets if @@total < 1
    return @@total unless format
    last_btc = Market.last_value_from("usdt-btc")
    print "==> #{as_dolar @@total} total | #{@@total/last_btc} btc".colorize(:green)
    puts " | #{as_dolar(@@taxes)} taxes".colorize(:yellow)
  end

end
