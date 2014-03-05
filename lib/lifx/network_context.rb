require 'lifx/timers'
require 'lifx/transport_manager'
require 'lifx/routing_table'
require 'lifx/light'
require 'lifx/protocol_path'

module LIFX
  class NetworkContext
    include Timers
    include Logging

    # A NetworkContext handles discovery and gateway connection management
    # as well as routing write messages to their intended destination

    def initialize
      @device_site = {}

      @devices = {}

      @transport_manager = TransportManager::LAN.new
      @transport_manager.on_message do |msg, ip, transport|
        handle_message(msg, ip, transport)
      end

      @routing_table = RoutingTable.new
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
    alias_method :lights, :devices

    def send_message(target: nil, payload:nil)
      paths = resolve_paths_for_target(target)
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

    protected

    def handle_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")

      @routing_table.update_from_message(message)
      case message.payload
      when Protocol::Device::StatePanGateway
      else
        if !message.tagged
          if @devices[message.device_id].nil?
            device = Light.new(context: self, id: message.device_id)
            register_device(device)
          end
          device = @devices[message.device_id]
          device.handle_message(message, ip, transport)
        end
      end
    end

    def resolve_paths_for_target(target)
      if target.tag?
        raise "can't handle this yet"
      elsif target.broadcast?
        raise "can't handle this yet"
      else
        site_id = @routing_table.site_id_for_device_id(target.device_id)
        if site_id
          [ProtocolPath.new(site_id: site_id, device_id: target.device_id)]
        else
          @routing_table.site_ids.map { |site_id| ProtocolPath.new(site_id: site_id, device_id: target.device_id)}
        end
      end
    end
  end
end
