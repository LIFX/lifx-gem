# Generated code ahoy!
module LIFX
  module Protocol
    module Wifi
      module Interface
        SOFT_AP = 1
        STATION = 2
      end

      module Security
        UNKNOWN = 0
        OPEN = 1
        WEP_PSK = 2
        WPA_TKIP_PSK = 3
        WPA_AES_PSK = 4
        WPA2_AES_PSK = 5
        WPA2_TKIP_PSK = 6
        WPA2_MIXED_PSK = 7
      end

      module Status
        CONNECTING = 0
        CONNECTED = 1
        FAILED = 2
        OFF = 3
      end

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
        string :ipv6, length: 16
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
