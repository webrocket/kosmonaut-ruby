require 'json'

module Kosmonaut
  class Client < C::Client
    def broadcast(channel, event, data)
      super(channel, event, data.to_json)
    end
  end
end
