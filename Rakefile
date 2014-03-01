require "bundler/gem_tasks"

task :console do
  require "lifx"
  require "pry"
  c = LIFX::Client.new
  c.discover
  c.pry
end
