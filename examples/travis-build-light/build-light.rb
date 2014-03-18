# A Travis CI Build Light
#
# To run: bundle; bundle ruby build-light.rb [user/repo]
# Please note this doesn't have error handling yet.

require 'bundler'
Bundler.require

lifx = LIFX::Client.lan
lifx.discover!
sleep 2 # Wait for tag data to come back

light = if lifx.tags.include?('Build Light')
  lights = lifx.lights.with_tag('Build Light')
  if lights.empty?
    puts "No lights in the Build Light tag, using the first light found."
    lifx.lights.first
  else
    lights
  end
else
  lifx.lights.first
end

if !light
  puts "No LIFX lights found."
  exit 1
end

puts "Using light(s): #{light}"
repo_path = ARGV.first || 'rails/rails'

repo = Travis::Repository.find(repo_path)
puts "Watching repository #{repo.slug}"

def update_light(light, repository)
  color = case repository.color
  when 'green'
    LIFX::Color.hsb(120, 1, 1)  
  when 'yellow'
    LIFX::Color.hsb(60, 1, 1)  
  when 'red'
    LIFX::Color.hsb(0, 1, 1)
  end

  light.set_color(color, duration: 0.2)
  puts "#{Time.now}: Build ##{repository.last_build.number} is #{repository.color}."
end

update_light(light, repo)

Travis.listen(repo) do |stream|
  stream.on('build:started', 'build:finished') do |event|
    update_light(light, event.repository)
  end
end