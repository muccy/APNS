module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  def self.send_notification(device_token, message)
    begin
      sock, ssl = self.open_connection
      ssl.write(APNS::Notification.new(device_token, message).packaged_notification(0))
      error = APNS::ApnsErrorCodeHandler.get_error_if_present ssl
    rescue Exception => ex
      APNS::ApnsLogger.log.fatal "Exception in send_notification. device_token: #{device_token} message: #{message}"
      APNS::ApnsLogger.log.fatal(error = ex)
    ensure
      ssl.close
      sock.close
    end
    error
  end

  # Checks whether the APNS have sent any error messages through the connection. If any errors are present,
  # edit the state map, as necessary so that notification sending can be started from the point after the failed
  # notification. (the number of notifications is taken to consideration as well. so if the last notification that was
  # sent have failed, this method would return false, as there are no notifications left for the notification sending
  # process to continue.
  #
  # Send true if the notification sending process should continue (manning errors were found). Send false if
  # the notification process should not continue (meaning that no errors were found).
  def self.continue_notification_sending? state, ssl, notifications
    if error = APNS::ApnsErrorCodeHandler.get_error_if_present(ssl)
      APNS::ApnsLogger.log.warn "Error detected in continue_notification_sending?"
      APNS::ApnsLogger.log.warn error
      # record the failure to send this notification, that failed
      state[:failures] << {
          :token => notifications[error[:notification_id]],
          :error => error
      }
      # start from the next notification in the array/queue
      state[:start_point] = (error[:notification_id] + 1) #+1 because you want to start from the next notification
      #note: the notifications array AND notification_id is 0 index based.

      # if the failure was at the last notification. There is no point continuing send_notifications as there are no
      # more notifications left in the queue
      return state[:start_point] < notifications.size
    else

      # if the execution came up to this point, we can assume that the for loop above executed without any errors.
      # thus, all notifications that can be sent are sent. Signal send notifications to terminate the top most (one and only) while loop
      return false
    end
  end

  # send a batch of notifications. Uses the enhanced notification format. return a array with all errors encountered while
  # sending the given batch of notifications
  #
  # return array format
  # [{:token => 112894699s8d7f9sdf79s81237199, :error => {}},...]
  #
  # the :error contains a APNS::ApnsErrorCodeHandler.get_error_if_present returned map representing a APNS returned error
  def self.send_notifications notifications
    state = {
        :start_point => 0,
        :failures    => []
    }

    while true do
      begin
        # get the connection
        sock, ssl = self.open_connection

        # start sending notifications
        for i in state[:start_point]..(notifications.size - 1)
          ssl.write(notifications[i].packaged_notification(i))
          #sleep(1) #use this for testing the rescue Errno::EPIPE block. As when you only have a small number of notifications
          #the rescue block never gets executed as it takes a while for the APNS to send a error
          #through the pipe and disconnect you.
        end

        if !self.continue_notification_sending?(state, ssl, notifications)
          break
        end

      rescue Errno::EPIPE => epipe_exception # this is the classic error when APNS drops the connection...
        APNS::ApnsLogger.log.warn "EPIPE Exception in send_notifications"
        APNS::ApnsLogger.log.warn epipe_exception
        # try to get the error message sent by the APNS. This should be present if the connection was
        # dropped by the APNS because of a error in a sent notification.
        if !self.continue_notification_sending?(state, ssl, notifications)
          break #if APNS didn't sent a error, we don't know what notifications got sent and what didn't. Just give up.
        end
      rescue Exception => exception # whatever other errors goes here
        APNS::ApnsLogger.log.fatal "Exception in send_notifications"
        APNS::ApnsLogger.log.fatal exception
        break #this is a unexpected situation. We don't know what notifications got sent and what didn't. so just giveup.
      ensure # make sure we close the connections whatever happens
        ssl.close
        sock.close
      end
    end

    state[:failures]
  end

  protected

  def self.open_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless APNS::Config.pem
    raise "The path to your pem file does not exist!" unless File.exist?(APNS::Config.pem)

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(APNS::Config.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(APNS::Config.pem), APNS::Config.pass)

    sock         = TCPSocket.new(APNS::Config.host, APNS::Config.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
    ssl.connect

    return sock, ssl
  end


end
