require 'lifx/timers'
require 'lifx/transport_manager'
require 'lifx/light'

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
    end

    def stop
      @threads.each do |thread|
        Thread.kill(thread)
      end
    end

    def discover
      @transport_manager.discover
    end

    def send_to_site(params)
      @transport_manager.write(params)
    end

    def send_to_device(device: nil, site: nil, payload: nil, method: :best)
      site ||= resolve_site_id_for_device_id(device)

      # If no site found, send it to all known sites
      # If there are no known sites, throw exception
      if site.nil?
        raise "Can't handle no sites being resolved yet"
      end

      send_message(tagged: false, device: device, site: site, payload: payload)
    end

    def send_to_all(site: nil, payload: nil, method: :best)
      if site.nil?
        @device_sites.values.each do |site|
          send_message(site: true, tagged: true, payload: payload)
        end
      else
        send_message(site, tagged: true, payload: payload)
      end
    end

    def register_device(device)
      device_id = device.id
      @devices[device_id] = device # What happens when there's already one registered?
    end

    def devices
      @devices.values
    end
    alias_method :lights, :devices

    def handle_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")

      @device_site[message.device] = message.site unless message.tagged
      case message.payload
      when Protocol::Device::StatePanGateway
      else
        if !message.tagged
          if @devices[message.device].nil?
            device = Light.new(self, id: message.device)
            register_device(device)
          end
          device = @devices[message.device]
          device.handle_message(message, ip, transport)
        end
      end
    end

    protected

    def resolve_site_id_for_device_id(device_id)
      @device_site[device_id]
    end
  end
end
