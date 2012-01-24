require 'json'
require 'thread'

module Kosmonaut
  class Client < Socket
    # Maximum number of seconds to wait for the request to being processed.
    REQUEST_TIMEOUT = 5.0

    # Public: The Client constructor. Pre-configures the client instance. See
    # also the Kosmonaut::Socket#initialize for the details.
    # 
    # url - The WebRocket backend endpoint URL to connect to.
    #
    # The endpoint's URL must have the following format:
    #
    #     [scheme]://[secret]@[host]:[port]/[vhost]
    #
    # Examples
    #
    #     c = Kosmonaut::Client.new("wr://f343...fa4a@myhost.com:8080/hello")
    #     c.broadcast("room", "status", {"message" => "is going to the beach!"})
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
    def broadcast(channel, event, data)
      payload = ["BC", channel, event, data.to_json]
      perform_request(payload)
    end

    def open_channel(name)
      payload = ["OC", name]
      perform_request(payload)
    end

    def close_channel(name)
      payload = ["CC", name]
      perform_request(payload)
    end

    def request_single_access_token(uid, permission)
      payload = ["AT", uid, permission]
      perform_request(payload)
    end

    def socket_type
      "req"
    end

    private

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
