# Copyright (C) 2012 Krzysztof Kowalik <chris@nu7hat.ch> and folks at Cubox
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
 
require 'json'
require 'thread'

module Kosmonaut
  # Public: Client is an implementation REQ-REP type socket which handles
  # communication between backend application and WebRocket backend endpoint.
  #
  # Client is used to synchronously request operations from the server.
  # Synchronous operations are used to provide consistency for the backed
  # generated events.
  #
  # Examples
  #
  #     c = Kosmonaut::Client.new("wr://token@127.0.0.1:8081/vhost")
  #     c.open_channel("comments")
  #     
  #     @comment = User.new(params[:comment])
  #     
  #     if @comment.save
  #       c.broadcast("comments", "comment_added", @comment.to_json)
  #       # ...
  #     end
  #
  class Client < Socket
    # Maximum number of seconds to wait for the request to being processed.
    REQUEST_TIMEOUT = 5.0

    # Public: The Client constructor. Pre-configures the client instance. See
    # also the Kosmonaut::Socket#initialize to get more information.
    # 
    # url - The WebRocket backend endpoint URL to connect to.
    #
    def initialize(url)
      super(url)
      @mtx = Mutex.new
    end

    # Public: Broadcasts a event with attached data on the specified channel.
    # The data attached to the event must be a hash!
    #
    # channel - A name of the channel to broadcast to.
    # event   - A name of the event to be triggered.
    # data    - The data attached to the event.
    #
    # Examples
    #
    #     c.broadcast("room", "away", {"message" => "on the meeting"})
    #     c.broadcast("room". "message", {"content" => "Hello World!"})
    #     c.broadcast("room". "status", {"message" => "is saying hello!"})
    #
    # Returns 0 if succeed.
    # Raises one of the Kosmonaut::Error inherited exceptions.
    def broadcast(channel, event, data)
      payload = ["BC", channel, event, data.to_json]
      perform_request(payload)
    end
    
    # Public: Opens specified channel. If channel already exists, then ok 
    # response will be received anyway. If channel name is starts with the
    # `presence-` or `private-` prefix, then appropriate type of the channel
    # will be created.
    #
    # name - A name of the channel to be created.
    #
    # Examples
    #
    #     c.open_channel("room")
    #     c.open_channel("presence-room")
    #     c.open_channel("private-room")
    # 
    # Returns 0 if succeed.
    # Raises one of the Kosmonaut::Error inherited exceptions.
    def open_channel(name)
      payload = ["OC", name]
      perform_request(payload)
    end

    # Public: Closes specified channel. If channel doesn't exist then an
    # error will be thrown.
    #
    # name - A name of the channel to be deleted.
    #
    # Examples
    #
    #     c.close_channel("hello")
    #     c.close_channel("presence-room")
    #
    # Returns 0 if succeed.
    # Raises one of the Kosmonaut::Error inherited exceptions.
    def close_channel(name)
      payload = ["CC", name]
      perform_request(payload)
    end

    # Public: Sends a request to generate a single access token for given
    # user with specified permissions.
    #
    # uid        - An user defined unique ID.
    # permission - A permissions regexp to match against the channels.
    #
    # Examples
    #
    #     @current_user = User.find(params[:id])
    #     c.request_single_access_token(@current_user.username, ".*")
    #
    # 
    # Returns generated access token string if succeed.
    # Raises one of the Kosmonaut::Error inherited exceptions.
    def request_single_access_token(uid, permission)
      payload = ["AT", uid, permission]
      perform_request(payload)
    end

    private

    # Internal: Returns abbreviation of the socket type.
    def socket_type
      "req"
    end

    # Internal: Performs request with specified payload and waits for the
    # response with it's result.
    #
    # Returns response result if succeed.
    # Raises one of the Kosmonaut::Error inherited exceptions.
    def perform_request(payload)
      @mtx.synchronize {
        response = []
        s = connect(REQUEST_TIMEOUT)
        packet = pack(payload)
        Kosmonaut.log("Client/REQ : #{packet.inspect}")
        s.write(packet)
        response = recv(s)
        s.close
        parse_response(response)
      }
    end

    # Internal: Parses given response and discovers it's result according
    # to the WebRocket Backend Protocol specification.
    #
    # Response format
    #
    #     0x01 | command      \n |
    #     0x02 | payload...   \n | *
    #     0x.. | ...          \n | *
    #          |        \r\n\r\n | 
    #
    # Returns response result if succeed.
    # Raises one of the Kosmonaut::Error inherited exceptions.
    def parse_response(response)
      cmd = response[0].to_s
      Kosmonaut.log("Client/RES : #{response.join("\n").inspect}")
      case cmd
      when "OK"
        return 0
      when "ER"
        errcode = response[1].to_i
        error = ERRORS[errcode]
        raise error.new if error
      when "AT"
        token = response[1].to_s
        return token if token.size == 128
      end
      raise UnknownServerError.new
    end
  end
end
