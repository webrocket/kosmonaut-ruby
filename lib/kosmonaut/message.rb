# Copyright (C) 2012 Krzysztof Kowalik <chris@nu7hat.ch> and folks at Cubox
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'hashie'

module Kosmonaut
  # Public: Message is an unified wrapper for the incoming events.
  #
  # Example:
  #
  #   class ChatBackend
  #     def save_to_history_and_broadcast(msg)
  #       room = Room.find(msg.room)
  #       room.history.append(msg)
  #       msg.broadcast_copy("presence-#{room.name}")
  #     end
  #   end
  #
  class Message < Hashie::Mash
    # Public: The name of the event.
    attr_reader :event

    # Internal: Constructor, creates new message.
    #
    # event  - The String event name.
    # data   - The Hash message payload.
    # worker - The Worker which received the message.
    #
    def new(event, data, worker=nil)
      @event = event
      @client = Client.new(worker.url) if worker
      super(data)
    end

    # Public: Broadcasts reply to the message on the specified channel.
    #
    # channel - The String channel name to broadcast to.
    # event   - The String event name to be broadcasted.
    # data    - The Hash payload. 
    #
    # Example:
    #
    #   def hello(msg)
    #     msg.broadcast_reply("private-#{msg.author}", "hello", {
    #       :greeting => "Hi, how are you #{msg.author_full_name}"
    #     })
    #   end
    #
    def broadcast_reply(channel, event, data={})
      @client.broadcast(channel, event, data)
    end

    # Public: Broadcasts copy of the message on the specified channel.
    #
    # channel - The String channel name to broadcast to.
    #
    # Example:
    #
    #   def save_to_history_and_broadcast(msg)
    #     room = Room.find(msg.room)
    #     room.history.append(msg)
    #     msg.broadcast_copy("presence-#{room.name}")
    #   end
    #
    def broadcast_copy(channel)
      broadcast_reply(channel, self.event, self.to_hash)
    end

    # Public: Sends direct reply to the message sender.
    #
    # event   - The String event name to be broadcasted.
    # data    - The Hash payload. 
    #
    # NOTE: This method is not implemented yet.
    def direct_reply(event, data)
      raise NotImplementedError.new("Kosmonaut::Message#direct_reply is not implemented yet")
    end
  end
end
