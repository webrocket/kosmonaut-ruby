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
  module Version
    MAJOR = 0
    MINOR = 4
    PATCH = 0

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end

  def self.version
    Version.to_s
  end
end
