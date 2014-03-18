require "bundler/gem_tasks"

task :console do
  require "lifx"
  require "pry"
  if ENV['DEBUG']
    LIFX::Config.logger = Yell.new(STDERR)
  end
  LIFX::Client.lan.discover! do |c|
    c.lights.count > 0
  end
  LIFX::Client.lan.pry
end
