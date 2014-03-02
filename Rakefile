require "bundler/gem_tasks"

task :console do
  require "lifx"
  require "pry"
  if ENV['DEBUG']
    LIFX::Config.logger = Yell.new(STDERR)
  end
  c = LIFX::Client.instance
  c.discover
  c.pry
end
