require 'lifx/timers'
require 'lifx/site'

module LIFX
  class Network
    include Timers

    def initialize(broadcast_ip, port)
      # TODO: Rate limiting
      @broadcast_ip = broadcast_ip
      @port         = port
      @sites        = {}
      @threads      = []
      @sites_lock   = Mutex.new
      @threads << initialize_transport
      initialize_stale_site_checking
      @threads << initialize_timer_thread
    end

    def stop
      @threads.each do |thread|
        Thread.kill(thread)
      end
    end

    DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND = 1    # seconds
    DISCOVERY_INTERVAL                     = 20   # seconds
    def discover
      stop_discovery
      Thread.abort_on_exception = true
      @discovery_thread = Thread.new do
        message = Message.new(payload: Protocol::Device::GetPanGateway.new)
        LOG.info("Discovering gateways on #{@broadcast_ip}:#{@port}")
        loop do
          @transport.write(message)
          if sites.empty?
            sleep(DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND)
          else
            sleep(DISCOVERY_INTERVAL)
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

    def sites_hash
      @sites.dup
    end

    def to_s
      %Q{#<LIFX::Network broadcast_ip=#{@broadcast_ip} port=#{@port}>}
    end
    alias_method :inspect, :to_s

    protected

    def initialize_transport
      @transport = Transport::UDP.new(@broadcast_ip, @port)
      @transport.listen do |message, ip|
        on_message(message, ip)
      end
    end

    STALE_SITE_CHECK_INTERVAL = 5
    def initialize_stale_site_checking
      timers.every(STALE_SITE_CHECK_INTERVAL) do
        remove_stale_sites
      end
    end

    STALE_SITE_THRESHOLD = 30 # seconds
    def remove_stale_sites
      LOG.info("#{self}: Checking for stale sites")
      @sites_lock.synchronize do
        stale_sites = @sites.values.select { |site| site.age > STALE_SITE_THRESHOLD }
        stale_sites.each do |site|
          LOG.info("#{self}: Removing #{site} as age is #{site.age}")
          site.stop
          @sites.delete(site.id)
        end
      end
    end

    def on_message(message, ip)
      case message.payload
      when Protocol::Device::StatePanGateway
        @sites_lock.synchronize do
          if !@sites.has_key?(message.site)
            LOG.info("Discovered new site #{message.site} at #{ip}")
            @sites[message.site] = Site.new(message.site)
          end
          @sites[message.site].on_message(message, ip, @transport)
        end
      end
    end
  end
end
