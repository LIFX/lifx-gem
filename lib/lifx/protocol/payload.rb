module LIFX
  # @api private
  module Protocol
    class Payload < BinData::Record
      def to_s
        "#<#{self.class} #{super}>"
      end
    end
  end
end
