module LIFX
  class Network
    def initialize(broadcast_ip, port)
      # TODO: Rate limiting
      @sites = {}
      @transport = Transport::UDP.new(broadcast_ip, port)
      @transport.listen do |message, ip|
        on_message(message, ip)
      end
    end

    def discover
      stop_discovery
      Thread.abort_on_exception = true
      @discovery_thread = Thread.new do
        payload = Protocol::Device::GetPanGateway.new
        message = Message.new(payload: payload)
        loop do
          @transport.write(message)
          if @sites.empty?
            sleep 0.25
          else
            break
          end
        end
      end
    end

    def stop_discovery
      Thread.kill(@discovery_thread) if @discovery_thread
    end

    def sites
      @sites.values
    end

    protected

    def on_message(message, ip)
      puts "#{@transport.inspect}: #{message.inspect}"
      case message.payload
      when Protocol::Device::StatePanGateway
        @sites[message.site] ||= Site.new(message.site, @transport)
        @sites[message.site].on_message(message, ip, @transport)
      end
    end
  end
end
