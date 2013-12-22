module LIFX
  module Protocol
    module MetadataFields
      def MetadataFields.included(mod)
        mod.instance_eval do
          hide :_reserved3
          
          uint64 :at_time
          uint16 :type
          uint16 :_reserved3
        end
      end
    end

    class Metadata < BinData::Record
      endian :little

      include MetadataFields
    end
  end
end
