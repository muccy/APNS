module APNS
  class ApnsErrorCodeHandler

    # Get the APNS error information in a hash
    def self.get_apns_error data
      raw_error = data.unpack("ccN")

      # return the map
      {
          :notification_id => raw_error[2],
          :error => {
              :type => raw_error[0],
              :code => raw_error[1],
              :description => self.decode_apns_error_code(raw_error[1])
          }
      }
    end

    # APNS error codes from:
    #   http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html
    APNS_ERROR_CODES = {
        0   => "No errors encountered",
        1   => "Processing error",
        2   => "Missing device token",
        3   => "Missing topic",
        4   => "Missing payload",
        5   => "Invalid token size",
        6   => "Invalid topic size",
        7   => "Invalid payload size",
        8   => "Invalid token",
        255 => "None (unknown)"
    }

    # Decode the given error code using the APNS_ERROR_CODES map.
    # If decoding fails return "Error description not found(!).",
    # however that should not happen!
    def self.decode_apns_error_code error_code
      if error_description = APNS::ApnsErrorCodeHandler::APNS_ERROR_CODES[error_code]
        error_description
      else
        "Error description not found(!)."
      end
    end

  end
end