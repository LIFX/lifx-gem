require 'socket'

module LIFX
  class Transport
    class TCP < Transport
      def initialize(host, port)
        super
        connect
        at_exit do
          close
        end
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
        LOG.error("#{self}: Exception occured - #{ex}")
        LOG.error("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        @socket = nil
      end

      def reconnect
        close
        connect
      end

      def close
        return if !@socket
        Thread.kill(@listener)
        @socket.close
        @socket = nil
      end

      HEADER_SIZE = 8
      def listen(&block)
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
              
              if message
                block.call(message)
              else
                # FIXME: Make this better
                raise "Unparsable data"
              end
            rescue => ex
              LOG.error("#{self}: Exception occured - #{ex}")
              LOG.error("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
              if @socket
                LOG.error("#{self}: Reconnecting...")
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
        LOG.error("#{self}: Exception in #write: #{ex}")
        LOG.error("#{self}: Backtrace: #{ex.backtrace.join("\n")}")
        reconnect
      end
    end
  end
end
