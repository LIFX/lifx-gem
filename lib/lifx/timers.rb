require 'timers'
module LIFX
  # @private
  module Timers
    protected
    def initialize_timer_thread
      timers.after(1) {} # Just so timers.wait doesn't complain when there's no timer
      @timer_thread = Thread.start do
        loop do
          timers.wait
        end
      end
    end

    def stop_timers
      timers.each(&:cancel)
      if @timer_thread
        @timer_thread.abort
      end
    end

    public
    def timers
      @timers ||= ::Timers.new
    end
  end
end
