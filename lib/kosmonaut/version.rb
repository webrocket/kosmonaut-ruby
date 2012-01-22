module Kosmonaut
  module Version
    MAJOR = 0
    MINOR = 2
    PATCH = 4

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end

  def self.version
    Version.to_s
  end
end
