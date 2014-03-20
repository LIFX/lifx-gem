require 'lifx/observable'
require 'lifx/timers'

module LIFX
  # @api private
  class GatewayConnection
    # GatewayConnection handles the UDP and TCP connections to the gateway
    # A GatewayConnection is created when a new device sends a StatePanGateway
    include Timers
    include Logging
    include Observable

    MAX_TCP_ATTEMPTS = 3
    def initialize
      @threads = []
      @tcp_attempts = 0
      @threads << initialize_write_queue
    end

    def handle_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        if use_udp? && !udp_connected? && payload.service == Protocol::Device::Service::UDP
          # UDP transport here is only for sending directly to bulb
          # We receive responses via UDP transport listening to broadcast in Network
          connect_udp(ip, payload.port.to_i)
        elsif use_tcp? && !tcp_connected? && payload.service == Protocol::Device::Service::TCP && (port = payload.port.snapshot) > 0
          connect_tcp(ip, port)
        end
      else
        logger.error("#{self}: Unhandled message: #{message}")
      end
    end

    def use_udp?
      Config.allowed_transports.include?(:udp)
    end

    def use_tcp?
      Config.allowed_transports.include?(:tcp)
    end

    def udp_connected?
      @udp_transport && @udp_transport.connected?
    end

    def tcp_connected?
      @tcp_transport && @tcp_transport.connected?
    end

    def connected?
      udp_connected? || tcp_connected?
    end

    def connect_udp(ip, port)
      @udp_transport = Transport::UDP.new(ip, port)
    end

    def connect_tcp(ip, port)
      if @tcp_attempts > MAX_TCP_ATTEMPTS
        logger.info("#{self}: Ignoring TCP service of #{ip}:#{port} due to too many failed attempts.")
        return
      end
      @tcp_attempts += 1
      logger.info("#{self}: Establishing connection to #{ip}:#{port}")
      @tcp_transport = Transport::TCP.new(ip, port)
      @tcp_transport.add_observer(self) do |message:, ip:, transport:|
        notify_observers(message: message, ip: ip, transport: @tcp_transport)
      end
      @tcp_transport.listen
      at_exit do
        @tcp_transport.close if @tcp_transport
      end
    end

    def write(message)
      @queue.push(message)
    end

    def close
      @threads.each { |thr| Thread.kill(thr) }
      [@tcp_transport, @udp_transport].compact.each(&:close)
    end

    def flush(timeout: nil)
      proc = lambda do
        while !@queue.empty?
          sleep 0.05
        end
      end
      if timeout
        Timeout.timeout(timeout) do
          proc.call
        end
      else
        proc.call
      end
    end

    def to_s
      "#<LIFX::GatewayConnection tcp=#{@tcp_transport} tcp_attempts=#{@tcp_attempts} udp=#{@udp_transport}>"
    end
    alias_method :inspect, :to_s

    def set_message_rate(rate)
      @message_rate = rate
    end
    protected

    MAXIMUM_QUEUE_LENGTH   = 10
    DEFAULT_MESSAGE_RATE = 5
    def message_rate
      @message_rate || DEFAULT_MESSAGE_RATE
    end

    def initialize_write_queue
      @queue = SizedQueue.new(MAXIMUM_QUEUE_LENGTH)
      @last_write = Time.now
      Thread.abort_on_exception = true
      Thread.new do
        loop do
          if !connected?
            sleep 0.1
            next
          end
          delay = [(1.0 / message_rate) - (Time.now - @last_write), 0].max
          logger.debug("#{self}: Sleeping for #{delay}")
          sleep(delay)
          message = @queue.pop
          if !message.is_a?(Message)
            raise ArgumentError.new("Unexpected object in message queue: #{message.inspect}")
          end
          if !actually_write(message)
            logger.error("#{self}: Couldn't write, pushing back onto queue.")
            @queue << message
          end
          @last_write = Time.now
        end
      end
    end

    def check_connections
      if @tcp_transport && !tcp_connected?
        @tcp_transport = nil
        logger.info("#{self}: TCP connection dropped, clearing.")
      end

      if @udp_transport && !udp_connected?
        @udp_transport = nil
        logger.info("#{self}: UDP connection dropped, clearing.")
      end
    end

    def actually_write(message)
      check_connections

      # TODO: Support force sending over UDP
      if tcp_connected?
        if @tcp_transport.write(message)
          logger.debug("-> #{self} #{@tcp_transport}: #{message}")
          return true
        end
      end

      if udp_connected?
        if @udp_transport.write(message)
          logger.debug("-> #{self} #{@tcp_transport}: #{message}")
          return true
        end
      end

      false
    end

  end
end
