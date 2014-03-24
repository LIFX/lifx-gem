module LIFX
  # Target is a high-level abstraction for the target of a Message
  # @api private
  class Target

    attr_reader :site_id, :device_id, :tag, :broadcast
    def initialize(device_id: nil, site_id: nil, tag: nil, broadcast: nil)
      @site_id   = site_id
      @device_id = device_id
      @tag       = tag
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
