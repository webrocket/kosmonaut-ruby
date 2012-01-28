# Copyright (C) 2012 Krzysztof Kowalik <chris@nu7hat.ch> and folks at Cubox
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
 
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
