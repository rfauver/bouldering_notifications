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

gyms = [
  {
    gym: :gwpower,
    name: 'Great Western Power Co.',
    url: 'https://touchstoneclimbing.com/gwpower-co/route-setting/',
  },
  {
    gym: :ironworks,
    name: 'Ironworks',
    url: 'https://touchstoneclimbing.com/ironworks/route-setting/',
  },
  {
    gym: :dogpatch,
    name: 'Dogpatch Boulders',
    url: 'https://touchstoneclimbing.com/dogpatch-boulders/route-setting/',
  },
]

gyms_with_new_problems = gyms.map do |gym|
  page = Nokogiri::HTML(open(gym[:url]))
  keys = [:location, :date, :problems]
  row = page.css('.table-routes tbody tr:first-child td').map(&:text)
  row = keys.zip(row).to_h

  old_row = redis.get(gym[:gym])
  old_row = JSON.parse(old_row, symbolize_names: true) if old_row

  just_set = old_row != row
  bouldering_problems = row[:problems].match?(/v/i)

  redis.set(gym[:gym], row.to_json) if just_set

  next unless just_set && bouldering_problems
  gym.merge(row)
end.compact

exit unless gyms_with_new_problems.length > 0

multiple_gyms = gyms_with_new_problems.length > 1
title = multiple_gyms ? 'Multiple Gyms' : gyms_with_new_problems.first[:name]
message = gyms_with_new_problems.map do |gym|
  line = "#{gym[:problems]} in the #{gym[:location]} set on #{gym[:date]}"
  line += " at #{gym[:name]}" if multiple_gyms
  line
end.join("\n")

Notifier.call(title: "New Routes at #{title}", message: message)
