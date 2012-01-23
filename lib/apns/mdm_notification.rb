module APNS
  class MdmNotification
    attr_accessor :device_token, :push_magic

    def initialize(device_token, push_magic)
      self.device_token = device_token
      self.push_magic = push_magic
    end

    def packaged_notification id
      pm = self.packaged_message
      [1, id, 0, 32, self.device_token, pm.size, pm].pack("cNNnH*na*")
    end

    def packaged_message
      message = {'mdm'=> self.push_magic}
      message.to_json
    end
  end
end
