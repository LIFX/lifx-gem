module LIFX
  class Target
    # Target is a high-level abstraction for the target of a Message
    class << self
      def broadcast
        new(broadcast: true)
      end

      def device_id(device_id)
        new(device_id: device_id)
      end

      def tag(tag)
        new(tag: tag)
      end
    end

    attr_reader :tag, :device_id, :broadcast
    def initialize(tag: nil, device_id: nil, broadcast: nil)
      @tag = tag
      @device_id = device_id
      @broadcast = broadcast
    end

    def broadcast?
      !!broadcast
    end

    def tag?
      !!tag
    end
  end
end