# Identify
#
# This example uses a divide and conquer search algorithm to identify a light visually.
# It will set all lights to white, then partition them by colour.
# On each iteration, it will ask you what colour the bulb you're trying to identify is showing
# until it narrows it down to a single bulb.
# Please note it does not restore the light state before identification.

require 'bundler'
Bundler.require

COLOURS = {
  'red' => [0, 1, 1],
  'yellow' => [50, 1, 1],
  'green' => [120, 1, 1],
  'blue' => [220, 1, 1]
}

LIFX::Config.logger = Logger.new(STDERR)
c = LIFX::Client.lan
c.discover
5.times do
  c.lights.refresh
  c.flush
  sleep 1
  puts "Lights found: #{c.lights.count}"
end


def partition(list, partitions)
  [].tap do |array|
    list.each_slice((list.count / partitions.to_f).ceil) do |chunk|
      array << chunk
    end
  end
end

lights = c.lights.to_a
mapping = {}

while lights.count > 1
  puts "Searching through #{lights.count} lights..."
  c.lights.set_color(LIFX::Color.white)
  partitions = partition(lights, COLOURS.values.count)
  COLOURS.keys.each_with_index do |color_name, index|
    color = LIFX::Color.hsb(*COLOURS[color_name])
    mapping[color_name] = partitions[index]
    next if partitions[index].nil?
    partitions[index].each do |l|
      l.set_color(color, duration: 0)
    end
  end
  puts "Waiting for flush."
  c.flush
  puts "What colour is the bulb you're trying to identify? (#{COLOURS.keys.join(', ')})"
  resp = gets.strip
  if mapping.has_key?(resp)
    lights = mapping[resp]
  else
    puts "Colour not found. Iterating again"
  end
end

if lights.count == 1
  puts "Light identified: #{lights.first}"
else
  puts "No bulbs found."
end

c.flush
