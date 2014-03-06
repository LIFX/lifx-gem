require 'lifx/timers'

module LIFX
  class GatewayConnection
    # GatewayConnection handles the UDP and TCP connections to the gateway
    # A GatewayConnection is created when a new device sends a StatePanGateway
    include Timers
    include Logging

    def initialize
      @threads = []
      @threads << initialize_write_queue
    end

    def on_message(&block)
      @message_handler = block
    end

    def handle_message(message, ip, transport)
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
        if @message_handler
          @message_handler.call(msg, ip, @tcp_transport)
        end
      end
      at_exit do
        @tcp_transport.close
      end
    end

    def write(message)
      @queue << message
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

    def best_transport
      @tcp_transport || @udp_transport
    end

    protected

    MINIMUM_TIME_BETWEEN_MESSAGE_SEND = 0.2
    MAXIMUM_QUEUE_LENGTH = 100

    def initialize_write_queue
      @queue = SizedQueue.new(MAXIMUM_QUEUE_LENGTH)
      @last_write = Time.now
      Thread.new do
        loop do
          if best_transport.nil?
            sleep 0.1
            next
          end
          message = @queue.pop
          if !message.is_a?(Message)
            raise ArgumentError.new("Unexpected object in message queue: #{message.inspect}")
          end
          delay = [MINIMUM_TIME_BETWEEN_MESSAGE_SEND - (Time.now - @last_write), 0].max
          logger.debug("#{self}: Sleeping for #{delay}")
          sleep(delay)
          actually_write(message)
          @last_write = Time.now
        end
      end
    end

    def actually_write(message)
      # TODO: Support force sending over UDP
      logger.debug("-> #{self} #{best_transport}: #{message}")
      best_transport.write(message)
    end

  end
end
