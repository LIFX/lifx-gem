require 'lifx/seen'
require 'lifx/timers'
require 'lifx/observable'
require 'lifx/gateway_connection'

module LIFX
  # @api private
  class Site
    include Seen
    include Timers
    include Logging
    include Observable
    
    attr_reader :id, :gateways, :tag_manager

    def initialize(id:)
      @id            = id
      @gateways      = {}
      @gateways_mutex = Mutex.new
      @threads       = []
      @threads << defer_lights_discovery
      @threads << initialize_timer_thread
      initialize_stale_gateway_check
    end

    def write(message)
      message.path.site_id = id
      @gateways.values.each do |gateway|
        gateway.write(message)
      end
    end

    def handle_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        @gateways_mutex.synchronize do
          @gateways[message.device_id] ||= GatewayConnection.new
          @gateways[message.device_id].handle_message(message, ip, transport)
          @gateways[message.device_id].add_observer(self) do |**args|
            notify_observers(**args)
          end
        end
      end
      seen!
    end

    def flush(**options)
      @gateways.values.map do |gateway|
        Thread.new do
          gateway.flush(**options)
        end
      end.each(&:join)
    end
    
    def to_s
      %Q{#<LIFX::Site id=#{id}>}
    end
    alias_method :inspect, :to_s

    def stop
      @threads.each do |thread|
        Thread.kill(thread)
      end
      @gateways.values.each do |gateway|
        gateway.close
      end
    end

    def scan_lights
      write(Message.new(path: ProtocolPath.new(tagged: true), payload: Protocol::Light::Get.new))
    end

    protected

    def defer_lights_discovery
      # We wait a bit so the TCP transport has a chance to connect
      Thread.new do
        while gateways.empty?
          sleep 0.1
        end
        scan_lights
      end
    end

    STALE_GATEWAY_CHECK_INTERVAL = 10
    def initialize_stale_gateway_check
      timers.every(STALE_GATEWAY_CHECK_INTERVAL) do
        @gateways_mutex.synchronize do
          stale_gateways = @gateways.select do |k, v|
            !v.connected?
          end
          stale_gateways.each do |id, _|
            logger.info("#{self}: Dropping stale gateway id #{id}")
            @gateways.delete(id)
          end
        end
      end
    end

  end
end
