module Systemd
  class UnsupportedFeatureError < StandardError
    def initialize(feature)
      super("#{feature} is not supported by the underlying version of libsystemd.")
    end
  end
end
