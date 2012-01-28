# Copyright (C) 2012 Krzysztof Kowalik <chris@nu7hat.ch> and folks at Cubox
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
 
require 'kosmonaut/errors'
require 'kosmonaut/socket'
require 'kosmonaut/worker'
require 'kosmonaut/client'
require 'kosmonaut/version'

module Kosmonaut
  extend self
  
  # Public: The debug mode switch. If true, then debug messages will
  # be printed out. 
  attr_accessor :debug

  # Internal: Simple logging method used to display debug information
  #
  # msg - The debug message to be displayed
  #
  def log(msg)
    print("DEBUG: ", msg, "\n") if Kosmonaut.debug
  end
end

Kosmonaut.debug = false
