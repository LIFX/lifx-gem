require 'rspec'
require 'lifx'
require 'lifx/utilities'

shared_context 'integration', integration: true do
  include LIFX::Utilities

  def lifx
    $lifx ||= begin
      c = LIFX::Client.instance
      c.discover
      begin
        Timeout.timeout(5) do
          while !c.lights.find { |l| l.label =~ /^Test/ }
            sleep 0.5
          end
        end
      rescue Timeout::Error
        raise "Could not find any lights matching /^Test/ in #{c.lights.inspect}"
      end
      c
    end
  end

  def flush
    lifx.flush
  end

  def wait(timeout: 5, retry_wait: 0.1, &block)
    Timeout.timeout(timeout) do
      begin
        block.call
      rescue RSpec::Expectations::ExpectationNotMetError
        sleep(retry_wait)
        retry
      end
    end
  rescue Timeout::Error
    block.call
  end

  let(:lights) { lifx.lights }
  let(:light) { lights.find { |l| l.label =~ /^Test/} }
end

if ENV['DEBUG']
  LIFX::Config.logger = Yell.new(STDERR)
end

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
end

