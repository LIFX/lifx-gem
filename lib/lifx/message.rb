module LIFX
  class Message
    class InvalidFrame < ArgumentError; end
    class UnsupportedProtocolVersion < StandardError; end
    class NotAddressableFrame < StandardError; end

    PROTOCOL_VERSION = 1024

    class << self
      def unpack(data)
        raise InvalidFrame if data.length < 2

        header = Protocol::Header.read(data)
        raise UnsupportedProtocolVersion if header.protocol != PROTOCOL_VERSION
        raise NotAddressableFrame if header.addressable == 0

        message = Protocol::Message.read(data)
        payload_class = message_type_for_id(message.type)
        payload = payload_class.read(message.payload)
        new(message, payload)
      end

      def message_type_for_id(type_id)
        Protocol::TYPE_ID_TO_CLASS[type_id]
      end

      def type_id_for_message_class(klass)
        Protocol::CLASS_TO_TYPE_ID[klass]
      end
    end

    LIFX::Protocol::Message.fields.each do |field|
      define_method(field.name) do
        self.message.send(field.name)
      end

      define_method("#{field.name}=") do |value|
        self.message.send("#{field.name}=", value)
      end
    end

    alias_method :tagged?, :tagged
    alias_method :addressable?, :addressable

    attr_accessor :message, :payload
    def initialize(message = Protocol::Message.new, payload = nil)
      @message = message
      @payload = payload
    end

  end
end