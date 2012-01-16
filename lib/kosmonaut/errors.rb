module Kosmonaut
  class Error < StandardError
  end

  class BadRequestError < Error
    def initialize
      super "400: Bad request"
    end
  end

  class UnauthorizedError < Error
    def initialize
      super "402: Unauthorized"
    end
  end

  class ForbiddenError < Error
    def initialize
      super "403: Forbidden"
    end
  end

  class InvalidChannelNameError < Error
    def initialize
      super "451: Invalid channel name"
    end
  end

  class ChannelNotFoundError < Error
    def initialize
      super "454: Channel not found"
    end
  end

  class InternalError < Error
    def initialize
      super "597: Internal error"
    end
  end

  class EndOfFileError < Error
    def initialize
      super "598: End of file"
    end
  end

  class UnknownServerError < Error
    def initialize
      super "Unknown server error"
    end
  end

  ERRORS = {
    400 => BadRequestError,
    402 => UnauthorizedError,
    403 => ForbiddenError,
    451 => InvalidChannelNameError,
    454 => ChannelNotFoundError,
    597 => InternalError,
    598 => EndOfFileError,
  }
end
