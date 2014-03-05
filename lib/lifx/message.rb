require 'forwardable'
require 'lifx/protocol_path'

module LIFX
  class Message
    include Logging
    extend Forwardable

    class MessageError < StandardError; end
    class UnpackError < MessageError; end
    class PackError < MessageError; end
    class NoPath < MessageError; end

    class InvalidFrame < UnpackError; end
    class UnsupportedProtocolVersion < UnpackError; end
    class NotAddressableFrame < UnpackError; end
    class NoPayload < PackError; end
    class UnmappedPayload < MessageError; end
    class InvalidFields < PackError; end

    PROTOCOL_VERSION = 1024

    class << self
      attr_accessor :log_invalid_messages

      def unpack(data)
        raise InvalidFrame if data.length < 2

        header = Protocol::Header.read(data)
        raise UnsupportedProtocolVersion.new("Expected #{PROTOCOL_VERSION} but got #{header.protocol} instead") if header.protocol != PROTOCOL_VERSION
        raise NotAddressableFrame if header.addressable == 0

        message = Protocol::Message.read(data)
        path = ProtocolPath.new(raw_site: message.raw_site, raw_target: message.raw_target, tagged: message.tagged)
        payload_class = message_type_for_id(message.type.snapshot)
        if payload_class.nil?
          if self.log_invalid_messages
            logger.error("Message.unpack: Unrecognised payload ID: #{message.type}")
            logger.error("Message.unpack: Message: #{message}")
          end
          return nil # FIXME
          raise UnmappedPayload.new("Unrecognised payload ID: #{message.type}")
        end
        begin
          payload = payload_class.read(message.payload)
        rescue => ex
          if message.raw_site == "\x00" * 6
            logger.info("Message.unpack: Ignoring malformed message from virgin bulb")
          else
            if self.log_invalid_messages
              logger.error("Message.unpack: Exception while unpacking payload of type #{payload_class}: #{ex}")
              logger.error("Message.unpack: Data: #{data.inspect}")
            end
          end
        end
        new(path, message, payload)
      rescue => ex
        if self.log_invalid_messages
          logger.debug("Message.unpack: Exception while unpacking #{data.inspect}")
          logger.debug("Message.unpack: #{ex} - #{ex.backtrace.join("\n")}")
        end
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

    def_delegators :path, :device_id, :site_id, :tagged
    
    attr_accessor :path, :payload
    def initialize(*args)
      if args.count == 3 
        @path, @message, @payload = args
      elsif (hash = args.first).is_a?(Hash)
        path = hash.delete(:path)
        payload = hash.delete(:payload)

        check_valid_fields!(hash)

        @message = Protocol::Message.new(hash)
        self.payload = payload
        self.path = path
        @message.tagged = path.tagged?
      else
        @message = Protocol::Message.new
      end
      @message.msg_size = @message.num_bytes
      @message.protocol = PROTOCOL_VERSION
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
      raise NoPath if !path
      @message.raw_site = path.raw_site
      @message.raw_target = path.raw_target
      @message.tagged = path.tagged?
      @message.msg_size = @message.num_bytes
      @message.pack
    end

    def to_s
      hash = {site: path.site_id}
      if path.tagged?
        hash[:tags] = path.tag_ids
        hash[:tags] = 'all' if hash[:tags].empty?
      else
        hash[:device] = path.device_id
      end
      hash[:type] = payload.class.to_s.sub('LIFX::Protocol::', '')
      hash[:addressable] = addressable? ? 'true' : 'false'
      hash[:tagged] = path.tagged? ? 'true' : 'false'
      hash[:protocol] = protocol
      hash[:payload] = payload.snapshot if payload
      attrs = hash.map { |k, v| "#{k}=#{v}" }.join(' ')
      %Q{#<LIFX::Message #{attrs}>}
    end
    alias_method :inspect, :to_s
    
    protected

    def check_valid_fields!(hash)
      invalid_fields = hash.keys - self.class.valid_fields
      if invalid_fields.count > 0
        raise InvalidFields.new("Invalid fields for Message: #{invalid_fields.join(', ')}")
      end
    end
  end
end
