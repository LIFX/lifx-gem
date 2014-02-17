require 'socket'
module LIFX
  class Transport
    class UDP < Transport
      BUFFER_SIZE = 128
      
      def initialize(host, port)
        super
        @socket = create_socket
      end

      def write(message)
        @socket.write(message.pack, 0, host, port)
      end

      def listen(&block)
        Thread.abort_on_exception = true
        @listener = Thread.new do
          @socket.bind(host, port)
          loop do
            bytes, ip = @socket.recvfrom(BUFFER_SIZE)
            message = Message.unpack(bytes)

            if message
              block.call(message, ip)
            end
          end
        end
      end

      def stop
        Thread.kill(@listener) if @listener
      end

      protected

      def create_socket
        UDPSocket.new.tap do |socket|
          socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
        end
      end
    end
  end
end
