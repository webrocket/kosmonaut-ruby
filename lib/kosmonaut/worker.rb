require 'json'

module Kosmonaut
  class Worker < C::Worker
    def _on_message(data)
      if respond_to?(:on_message)
        payload = JSON.parse(data)
        event = payload.keys.first
        data = data[event]
        on_message(event, data)
      end
    rescue => err
      _on_exception(err)
    end

    def _on_error(errcode)
      if respond_to?(:on_error)
        on_error(errcode.to_i)
      end
    rescue => err
      _on_exception(err)
    end

    def _on_exception(err)
      if respond_to?(:on_exception)
        on_exception(err)
      else
        raise err
      end
    end
  end
end
