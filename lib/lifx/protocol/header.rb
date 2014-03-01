module LIFX
  module Protocol
    module HeaderFields
      def HeaderFields.included(mod)
        mod.instance_eval do
          hide :_reserved, :_reserved1

          uint16 :msg_size
          bit12le :protocol
          bool_bit1 :addressable, value: true
          bool_bit1 :tagged
          bit2le :_reserved
          uint32 :_reserved1
        end
      end
    end
    
    class Header < BinData::Record
      endian :little

      include HeaderFields
    end
  end
end
