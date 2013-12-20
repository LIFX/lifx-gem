# Generated code ahoy!
module LIFX
  module Protocol
    module Light
      module Waveform
        SAW = 0
        SINE = 1
        HALF_SINE = 2
        TRIANGLE = 3
        PULSE = 4
      end

      class Hsbk < BinData::Record
        endian :little

        uint16 :hue # 0..65_535 scaled to 0° - 360°.
        uint16 :saturation # 0..65_535 scaled to 0% - 100%.
        uint16 :brightness # 0..65_535 scaled to 0% - 100%.
        uint16 :kelvin # Explicit 2_400..10_000.
      end

      class Get < BinData::Record
        endian :little

      end

      class Set < BinData::Record
        endian :little

        uint8 :stream # 0 is no stream.
        hsbk :color
        uint32 :duration # Milliseconds.
      end

      class SetWaveform < BinData::Record
        endian :little

        uint8 :stream # 0 is no stream.
        bool :transient
        hsbk :color
        uint32 :period # Milliseconds per cycle.
        float :cycles
        int16 :duty_cycle
        uint8 :waveform
      end

      class SetDimAbsolute < BinData::Record
        endian :little

        int16 :brightness # 0 is no change.
        uint32 :duration # Milliseconds.
      end

      class SetDimRelative < BinData::Record
        endian :little

        int32 :brightness # 0 is no change.
        uint32 :duration # Milliseconds.
      end

      class Rgbw < BinData::Record
        endian :little

        uint16 :red
        uint16 :green
        uint16 :blue
        uint16 :white
      end

      class SetRgbw < BinData::Record
        endian :little

        rgbw :color
      end

      class State < BinData::Record
        endian :little

        hsbk :color
        int16 :dim
        uint16 :power
        string :label, length: 32, trim_padding: true
        uint64 :tags
      end

      class GetRailVoltage < BinData::Record
        endian :little

      end

      class StateRailVoltage < BinData::Record
        endian :little

        uint32 :voltage
      end

      class GetTemperature < BinData::Record
        endian :little

      end

      class StateTemperature < BinData::Record
        endian :little

        int16 :temperature # Deci-celsius. 25.45 celsius is 2545
      end

    end
  end
end
