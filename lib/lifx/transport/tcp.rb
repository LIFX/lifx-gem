require 'socket'

module LIFX
  class Transport
    class TCP < Transport
      include Logging

      def initialize(*args)
        super
        connect
      end

      def connected?
        @socket && !@socket.closed?
      end

      def connect
        @socket = TCPSocket.new(host, port) # Performs the connection
        @socket.setsockopt(Socket::SOL_SOCKET,  Socket::SO_SNDBUF,    1024)
        @socket.setsockopt(Socket::SOL_SOCKET,  Socket::SO_KEEPALIVE, true)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY,  1)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_MAXSEG,   512)
      rescue => ex
        logger.error("#{self}: Exception occured - #{ex}")
        logger.error("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        @socket = nil
      end

      def reconnect
        @socket.close
        connect
      end

      def close
        return if !@socket
        Thread.kill(@listener)
        @socket.close
        @socket = nil
      end

      HEADER_SIZE = 8
      def listen
        return if @listener
        Thread.abort_on_exception = true
        @listener = Thread.new do
          while @socket do
            begin
              header_data = @socket.recv(HEADER_SIZE, Socket::MSG_PEEK)
              header = Protocol::Header.read(header_data)
              size = header.msg_size
              data = @socket.recv(size)
              message = Message.unpack(data)
              
              notify_observers(message: message, ip: host, transport: self)
            rescue Message::UnpackError
              if !@ignore_unpackable_messages
                logger.error("#{self}: Exception occured - #{ex}")
              end
            rescue => ex
              logger.error("#{self}: Exception occured - #{ex}")
              logger.error("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
              if @socket
                logger.error("#{self}: Reconnecting...")
                reconnect
              end
            end
          end
        end
      end

      def write(message)
        data = message.pack
        @socket.write(data)
      rescue => ex
        logger.error("#{self}: Exception in #write: #{ex}")
        logger.error("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        reconnect
      end
    end
  end
end
