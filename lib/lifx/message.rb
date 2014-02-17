module LIFX
  class Message
    class InvalidFrame < ArgumentError; end
    class UnsupportedProtocolVersion < StandardError; end
    class NotAddressableFrame < StandardError; end
    class NoPayload < ArgumentError; end
    class UnmappedPayload < ArgumentError; end
    class InvalidFields < ArgumentError; end

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

      def valid_fields
        @valid_fields ||= Protocol::Message.new.field_names.map(&:to_sym)
      end
    end

    LIFX::Protocol::Message.fields.each do |field|
      define_method(field.name) do
        @message.send(field.name).snapshot
      end

      define_method("#{field.name}=") do |value|
        @message.send("#{field.name}=", value)
      end
    end

    alias_method :tagged?, :tagged
    alias_method :addressable?, :addressable

    attr_accessor :payload
    def initialize(*args)
      if args.count == 2 
        @message = args.first
        @payload = args.last
      elsif (hash = args.first).is_a?(Hash)
        payload = hash.delete(:payload)
        check_valid_fields!(hash)
        @message = Protocol::Message.new(hash)
        self.payload = payload
      else
        @message = Protocol::Message.new
      end
    end

    def payload=(payload)
      @payload = payload
      type_id = self.class.type_id_for_message_class(payload.class)
      if type_id.nil?
        raise UnmappedPayload.new("Unmapped payload class #{payload.class}")
      end
      @message.type = type_id
      @message.payload = payload.pack
    end

    def pack
      raise NoPayload if !payload
      @message.pack
    end

    def inspect
      hash = {site: site.unpack('H*').join}
      if tagged?
        hash[:tags] = target.unpack('H*').join
      else
        hash[:device] = target[0...6].unpack('H*').join
      end
      hash[:type] = payload.class.to_s.sub('LIFX::Protocol::', '')
      hash[:addressable] = addressable? ? 'true' : 'false'
      hash[:tagged] = tagged? ? 'true' : 'false'
      hash[:protocol] = protocol
      hash[:payload] = payload.snapshot
      attrs = hash.map { |k, v| "#{k}=#{v}" }.join(' ')
      %Q{#<LIFX::Message:0x#{object_id.to_s(16)} #{attrs}>}
    end

    protected

    def check_valid_fields!(hash)
      invalid_fields = hash.keys - self.class.valid_fields
      if invalid_fields.count > 0
        raise InvalidFields.new("Invalid fields for Message: #{invalid_fields.join(', ')}")
      end
    end
  end
end
