require 'dotenv/load' unless ENV['PRODUCTION'] == 'true'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'redis'
require 'json'

class Notifier
  URL = URI.parse("https://api.pushover.net/1/messages.json")

  def self.call(message:, title: nil)
    request = Net::HTTP::Post.new(URL.path)
    request.set_form_data({
      token: ENV['PUSHOVER_TOKEN'],
      user: ENV['PUSHOVER_USER'],
      title: title,
      message: message
    }.compact)
    res = Net::HTTP.new(URL.host, URL.port)
    res.use_ssl = true
    res.verify_mode = OpenSSL::SSL::VERIFY_PEER
    res.start { |http| http.request(request) }
  end
end

def redis
  return @redis if defined?(@redis)
  url = ENV['REDIS_URL']
  @redis = Redis.new({ url: url }.compact)
end

page = Nokogiri::HTML(open("https://touchstoneclimbing.com/gwpower-co/route-setting/"))
keys = [:location, :date, :problems]
row = page.css('.table-routes tbody tr:first-child td').map(&:text)
row = keys.zip(row).to_h

old_row = redis.get(:gwpower)
old_row = JSON.parse(old_row, symbolize_names: true) if old_row

just_set = old_row != row
bouldering_problems = row[:problems].match?(/v/i)

redis.set(:gwpower, row.to_json) if just_set

puts "Set on #{row[:date]}, just set: #{just_set}"
puts "#{row[:problems]}, bouldering problems: #{bouldering_problems}"
exit unless just_set && bouldering_problems

Notifier.call(
  title: "New Routes at Great Western Power Co.",
  message: "#{row[:problems]} in the #{row[:location]} set on #{row[:date]}",
)
