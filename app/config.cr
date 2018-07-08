class Config
  property params = {} of Symbol => (String | Int32 | Float64 | Bool)

  def initialize
    @params[:log] = false
    @params[:simulate] = false
    @params[:retry] = false
    @params[:start_time] = now
  end

  def self.params
    self.instance.params
  end

  # singleton class
  def self.instance
    @@instance ||= new
  end

end
