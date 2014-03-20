module LIFX
  module Seen
    def last_seen
      @last_seen
    end

    def seconds_since_seen
      Time.now - (last_seen || Time.at(0))
    end

    def seen!
      @last_seen = Time.now
    end
  end
end
