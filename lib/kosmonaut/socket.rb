module Kosmonaut
  class Socket
    attr_reader :uri

    def initialize(url)
      @uri = URI.parse(url)
      generate_identity
    end

    protected

    def connect
      TCPSocket.open(@uri.host, @uri.port)
    end

    def pack(payload=[])
      payload.unshift("")
      payload.unshift(@identity)
      payload.join("\n") + "\n\r\n\r\n"
    end

    def recv(s)
      data = []
      possible_eom = false # possible end of message
      while !s.eof?
        line = s.gets
        if line == "\r\n"
          break if possible_eom
          possible_eom = true
        else
          possible_eom = false
          data << line.strip
        end
      end
      data
    end
    
    private

    def generate_identity
      parts = []
      parts << socket_type
      parts << @uri.path
      parts << @uri.user # secret
      parts << SecureRandom.uuid
      @identity = parts.join(":")
    end
  end
end
