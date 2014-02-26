require 'rspec'
require 'lifx'

shared_context 'integration', integration: true do
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

  def wait_until(timeout = 1, &block)
    Timeout.timeout(timeout) do
      while !block.call
        sleep 0.1
      end
    end
  rescue Timeout::Error
    $stderr.puts("Timeout exceeded")
  end

  def flush
    lifx.flush
  end

  let(:site) { lifx.sites.first }
  let(:lights) { site.lights }
  let(:light) { lights.first }
end

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
end

