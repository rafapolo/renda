TMZ = 2.hours # athens

line
puts "\t   Renda Basica".colorize(:blue)
line

# finish! if interrupted
[Signal::QUIT, Signal::ABRT, Signal::INT, Signal::KILL, Signal::TERM].each do |s|
  s.trap do
    puts "=> Interrupted!".colorize(:red)
    finish!
  end
end

def line
  puts "=================================".colorize(:blue)
end

def test_colors
   colors = [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :light_gray, :dark_gray, :light_red, :light_green, :light_yellow, :light_blue, :light_magenta, :light_cyan, :white]
   colors.each do |c1|
     colors.each do |c2|
       puts "fore #{c1} | back #{c2}".colorize.fore(c1).back(c2)
     end
   end
end


def percentage(x, y)
  x, y = x.to_f64, y.to_f64
  pct = x < y ? ((y - x) / x) * 100.0 : - ((x - y) / y) * 100.0
  pct.round(2)
end

def as_time(time, tmz=false)
  parsed_time = Time.parse(time.to_s, "%Ft%T.%L")
  tmz ? parsed_time + TMZ : parsed_time
end

def as_time_ago(span)
  h = span.hours > 0 ? "#{span.hours}h" : ""
  m = span.minutes > 0 ? "#{span.minutes}m" : ""
  "#{h}#{m}#{span.seconds}s#{span.milliseconds}"
end

def as_dolar(value)
  "$#{value.round(2)}"
end

def finish!
  elapsed = Time.now - as_time(Config.params[:start_time])
  line
  puts "=> #{Broker.requests_count} requests in #{as_time_ago(elapsed)}".colorize(:yellow)
  line
  exit
end

def color(float : Float64)
  float > 0 ? float.to_s.colorize(:green) : float.to_s.colorize(:red)
end

def now
  Time.now.to_s("%Ft%T.%L")
end

def save_json(json, file)
  File.open("log/#{file.to_s}.json", "w") do |f|
    f.write("#{json.to_pretty_json}\n".to_slice)
  end
end

class Logger
  def self.log(msg, file=:renda, error=false)
    File.open("log/#{file.to_s}.log", "a+") do |f|
      stamped = "#{now} #{msg}"
      puts stamped.colorize(error ? :red : :yellow) if Config.params[:log] || error
      f.write("#{stamped}\n".to_slice)
    end
  end
end
