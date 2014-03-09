require 'socket'
module LIFX
  class Transport
    class UDP < Transport
      BUFFER_SIZE = 128

      def initialize(*args)
        super
        @socket = create_socket
      end

      def write(message)
        data = message.pack
        @socket.send(data, 0, host, port)
      end

      def listen(ip: self.host, port: self.port)
        if @listener
          raise "Socket already being listened to"
        end
        
        Thread.abort_on_exception = true
        @listener = Thread.new do
          reader = UDPSocket.new
          reader.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
          reader.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEPORT, true)
          reader.bind(ip, port)
          loop do
            begin
              bytes, (_, _, ip, _) = reader.recvfrom(128)
              message = Message.unpack(bytes)
              notify_observers(message: message, ip: ip, transport: self)
            rescue Message::UnpackError
              if !@ignore_unpackable_messages
                logger.warn("#{self}: Unrecognised bytes: #{bytes.bytes.map { |b| '%02x ' % b }.join}")
              end
            end
          end
        end
      end

      def close
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
