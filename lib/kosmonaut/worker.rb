require 'json'
require 'thread'

module Kosmonaut
  class Worker < Socket
    include Kosmonaut

    RECONNECT_DELAY = 1000 # in milliseconds
    HEARTBEAT_INTERVAL = 2000 # in milliseconds

    def initialize(url)
      super(url)
      @mtx = Mutex.new
      @sock = nil
      @alive = false
      @reconnect_delay = RECONNECT_DELAY
      @heartbeat_ivl = HEARTBEAT_INTERVAL
      @heartbeat_at = 0
    end

    def listen
      @alive = true
      reconnect
      while true
        begin
          if !alive?
            send(@sock, ["QT"]) if @sock
            disconnect
            break
          end
          unless @sock
            raise Errno::ECONNREFUSED
          end
          Timeout.timeout(((@heartbeat_ivl * 2).to_f / 1000.0).to_i + 1) {
            msg = recv(@sock)
            raise Errno::ECONNRESET if @sock.eof? || msg.empty?
            log("Worker/RECV : #{msg.join("\n").inspect}")
            cmd = msg.shift
              
            case cmd
            when "HB"
              # nothing to do...
            when "QT"
              reconnect
              next
            when "TR"
              message_handler(msg[0])
            when "ER"
              error_handler(msg.size < 1 ? 597 : msg[0])
            end
          }
        rescue Timeout::Error, Errno::ECONNRESET, Errno::ECONNREFUSED => err
          log("Worker/RECONNECT: " + err.to_s)
          sleep(@reconnect_delay.to_f / 1000.0)
          reconnect
        end
        if Time.now.to_f > @heartbeat_at && @sock
          send(@sock, ["HB"])
          @heartbeat_at = Time.now.to_f + (@heartbeat_ivl.to_f / 1000.0)
        end
      end
    end
    
    def stop
      @mtx.synchronize { @alive = false }
    end

    def alive?
      @mtx.synchronize { @alive }
    end

    def socket_type
      "dlr"
    end

    private

    def send(s, payload)
      packet = pack(payload)
      @sock.write(packet)
      log("Worker/SENT : #{packet.inspect}")
    end

    def disconnect
      if @sock
        @sock.close
        @sock = nil
      end
    end

    def reconnect
      disconnect
      @sock = connect
      send(@sock, ["RD"])
      @heartbeat_at = Time.now.to_f + (@heartbeat_ivl.to_f / 1000.0)      
    rescue Errno::ECONNREFUSED
    end

    def message_handler(data)
      if respond_to?(:on_message)
        payload = JSON.parse(data.to_s)
        event = payload.keys.first
        data = data[event]
        on_message(event, data)
      end
    rescue => err
      exception_handler(err)
    end

    def error_handler(errcode)
      if respond_to?(:on_error)
        err = ERRORS[errcode.to_i]
        on_error(err ? err : UnknownServerError)
      end
    rescue => err
      exception_handler(err)
    end

    def exception_handler(err)
      if respond_to?(:on_exception)
        on_exception(err)
      else
        raise err
      end
    end
  end
end
