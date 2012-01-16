require 'json'
require 'uri'
require 'socket'
require 'securerandom'
require 'timeout'
require 'thread'

module Kosmonaut
  class Client < Socket
    include Kosmonaut

    REQUEST_TIMEOUT = 5 # in seconds

    def initialize(url)
      super(url)
      @mtx = Mutex.new
    end

    def broadcast(channel, event, data)
      payload = ["BC", channel, event, data.to_json]
      perform_request(payload)
    end

    def open_channel(name, type)
      payload = ["OC", name, type]
      perform_request(payload)
    end

    def close_channel(name)
      payload = ["CC", name]
      perform_request(payload)
    end

    def request_single_access_token(permission)
      payload = ["AT", permission]
      perform_request(payload)
    end

    def socket_type
      "req"
    end

    private

    def perform_request(payload)
      @mtx.synchronize {
        response = []
        Timeout.timeout(REQUEST_TIMEOUT) {
          s = connect
          packet = pack(payload)
          log("Client/REQ : #{packet.inspect}")
          s.write(packet)
          response = recv(s)
          s.close
        }
        parse_response(response)
      }
    end

    def parse_response(response)
      cmd = response[0].to_s
      log("Client/RES : #{response.join("\n").inspect}")
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
