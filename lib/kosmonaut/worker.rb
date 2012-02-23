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
  # Public: Worker is an implementation of SUBSCRIBER socket which handles
  # events incoming from the WebRocket backend endpoint.
  #
  # The communication here is asynchronous, and Worker can't send other
  # messages than ready state, heartbeat, or quit notification.
  #
  # Worker shouldn't be called directly, it should be used as a base class
  # for implementing your own workers.
  #
  # Examples
  #
  #     class MyWorker < Kosmonaut::Worker
  #       def on_message(event, data)
  #         if event == "append_chat_history"
  #           @room = Room.find(data[:room_id])
  #           @room.messages.build(data[:message])
  #           @room.save!
  #         end
  #       end
  #  
  #       def on_error(err)
  #         puts "WEBROCKET ERROR: #{err.to_s}"
  #       end
  #
  #       def on_exception(err)
  #         puts "INTERNAL ERROR: #{err.to_s}"
  #       end
  #     end
  #
  #     w = MyWorker.new("wr://token@127.0.0.1:8081/vhost")
  #     w.listen
  # 
  class Worker < Socket
    # Number of milliseconds after which client should retry to reconnect
    # to the bakcend endpoint.
    RECONNECT_DELAY = 1000

    # Number of milliseconds between next heartbeat message.
    HEARTBEAT_INTERVAL = 500

    # Public: The Worker constructor. Pre-configures the worker instance. See
    # also the Kosmonaut::Socket#initialize to get more information.
    #
    # url - The WebRocket backend endpoint URL to connect to.
    #
    def initialize(url)
      super(url)
      @mtx = Mutex.new
      @sock = nil
      @alive = false
      @reconnect_delay = RECONNECT_DELAY
      @heartbeat_ivl = HEARTBEAT_INTERVAL
      @heartbeat_at = 0
    end

    # Public: Listen starts a listener's loop for the worker. Listener implements
    # the Majordomo pattern to manage connection with the backend. 
    #
    # Raises Kosmonaut::UnauthorizedError if worker's credentials are invalid.
    def listen
      return false if alive?
      @alive = true
      reconnect

      while true
        disconnect and break unless alive?
        receive_and_process or reconnect(true)
        heartbeat if Time.now.to_f > @heartbeat_at
      end
    end
    
    # Public: Breaks the listener's loop and stops execution of
    # the worker. 
    def stop
      @mtx.synchronize { @alive = false }
    end

    # Public: Returns whether this worker's event loop is running.
    def alive?
      @mtx.synchronize { @alive }
    end

    private

    # Internal: Returns abbreviation of the socket type.
    def socket_type
      "dlr"
    end

    # Internal: Receives a message from the server and dispatches it.
    # 
    # Returns false if message couldn't be processed or socket has been closed. 
    def receive_and_process
      return unless @sock
      msg = recv(@sock)
      Kosmonaut.log("Worker/RECV : #{msg.join("\n").inspect}")
      dispatch(msg) && !@sock.eof?
    rescue Errno::EAGAIN, Errno::ECONNRESET, Errno::ECONNREFUSED, IOError => err
      Kosmonaut.log("Worker/DISCONNECTED: " + err.to_s)
      return false
    end

    # Internal: Sends heartbeat message to the server and updates
    # heartbeat schedule.
    def heartbeat
      return unless @sock
      send(@sock, ["HB"])
      @heartbeat_at = Time.now.to_f + (@heartbeat_ivl.to_f / 1000.0)
    end

    # Internal: Dispatches the incoming message.
    #
    # msg - A message to be dispatched.
    #
    # Returns false if server sent a quit message.
    def dispatch(msg)
      cmd = msg.shift

      case cmd
      when "HB"
        # nothing to do...
      when "QT", nil
        return false
      when "TR"
        message_handler(msg[0])
      when "ER"
        error_handler(msg.size < 1 ? 597 : msg[0])
      end

      true
    end

    # Internal: Packs given payload and writes it to the specified socket.
    #
    # sock          - The socket to write to.
    # payload       - The payload to be packed and sent.
    # with_identity - Whether identity should be prepend to the packet.
    #
    # Returns always nil
    def send(sock, payload, with_identity=false)
      return unless sock
      packet = pack(payload, with_identity)
      sock.write(packet)
      Kosmonaut.log("Worker/SENT : #{packet.inspect}")
      nil
    rescue Errno::EPIPE
    end
    
    # Internal: Disconnects and cleans up the socket if connected.
    #
    # Returns always true. 
    def disconnect
      if @sock
        @sock.send(@sock, ["QT"]) rescue nil
        @sock.close
      end
    rescue IOError
      # nothing to do...
    ensure
      @sock = nil
      return true
    end

    # Internal: Sets up new connection with the backend endpoint and sends
    # information that it's ready to work. Also initializes heartbeat 
    # scheduling.
    #
    # wait - If true, then it will wait before the reconnect try
    #
    def reconnect(wait=false)
      disconnect
      sleep(@reconnect_delay.to_f / 1000.0) if wait
      @sock = connect(((@heartbeat_ivl * 2).to_f / 1000.0).to_i + 1)
      send(@sock, ["RD"], true)
      @heartbeat_at = Time.now.to_f + (@heartbeat_ivl.to_f / 1000.0)
    rescue Errno::ECONNREFUSED
    end

    # Intenral: Message handler routes received data to user defined
    # 'on_message' method (if exists) and handles it's exceptions.
    #
    # data - The data to be handled.
    #
    def message_handler(data)
      if respond_to?(:on_message)
        payload = JSON.parse(data.to_s)
        on_message(*payload.first)
      end
    rescue => err
      exception_handler(err)
    end

    # Internal: Handles given WebRocket error.
    #
    # errcode - A code of the received error.
    # 
    # Raises Kosmonaut::UnauthorizerError if error 402 has been received.
    def error_handler(errcode)
      if respond_to?(:on_error)
        err = ERRORS[errcode.to_i]
        if err == UnauthorizedError
          raise err.new
        end
        begin
          on_error((err ? err : UnknownServerError).new)
        rescue => err
          exception_handler(err)
        end
      end
    end

    # Internal: Exception handler passes given error to user defined
    # exception handler or raises error if such not exists.
    #
    # err - The exception to be handled.
    #
    def exception_handler(err)
      if respond_to?(:on_exception)
        on_exception(err)
      else
        raise err
      end
    end
  end
end
