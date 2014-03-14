require 'lifx/observable'
require 'lifx/timers'

module LIFX
  class GatewayConnection
    # GatewayConnection handles the UDP and TCP connections to the gateway
    # A GatewayConnection is created when a new device sends a StatePanGateway
    include Timers
    include Logging
    include Observable

    def initialize
      @threads = []
      @threads << initialize_write_queue
    end

    def handle_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        if !udp_connected? && payload.service == Protocol::Device::Service::UDP
          # UDP transport here is only for sending directly to bulb
          # We receive responses via UDP transport listening to broadcast in Network
          connect_udp(ip, payload.port.to_i)
        elsif !tcp_connected? && payload.service == Protocol::Device::Service::TCP && (port = payload.port.snapshot) > 0
          connect_tcp(ip, port)
        end
      else
        logger.error("#{self}: Unhandled message: #{message}")
      end
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
      logger.info("#{self}: Establishing connection to #{ip}:#{port}")
      @tcp_transport = Transport::TCP.new(ip, port)
      @tcp_transport.add_observer(self) do |message:, ip:, transport:|
        notify_observers(message: message, ip: ip, transport: @tcp_transport)
      end
      @tcp_transport.listen
      at_exit do
        @tcp_transport.close
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

    protected

    # Due to an issue in the 1.1 firmware, we have to rate limit message sends
    # otherwise it can cause the gateway to lock up.
    MINIMUM_TIME_BETWEEN_MESSAGE_SEND = 1 / 5.0
    MAXIMUM_QUEUE_LENGTH = 10

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
          delay = [MINIMUM_TIME_BETWEEN_MESSAGE_SEND - (Time.now - @last_write), 0].max
          logger.debug("#{self}: Sleeping for #{delay}")
          sleep(delay)
          Thread.exclusive do
            message = @queue.pop
            if !message.is_a?(Message)
              raise ArgumentError.new("Unexpected object in message queue: #{message.inspect}")
            end
            if !actually_write(message)
              logger.error("#{self}: Couldn't write, pushing back onto queue.")
              @queue << message 
            end
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
