module LIFX
  module Protocol
    # @api private
    module Sensor
      class GetAmbientLight < Payload
        endian :little

      end

      class StateAmbientLight < Payload
        endian :little

        float :lux
      end

      class GetDimmerVoltage < Payload
        endian :little

      end

      class StateDimmerVoltage < Payload
        endian :little

        uint32 :voltage
      end

    end
  end
end
