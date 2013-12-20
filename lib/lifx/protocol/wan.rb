module LIFX
  module Protocol
    module Wan
      class ConnectPlain < BinData::Record
        endian :little

        string :user, length: 32, trim_padding: true
        string :pass, length: 32, trim_padding: true
      end

      class ConnectKey < BinData::Record
        endian :little

        bytes :key, length: 32
      end

      class StateConnect < BinData::Record
        endian :little

        bytes :key, length: 32
      end

      class Sub < BinData::Record
        endian :little

        bytes :target, length: 8
        bytes :site, length: 6
        bool :device
      end

      class Unsub < BinData::Record
        endian :little

        bytes :target, length: 8
        bytes :site, length: 6
        bool :device
      end

      class StateSub < BinData::Record
        endian :little

        bytes :target, length: 8
        bytes :site, length: 6
        bool :device
      end

    end
  end
end
