# Copyright (C) 2012 Krzysztof Kowalik <chris@nu7hat.ch> and folks at Cubox
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'logger'
require 'active_support/inflector'
require 'kosmonaut/worker'

module Kosmonaut
  # Public: Application is a default worker implementation, which provides
  # simple and conventional way to use multiple, routed handlers.
  #
  # Example:
  #
  #   class ChatBackend
  #     def save_to_history(msg)
  #       room = Room.find(msg[:room])
  #       room.history.append(msg)
  #     end
  #   end
  #
  #   Kosmonaut::Application.build "wr://token@127.0.0.1:8081/vhost" do
  #     use ChatBackend, :as => "chat"
  #     run
  #   end
  #
  class Application < Worker
    # Public: Configured logger.
    attr_accessor :logger

    # Public: Syntactic sugar for the constructor.
    #
    # url - The WebRocket backend endpoint URL to connect to.
    #
    def self.build(url, &block)
      new(url, &block)
    end

    # Internal: Constructor, executes given block within its instance.
    #
    # url - The WebRocket backend endpoint URL to connect to.
    #
    def initialize(url, &block)
      super(url)
      @handlers = {}
      instance_eval(&block)
    end
    
    # Internal: Logger property reader.
    #
    # Returns configured logger.
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    # Public: Registers new backend handler within the application.
    #
    # backend - The class to be registered.
    # options - The Hash options (default: {}):
    #           :as - A name used to register klass under (default: underscored
    #                 class name)
    # 
    # Example:
    #
    #   Kosmonaut::Application.use do
    #     use ChatBackend, :as => "chat"
    #     run
    #   end
    #
    def use(backend, options={})
      handle = options[:as] || backend.to_s.underscore
      @handlers[handle] = backend.new
    end

    # Internal: Message dispatcher.
    #
    # message - The Message to be dispatched.
    #
    def on_message(message)
      search_for = message.event.split("/")
      raise InvalidBackendEvent(message.event) if search_for.size < 2
      klass = @handlers[search_for[0]] and handler = klass.method(search_for[1])
      raise UndefinedHandler.new(message.event) unless handler
      logger.info("#{message.event}, #{message.inspect}")
      handler.call(message)
    end

    # Internal: Default error handler.
    #
    # err - The Error to be handled.
    #
    def on_error(err)
      logger.error(err.to_s)
    end

    # Internal: Default exception handler.
    #
    # err - The Error to be handled.
    #
    def on_exception(err)
      logger.fatal(err.to_s)
    end
  end
end
