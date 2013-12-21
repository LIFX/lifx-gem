module LIFX
  module Protocol
    module HeaderFields
      def included(mod)
        mod.instance_eval do
          uint16 :msg_size
          bit12le :protocol
          bit1le :addressable
          bit1le :tagged
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
