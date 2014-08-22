require 'socket'

module LIFX
  class Transport
    # @api private
    # @private
    class TCP < Transport
      include Logging

      def initialize(*args)
        super
        connect
      end

      def connected?
        !!(@socket && !@socket.closed?)
      end

      CONNECT_TIMEOUT = 3
      def connect
        Timeout.timeout(CONNECT_TIMEOUT) do
          @socket = TCPSocket.new(host, port) # Performs the connection
        end
        @socket.setsockopt(Socket::SOL_SOCKET,  Socket::SO_SNDBUF,    1024)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY,  1)
        logger.info("#{self}: Connected.")
      rescue => ex
        logger.warn("#{self}: Exception occurred in #connect - #{ex}")
        logger.debug("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        @socket = nil
      end

      def close
        super
        return if !@socket
        if !@socket.closed?
          @socket.close
          notify_observers(:disconnected)
        end
        @socket = nil
        if @listener
          @listener.abort
        end
        @listener = nil
      end

      HEADER_SIZE = 8
      def listen
        return if @listener
        @listener = Thread.start do
          while @socket do
            begin
              header_data = @socket.recv(HEADER_SIZE, Socket::MSG_PEEK)
              header      = Protocol::Header.read(header_data)
              size        = header.msg_size
              data        = @socket.recv(size)
              message     = Message.unpack(data)

              notify_observers(:message_received, {message: message, ip: host, transport: self})
            rescue Message::UnpackError
              if Config.log_invalid_messages
                logger.info("#{self}: Exception occurred while decoding message - #{ex}")
                logger.info("Data: #{data.inspect}")
              end
            rescue => ex
              logger.warn("#{self}: Exception occurred in #listen - #{ex}")
              logger.debug("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
              close
            end
          end
        end
      end

      SEND_TIMEOUT = 2
      def write(message)
        data = message.pack
        Timeout.timeout(SEND_TIMEOUT) do
          @socket.write(data)
        end
        true
      rescue => ex
        logger.warn("#{self}: Exception in #write: #{ex}")
        logger.debug("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        close
        false
      end
    end
  end
end
