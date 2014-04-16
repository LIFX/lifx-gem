require 'bundler'
Bundler.require
begin
  require 'pry'
rescue LoadError
end

require 'lifx'
require 'lifx/utilities'

shared_context 'integration', integration: true do
  def lifx
    $lifx ||= begin
      c = LIFX::Client.lan
      begin
        c.discover! do
          c.tags.include?('_Test') && c.lights.with_tag('_Test').count > 0
        end
      rescue Timeout::Error
        raise "Could not find any lights with tag _Test in #{c.lights.inspect}"
      end
      c
    end
  end

  def flush
    lifx.flush
  end

  let(:lights) { lifx.lights.with_tag('_Test') }
  let(:light) { lights.first }
end

module SpecHelpers
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
end

LIFX::Config.logger = Yell.new(STDERR) if ENV['DEBUG']

RSpec.configure do |config|
  config.include(SpecHelpers)
  config.formatter = 'documentation'
  config.color = true
end
