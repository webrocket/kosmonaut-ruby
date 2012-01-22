require 'uri'
require 'socket'
require 'securerandom'

module Kosmonaut
  class Socket
    attr_reader :uri

    def initialize(url)
      @uri = URI.parse(url)
      @addr = ::Socket.getaddrinfo(@uri.host, nil)
    end

    def connect(timeout)
      secs   = timeout.to_i
      usecs  = ((timeout - secs) * 1_000_000).to_i
      optval = [secs, usecs].pack("l_2")
      
      s = ::Socket.new(::Socket.const_get(@addr[0][0]), ::Socket::SOCK_STREAM, 0)
      s.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)
      s.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_RCVTIMEO, optval)
      s.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_SNDTIMEO, optval)
      s.connect(::Socket.pack_sockaddr_in(@uri.port, @addr[0][3]))
      
      generate_identity
      return s
    end

    protected

    def pack(payload=[], with_identity=true)
      if with_identity
        payload.unshift("")
        payload.unshift(@identity) 
      end
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
