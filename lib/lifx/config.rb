require 'configatron/core'
require 'yell'
module LIFX
  Config = Configatron::Store.new

  Config.default_duration = 1
  Config.broadcast_ip = '255.255.255.255'
  Config.allowed_transports = [:udp, :tcp]
  Config.log_invalid_messages = false
  Config.logger = Yell.new do |logger|
    logger.level = 'gte.warn'
    logger.adapter STDERR, format: '%d [%5L] %p/%t : %m'
  end
end
