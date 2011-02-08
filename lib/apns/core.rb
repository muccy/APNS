module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem  = nil # this should be the path of the pem file not the content's
  @pass = nil

  class << self
    attr_accessor :host, :pem, :port, :pass
  end

  def self.send_notification(device_token, message)
    begin
      sock, ssl = self.open_connection
      ssl.write(APNS::Notification.new(device_token, message).packaged_notification(0))
      error = APNS::ApnsErrorCodeHandler.get_error_if_present ssl
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
        # try to get the error message sent by the APNS. This should be present if the connection was
        # dropped by the APNS because of a error in a sent notification.
        if !self.continue_notification_sending?(state, ssl, notifications)
          break #if APNS didn't sent a error, we don't know what notifications got sent and what didn't. Just give up.
        end
      rescue Exception => exception # whatever other errors goes here
        break #this is a unexpected situation. We don't know what notifications got sent and what didn't. so just giveup.
      ensure # make sure we close the connections whatever happens
        ssl.close
        sock.close
      end
    end

    state[:failures]
  end

  def self.feedback
    sock, ssl = self.feedback_connection

    apns_feedback = []

    while line = sock.gets # Read lines from the socket
      line.strip!
      f = line.unpack('N1n1H140')
      apns_feedback << [Time.at(f[0]), f[2]]
    end

    ssl.close
    sock.close

    return apns_feedback
  end

  protected

  def self.open_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock, context)
    ssl.connect

    return sock, ssl
  end

  def self.feedback_connection
    raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless self.pem
    raise "The path to your pem file does not exist!" unless File.exist?(self.pem)

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
    context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)

    fhost        = self.host.gsub!('gateway', 'feedback')
    puts fhost

    sock = TCPSocket.new(fhost, 2196)
    ssl  = OpenSSL::SSL::SSLSocket.new(sock, context)
    ssl.connect

    return sock, ssl
  end
end
