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
        while @sites.empty? do
          @transport.write(message)
          sleep 0.25
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
      case message.payload
      when Protocol::Device::StatePanGateway
        @sites[message.site] ||= Site.new(message.site, @transport)
        @sites[message.site].on_message(message, ip, @transport)
      else
        puts "#{@transport.inspect}: #{message.inspect}"
      end
    end
  end
end
