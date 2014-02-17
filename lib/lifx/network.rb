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
      Thread.new do
        payload = Protocol::Device::GetPanGateway.new
        message = Message.new(payload: payload)
        3.times do
          @transport.write(message)
          sleep 0.25
        end
      end
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
        @sites[message.site].on_message(message, ip)
      end
    end
  end
end
