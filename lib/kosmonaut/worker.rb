require 'json'
require 'thread'

module Kosmonaut
  class Worker < Socket
    RECONNECT_DELAY = 1000 # in milliseconds
    HEARTBEAT_INTERVAL = 500 # in milliseconds

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
            send(@sock, ["QT"])
            disconnect
            break
          end
          unless @sock
            raise Errno::ECONNREFUSED
          end

          msg = recv(@sock)
          raise Errno::ECONNRESET if @sock.eof? || msg.empty?
          Kosmonaut.log("Worker/RECV : #{msg.join("\n").inspect}")
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
        rescue Errno::EAGAIN, Errno::ECONNRESET, Errno::ECONNREFUSED, IOError => err
          Kosmonaut.log("Worker/RECONNECT: " + err.to_s)
          sleep(@reconnect_delay.to_f / 1000.0)
          reconnect
        end
        # Send heartbeat if it's time.
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

    def send(s, payload, with_identity=false)
      return unless s
      packet = pack(payload, with_identity)
      s.write(packet)
      Kosmonaut.log("Worker/SENT : #{packet.inspect}")
    rescue Errno::EPIPE
    end

    def disconnect
      @sock.close if @sock 
    rescue IOError
    end
      
    def reconnect
      @sock = connect(((@heartbeat_ivl * 2).to_f / 1000.0).to_i + 1)
      send(@sock, ["RD"], true)
      @heartbeat_at = Time.now.to_f + (@heartbeat_ivl.to_f / 1000.0)
    rescue Errno::ECONNREFUSED
    end

    def message_handler(data)
      if respond_to?(:on_message)
        payload = JSON.parse(data.to_s)
        on_message(*payload.first)
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
