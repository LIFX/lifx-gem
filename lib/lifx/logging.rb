module LIFX
  module Logging
    def self.included(mod)
      mod.extend(self)
    end

    def logger
      LIFX::Config.logger
    end
  end
end