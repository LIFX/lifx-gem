require 'lifx/timers'

module LIFX
  class GatewayConnection
    # GatewayConnection handles the UDP and TCP connections to the gateway
    # A GatewayConnection is created when a new device sends a StatePanGateway
    include Timers
    include Logging

    attr_reader :site, :ip
    def initialize(site, ip)
      @site = site
      @ip = ip
    end

    def on_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        if !@udp_transport && payload.service == Protocol::Device::Service::UDP
          # UDP transport here is only for sending directly to bulb
          # We receive responses via UDP transport listening to broadcast in Network
          @udp_transport = Transport::UDP.new(ip, payload.port.snapshot)
        elsif !@tcp_transport && payload.service == Protocol::Device::Service::TCP && (port = payload.port.snapshot) > 0
          connect(ip, port)
        end
      else
        logger.error("#{self}: Unhandled message: #{message}")
      end
    end

    def connect(ip, port)
      logger.info("#{self}: Establishing connection to #{ip}:#{port}")
      @tcp_transport = Transport::TCP.new(ip, port)
      @tcp_transport.listen do |msg, ip|
        site.on_message(msg, ip, @tcp_transport)
      end
      at_exit do
        @tcp_transport.close
      end
    end

    def write(message)
      # TODO: Support force sending over UDP
      logger.debug("-> #{self} #{best_transport}: #{message}")
      best_transport.write(message)
    end

    def close
      [@tcp_transport, @udp_transport].compact.each(&:close)
    end

    def best_transport
      @tcp_transport || @udp_transport
    end
  end
end
