require 'socket'

module LIFX
  class Transport
    class TCP < Transport
      def initialize(host, port)
        super
        @socket = TCPSocket.new(host, port) # Performs the connection
        @socket.setsockopt(Socket::SOL_SOCKET,  Socket::SO_SNDBUF,  1024)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY,   1)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_MAXSEG,  512)
      end

      HEADER_SIZE = 8
      def listen(&block)
        return if @listener
        Thread.abort_on_exception = true
        @listener = Thread.new do
          loop do
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
              $stderr.puts("Exception in #{self}: #{ex}")
            end
          end
        end
      end

      def write(message)
        data = message.pack
        @socket.send(data, 0)
      end
    end
  end
end
