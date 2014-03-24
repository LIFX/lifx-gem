module LIFX
  module Seen
    # Returns the time when the device was last seen.
    # @return [Time]
    def last_seen
      @last_seen
    end

    # Returns the number of seconds since the device was last seen.
    # If the device hasn't been seen yet, it will use Unix epoch as
    # the time it was seen.
    # @return [Float]
    def seconds_since_seen
      Time.now - (last_seen || Time.at(0))
    end

    # Marks the device as being seen.
    # @private
    def seen!
      @last_seen = Time.now
    end
  end
end
