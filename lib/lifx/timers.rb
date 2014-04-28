require 'timers'
module LIFX
  # @private
  module Timers
    protected
    def initialize_timer_thread
      timers.after(1) {} # Just so timers.wait doesn't complain when there's no timer
      Thread.new do
        loop do
          timers.wait
        end
      end
    end

    public
    def timers
      @timers ||= ::Timers.new
    end
  end
end
