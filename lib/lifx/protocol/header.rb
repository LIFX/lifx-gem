module LIFX
  module Protocol
    module HeaderFields
      def HeaderFields.included(mod)
        mod.instance_eval do
          uint16 :msg_size, value: lambda { num_bytes }
          bit12le :protocol
          bool_bit1 :addressable
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
