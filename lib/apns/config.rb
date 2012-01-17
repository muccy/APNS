module APNS
  class Config
    @development_mode = true
    
    # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
    @pem  = nil # this should be the path of the pem file not the content's
    @pass = nil
    @log_to_file = true

    class << self
      attr_accessor :development_mode, :pem, :pass, :log_to_file
    end
  end
end