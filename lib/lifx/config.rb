require 'configatron/core'
require 'logger'
module LIFX
  Config = Configatron::Store.new

  Config.default_duration = 1
  Config.broadcast_ip = '255.255.255.255'
  Config.allowed_transports = [:udp, :tcp]
  Config.log_invalid_messages = false
  Config.logger = Logger.new(STDERR).tap do |logger|
    logger.level = Logger::WARN
  end
end
