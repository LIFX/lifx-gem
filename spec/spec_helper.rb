require 'rspec'
require 'lifx'
require 'lifx/utilities'

shared_context 'integration', integration: true do
  include LIFX::Utilities

  def lifx
    $lifx ||= begin
      options = if ENV['DEBUG']
        {logger: Yell.new(STDERR)}
      else
        {}
      end
      c = LIFX::Client.new(options)
      c.discover
      begin
        Timeout.timeout(5) do
          while c.lights.empty?
            sleep 0.5
          end
        end
      rescue Timeout::Error
        raise "Could not find any lights"
      end
      c
    end
  end

  def flush
    lifx.flush
  end

  let(:site) { lifx.sites.first }
  let(:lights) { site.lights }
  let(:light) { lights.first }
  let(:all_lights) { site.all_lights }
end

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
end

