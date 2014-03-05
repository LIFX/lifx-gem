module LIFX
  module LightTarget
    MSEC_PER_SEC   = 1000
    def set_color(color, duration: LIFX::Config.default_duration)
      send_message(Protocol::Light::Set.new(
        color: color.to_hsbk,
        duration: (duration * MSEC_PER_SEC).to_i,
        stream: 0,
      ))
    end

    def set_power(value)
      send_message(Protocol::Device::SetPower.new(level: value))
    end

    def turn_on
      set_power(1)
    end

    def turn_off
      set_power(0)
    end

    def refresh
      send_message(Protocol::Light::Get.new)
    end

    MAX_LABEL_LENGTH = 32
    class LabelTooLong < ArgumentError; end
    def set_label(label)
      if label.length > MAX_LABEL_LENGTH
        raise LabelTooLong.new("Label length must be below or equal to #{MAX_LABEL_LENGTH}")
      end
      send_message(Protocol::Device::SetLabel.new(label: label))
    end
  end
end
