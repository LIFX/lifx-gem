module LIFX
  class Message
    class InvalidFrame < ArgumentError; end
    class UnsupportedProtocolVersion < StandardError; end
    class NotAddressableFrame < StandardError; end
    class NoPayload < ArgumentError; end
    class UnmappedPayload < ArgumentError; end
    class InvalidFields < ArgumentError; end
    class PackError < ArgumentError; end

    PROTOCOL_VERSION = 1024

    class << self
      def unpack(data)
        raise InvalidFrame if data.length < 2

        header = Protocol::Header.read(data)
        raise UnsupportedProtocolVersion if header.protocol != PROTOCOL_VERSION
        raise NotAddressableFrame if header.addressable == 0

        message = Protocol::Message.read(data)
        payload_class = message_type_for_id(message.type.snapshot)
        if payload_class.nil?
          LOG.warn("Message.unpack: Unrecognised payload ID: #{message.type}")
          LOG.warn("Message.unpack: Message: #{message}")
          return nil
          raise UnmappedPayload.new("Unrecognised payload ID: #{message.type}")
        end
        begin
          payload = payload_class.read(message.payload)
        rescue => ex
          if message.raw_site == "\x00" * 6
            LOG.info("Message.unpack: Ignoring malformed message from virgin bulb")
          else
            LOG.error("Message.unpack: Exception while unpacking payload of type #{payload_class}: #{ex}")
            LOG.error("Message.unpack: Data: #{data.inspect}")
          end
        end
        new(message, payload)
      rescue => ex
        LOG.error("Message.unpack: Exception while unpacking #{data.inspect}")
        LOG.error("Message.unpack: #{ex} - #{ex.backtrace.join("\n")}")
        raise ex
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
        site    = hash.delete(:site)
        target  = hash.delete(:target)

        if target.is_a?(Integer)
          target = [target].pack('Q')
        end
        check_valid_fields!(hash)

        @message = Protocol::Message.new(hash)
        self.payload = payload
        self.site = site if site
        self.target = target if target
      else
        @message = Protocol::Message.new
      end
      @message.msg_size = @message.num_bytes
    rescue => ex
      raise PackError.new("Unable to pack message with args: #{args.inspect} - #{ex}")
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
      @message.msg_size = @message.num_bytes
      @message.pack
    end

    def site
      raw_site.unpack('H*').join
    end

    def site=(value)
      self.raw_site = [value].pack('H*')
    end

    def target
      raw_target.unpack('H*').join
    end

    def target=(value)
      self.raw_target = [value].pack('H*')
    end

    def raw_device
      raw_target[0...6]
    end

    def device
      raw_device.unpack('H*').join
    end

    def to_s
      hash = {site: site}
      if tagged?
        hash[:tags] = target
      else
        hash[:device] = device
      end
      hash[:type] = payload.class.to_s.sub('LIFX::Protocol::', '')
      hash[:addressable] = addressable? ? 'true' : 'false'
      hash[:tagged] = tagged? ? 'true' : 'false'
      hash[:protocol] = protocol
      hash[:payload] = payload.snapshot if payload
      attrs = hash.map { |k, v| "#{k}=#{v}" }.join(' ')
      %Q{#<LIFX::Message #{attrs}>}
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
