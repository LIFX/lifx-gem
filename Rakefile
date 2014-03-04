require "bundler/gem_tasks"

task :console do
  require "lifx"
  require "pry"
  if ENV['DEBUG']
    LIFX::Config.logger = Yell.new(STDERR)
  end
  # LIFX.client.discover
  LIFX.pry
end
