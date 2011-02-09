module APNS
  class ApnsLogger
    APP_NAME = "APNS"
    LOGGER_INSTANCE = Logger.new(STDOUT)
    LOGGER_INSTANCE.level = Logger::DEBUG
    APNS_LOGGER_INSTANCE = ApnsLogger.new

    def self.log
      APNS_LOGGER_INSTANCE
    end

    def method_missing(m, *args, &block)
	    LOGGER_INSTANCE.send(m, APP_NAME) {args[0]}
	  end

  end
end