module LIFX
  class Light
    attr_reader :site

    attr_accessor :label, :color, :power, :dim, :tags

    def initialize(site)
      @site = site
    end

    def on_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Light::State
        @label = payload.label
        @color = payload.color
        @power = payload.power
        @dim   = payload.dim
        @tags  = payload.tags
      end
    end
  end
end
