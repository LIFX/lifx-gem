module LIFX
  module Seen
    def last_seen
      @last_seen
    end

    def age
      Time.now - (last_seen || 0)
    end

    def seen!
      @last_seen = Time.now
    end
  end
end
