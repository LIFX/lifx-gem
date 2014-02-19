require 'timers'
module LIFX
  module Timers
    protected
    def initialize_timer_thread
      Thread.new do
        loop { timers.wait }
      end
    end

    def timers
      @timers ||= ::Timers.new
    end
  end
end
