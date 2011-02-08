module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem  = nil # this should be the path of the pem file not the contentes
  @pass = nil

  class << self
    attr_accessor :host, :pem, :port, :pass
  end

  # Check whether the given connection receives any data within 1 second. If it does return true
  def self.connection_have_output? connection
    readfds, writefds, exceptfds = select([connection], nil, nil, 1)
    !readfds.nil?
  end

  def self.send_notification(device_token, message)
    error = nil
    begin
      sock, ssl = self.open_connection
      #ssl.write(self.packaged_notification(device_token, message))
      ssl.write(APNS::Notification.new(device_token, message).packaged_notification(0))

      error = ssl.read.unpack("ccN") if APNS.connection_have_output? ssl

    ensure
      ssl.close
      sock.close
    end

    error
  end

  def self.send_notifications(notifications)
    begin
      sock, ssl = self.open_connection

      notifications.each do |n|
        ssl.write(n.packaged_notification(13423324))
      end

    rescue Errno::EPIPE => epipe_exception # this is the classic error when APNS drops the connection
    rescue Exception => exception # whatever other errors goes here

    ensure # make sure we close the connections whatever happens
      ssl.close
      sock.close
    end
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

#  def self.packaged_notification(device_token, message, id=924123)
#    pt = self.packaged_token(device_token)
#    pm = self.packaged_message(message)
#    #pm = "T3ST"
#    #[0, 0, 32, pt, 0, pm.size, pm].pack("ccca*cca*")
#    [1, id, 0, 32, device_token, pm.size, pm].pack("cNNnH*na*")
#    # command token-length token payload-size payload
#    # 0       0 - 32        pt   0 - pm.size  pm
#    # c       c    c        a*    c   c        a*
#    #[0, 0, 32, pt, 0, pm.size, pm].pack("ccca*cca*")
#
#    # command identifier expiry token-length token payload-length payload
#    # 1       50         0      0 - 32       pt    0 - pm.size    pm
#    # c       c          c      c - c        a*     c   c          a*
#    #[1, 50, 0, 0, 31, pt, 0, pm.size, pm].pack("cNNnca*cca*")
#  end

#  def self.packaged_token(device_token)
#    [device_token.gsub(/[\s|<|>]/,'')].pack('H*')
#  end
#
#  def self.packaged_message(message)
#    if message.is_a?(Hash)
#      apns_from_hash(message)
#    elsif message.is_a?(String)
#      '{"aps":{"alert":"'+ message + '"}}'
#    else
#      raise "Message needs to be either a hash or string"
#    end
#  end
#
#  def self.apns_from_hash(hash)
#    other = hash.delete(:other)
#    aps = {'aps'=> hash }
#    aps.merge!(other) if other
#    aps.to_json
#  end

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
