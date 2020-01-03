class Tick

  JSON.mapping({
    bid: Float64,
    ask: Float64,
    last: Float64
  })

  def self.from_market(market)
    #TODO: WebSockets!
    self.from_json(Broker.get("public/getticker", "market=#{market}"))
  end

end
