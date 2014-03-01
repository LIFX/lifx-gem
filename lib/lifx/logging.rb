module LIFX
  module_function

  def logger=(logger)
    @logger = logger
  end

  def logger
    @logger ||= default_logger
  end

  def default_logger
    Yell.new do |logger|
      logger.level = 'gte.warn'
      logger.adapter STDERR, format: '%d [%5L] %p/%t : %m'
    end
  end

  module Logging
    def self.included(mod)
      mod.extend(self)
    end

    def logger
      LIFX.logger
    end
  end
end