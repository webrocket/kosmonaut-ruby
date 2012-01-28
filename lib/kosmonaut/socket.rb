# Copyright (C) 2012 Krzysztof Kowalik <chris@nu7hat.ch> and folks at Cubox
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
 
require 'uri'
require 'socket'
require 'securerandom'

module Kosmonaut
  # Internal: Socket is a base class defining tools and helpers used by 
  # Client and Worker implementations.
  class Socket
    # Public: A parsed URL of the WebRocket backend endpoint.
    attr_reader :uri

    # Internal: The Socket constructor. 
    #
    # The endpoint's URL must have the following format:
    #
    #     [scheme]://[secret]@[host]:[port]/[vhost]
    #
    def initialize(url)
      @uri = URI.parse(url)
      @addr = ::Socket.getaddrinfo(@uri.host, nil)
    end

    protected

    # Internal: Connect creates new connection with the backend endpoint.
    #
    # timeout - A value of the maximum execution time (float).
    #
    # Returns configured and connected socket instance.
    def connect(timeout)
      secs = timeout.to_i
      usecs = ((timeout - secs) * 1_000_000).to_i
      optval = [secs, usecs].pack("l_2")
      
      # Raw timeouts are way way way faster than Timeout module or SystemTimer
      # and doesn't need external dependencies. 
      s = ::Socket.new(::Socket.const_get(@addr[0][0]), ::Socket::SOCK_STREAM, 0)
      s.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)
      s.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_RCVTIMEO, optval)
      s.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_SNDTIMEO, optval)
      s.connect(::Socket.pack_sockaddr_in(@uri.port, @addr[0][3]))
      
      generate_identity!
      return s
    end

    # Internal: Pack converts given payload into single packet in format
    # defined by WebRocket Backend Protocol.
    #
    # Packet format
    #
    #     0x01 | identity     \n | *
    #     0x02 |              \n | *
    #     0x03 | command      \n |
    #     0x04 | payload...   \n | *
    #     0x.. | ...          \n | *
    #          |        \r\n\r\n | 
    #
    # * - optional field
    #
    # payload       - The data to be packed.
    # with_identity - Whether identity should be prepend to the packet.
    #
    # Returns packed data.
    def pack(payload=[], with_identity=true)
      if with_identity
        payload.unshift("")
        payload.unshift(@identity) 
      end
      payload.join("\n") + "\n\r\n\r\n"
    end

    # Internal: Reads one packet from given socket instance.
    #
    # sock - The socket to receive from.
    #
    # Returns received data (frames) as an array of strings.
    def recv(sock)
      data = []
      possible_eom = false # possible end of message
      while !sock.eof?
        line = sock.gets
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

    # Internal: Generates unique identity for the socket connection.
    # Identity is composed from the following parts:
    #
    #     [socket-type]:[vhost]:[vhost-token]:[uuid]
    #
    def generate_identity!
      @identity = [socket_type, @uri.path, @uri.user, SecureRandom.uuid].join(":")
    end
  end
end
