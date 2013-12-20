module LIFX
  module Protocol
    module Wifi
      class Get < BinData::Record
        endian :little

        uint8 :interface
      end

      class Set < BinData::Record
        endian :little

        uint8 :interface
        bool :active
      end

      class State < BinData::Record
        endian :little

        uint8 :interface
        uint8 :status
        uint32 :ipv4
        bytes :ipv6, length: 16
      end

      class GetAccessPoint < BinData::Record
        endian :little

      end

      class SetAccessPoint < BinData::Record
        endian :little

        uint8 :interface
        string :ssid, length: 32, trim_padding: true
        string :pass, length: 64, trim_padding: true
        uint8 :security
      end

      class StateAccessPoint < BinData::Record
        endian :little

        uint8 :interface
        string :ssid, length: 32, trim_padding: true
        uint8 :security
        int16 :strength
        uint16 :channel
      end

    end
  end
end
