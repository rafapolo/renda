require "./helper"

class Order

  JSON.mapping({
    accountid: String | Nil,
    orderuuid: String,
    exchange: String,
    type: String | Nil,
    ordertype: String | Nil,
    quantity: Float64,
    quantityremaining: Float64,
    limit: Float64,
    reserved: Float64 | Nil,
    reserveremaining: Float64 | Nil,
    commissionreserved: Float64 | Nil,
    commissionreserveremaining: Float64 | Nil,
    commissionpaid: Float64 | Nil,
    price: Float64,
    priceperunit: Float64 | Nil,
    timestamp: String | Nil,
    opened: String | Nil,
    closed: String | Nil,
    is_open: Bool | Nil,
    sentinel: String | Nil,
    cancelinitiated: Bool | Nil,
    immediateorcancel: Bool,
    isconditional: Bool,
    condition: String,
    conditiontarget: Bool | Nil,
    #INFO: order history has other mapping
    commission: {type: Float64, default: 0.to_f64},
    order_dolar: {type: Float64, default: 0.to_f64},
    atual_dolar: {type: Float64, default: 0.to_f64},
    tax: {type: Float64, default: 0.to_f64},
    change: {type: Float64, default: 0.to_f64}
  })

  def self.total_taxes
    taxes = 0.to_f64.as(Float64)
    self.all.each do |o|
      taxes += o.tax
    end
    taxes
  end

  def self.all(format = nil)
    orders = Array(Order).from_json(Broker.get("account/getorderhistory"))
    return orders unless format
    # TODO: add list of orderuid|finish_date
    btc_usd = Market.last_value_from("usdt-btc")
    orders.each do |o|
      # set dolars paid when bought, actual price and taxes.
      currency = o.exchange.split("-")[1]
      day_dolar = Market.btc_to_dolar_of_date(as_time(o.closed))
      o.order_dolar = day_dolar * o.quantity
      o.atual_dolar = o.quantity * btc_usd
      o.tax = day_dolar * o.commission.to_s.to_f64
      o.change = percentage(o.order_dolar, o.atual_dolar)
      puts day_dolar, o.order_dolar, o.atual_dolar, o.change
    end
    total = 0.0
    puts "==> Orders ==>".colorize(:blue)
    orders.each do |o|
      profit = o.atual_dolar - o.order_dolar
       if o.buy?
        total += profit
      else
        total -= profit
      end
      out = "# #{as_time(o.closed)} | #{o.exchange.upcase} | #{o.change}% | #{as_dolar(o.order_dolar)} +#{as_dolar(profit)} | $#{o.tax.round(5)} tax"
      puts o.buy? ? out.colorize(:green) : out.colorize(:red)
    end
    line
    puts "==> #{as_dolar(total)} profit".colorize(:green)
    orders
  end

  def buy?
    self.ordertype == "limit_buy"
  end

  # show orders processing time
  def self.avg_time
    Order.all.each do |o|
      elapsed = as_time_ago(as_time(o.closed) - as_time(o.timestamp))
      o_type = o.ordertype.split("_")[1].upcase
      puts "#{o_type} #{o.exchange.upcase} in #{elapsed}".colorize(:yellow)
    end

  end

  # show total asks under Value for Market
  def self.total_under(value, market)
    market = market.upcase
    json = JSON.parse(Broker.get("/public/getorderbook", "market=#{market}&type=sell"))
    total = 0.0
    json.each do |sell|
      rate = sell["rate"].to_s.to_f64
      if rate <= value
        qtd = sell["quantity"].to_s.to_f64
        total += (rate*qtd)
      end
    end
    #"#{market} under #{value} => #{total} btc | #{in_usd}".colorize(:yellow)
    total
  end


end
