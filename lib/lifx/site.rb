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
    include RequiredKeywordArguments

    attr_reader :id, :gateways, :tag_manager

    def initialize(id: required!(:id))
      @id            = id
      @gateways      = {}
      @gateways_mutex = Mutex.new
      @threads       = []
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
          @gateways[message.device_id].add_observer(self, :message_received) do |**args|
            notify_observers(:message_received, **args)
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

    def observer_callback_definition
      {
        message_received: -> (message: nil, ip: nil, transport: nil) {}
      }
    end


    protected

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
