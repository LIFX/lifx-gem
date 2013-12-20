module LIFX
  module Protocol
    module Sensor
      class GetAmbientLight < BinData::Record
        endian :little

      end

      class StateAmbientLight < BinData::Record
        endian :little

        float :lux
      end

      class GetDimmerVoltage < BinData::Record
        endian :little

      end

      class StateDimmerVoltage < BinData::Record
        endian :little

        uint32 :voltage
      end

    end
  end
end
