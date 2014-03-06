require 'lifx/timers'
require 'lifx/transport_manager'
require 'lifx/routing_manager'
require 'lifx/tag_manager'
require 'lifx/light'
require 'lifx/protocol_path'

module LIFX
  class NetworkContext
    include Timers
    include Logging

    # A NetworkContext handles discovery and gateway connection management
    # as well as routing write messages to their intended destination

    attr_reader :tag_manager, :routing_manager
    
    def initialize
      @devices = {}

      @transport_manager = TransportManager::LAN.new
      @transport_manager.on_message do |msg, ip, transport|
        handle_message(msg, ip, transport)
      end

      @routing_manager = RoutingManager.new(context: self)
      @tag_manager = TagManager.new(context: self, tag_table: @routing_manager.tag_table)
    end

    def stop
      @threads.each do |thread|
        Thread.kill(thread)
      end
    end

    def discover
      @transport_manager.discover
    end

    def devices
      @devices.values
    end

    def tags
      @routing_manager.tags
    end

    alias_method :lights, :devices

    def send_message(target:, payload:)
      paths = @routing_manager.resolve_target(target)

      messages = paths.map do |path|
        Message.new(path: path, payload: payload)
      end
      messages.each do |message|
        @transport_manager.write(message)
      end
    end

    def register_device(device)
      device_id = device.id
      @devices[device_id] = device # What happens when there's already one registered?
    end

    # Tags

    def tags_for_device(device)
      @routing_manager.tags_for_device_id(device.id)
    end

    def add_tag_to_device(tag:, device:)
      @tag_manager.add_tag_to_device(tag: tag, device: device)
    end

    def remove_tag_from_device(tag:, device:)
      @tag_manager.remove_tag_from_device(tag: tag, device: device)
    end

    protected

    def handle_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")

      @routing_manager.update_from_message(message)
      case message.payload
      when Protocol::Device::StatePanGateway
        # Ideally this should not reach here as this is a TransportManager message
      else
        if !message.tagged?
          if @devices[message.device_id].nil?
            device = Light.new(context: self, id: message.device_id, site_id: message.site_id)
            register_device(device)
          end
          device = @devices[message.device_id]
          device.handle_message(message, ip, transport)
        end
      end
    end
  end
end
