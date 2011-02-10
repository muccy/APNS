require File.dirname(__FILE__) + '/../spec_helper'

describe APNS::NotificationSender do

  describe "#send_notification" do
    it "should send a notification when there are no APNS errors" do

      sock = double()
      sock.stub(:close)

      ssl = double()
      ssl.stub(:write)
      ssl.stub(:close)

      error_code_handler = double()
      error_code_handler.stub(:get_error_if_present) { nil } # no error scenario

      connection_provider = double()
      connection_provider.stub(:open_connection) { [sock, ssl] }

      ssl.should_receive(:write).once
      error_code_handler.should_receive(:get_error_if_present).once.with(ssl)
      ssl.should_receive(:close).once
      sock.should_receive(:close).once

      result =APNS::NotificationSender.send_notification("device_token",
                                                         {
                                                             :alert => "alert",
                                                             :badge => 3,
                                                             :sound => "sound",
                                                             :other => {:type => "type"}
                                                         },
                                                         connection_provider,
                                                         error_code_handler
      )

      result.should == nil
    end

    it "should send a notification and report errors when there are APNS errors" do

      sock = double()
      sock.stub(:close)

      ssl = double()
      ssl.stub(:write)
      ssl.stub(:close)

      error_code_handler = double()
      error_code_handler.stub(:get_error_if_present) { "example error" } # error scenario

      connection_provider = double()
      connection_provider.stub(:open_connection) { [sock, ssl] }

      ssl.should_receive(:write).once
      error_code_handler.should_receive(:get_error_if_present).once.with(ssl)
      ssl.should_receive(:close).once
      sock.should_receive(:close).once

      result =APNS::NotificationSender.send_notification("device_token",
                                                         {
                                                             :alert => "alert",
                                                             :badge => 3,
                                                             :sound => "sound",
                                                             :other => {:type => "type"}
                                                         },
                                                         connection_provider,
                                                         error_code_handler
      )

      result.should == "example error"
    end

    it "should send a notification and return any raised exception when there is a unexpected exception" do

      sock = double()
      sock.stub(:close)

      ssl            = double()
      test_exception = Exception.new
      ssl.stub(:write) { raise test_exception }
      ssl.stub(:close)

      error_code_handler  = double()

      connection_provider = double()
      connection_provider.stub(:open_connection) { [sock, ssl] }

      ssl.should_receive(:write).once
      ssl.should_receive(:close).once
      sock.should_receive(:close).once

      result =APNS::NotificationSender.send_notification("device_token",
                                                         {
                                                             :alert => "alert",
                                                             :badge => 3,
                                                             :sound => "sound",
                                                             :other => {:type => "type"}
                                                         },
                                                         connection_provider,
                                                         error_code_handler
      )

      result.should == test_exception
    end
  end

  describe "#send_notifications" do
    it "should send notifications and report no errors when there are no APNS errors" do
      n1                = double()
      n2                = double()
      n3                = double()
      n4                = double()
      n5                = double()

      n1.should_receive(:packaged_notification).with(0)
      n2.should_receive(:packaged_notification).with(1)
      n3.should_receive(:packaged_notification).with(2)
      n4.should_receive(:packaged_notification).with(3)
      n5.should_receive(:packaged_notification).with(4)
      notifications_array = [n1, n2, n3, n4, n5]

      # no errors scenario
      APNS::NotificationSender.should_receive(:continue_notification_sending?){ false }.once

      sock = double()
      ssl = double()

      connection_provider = double()
      connection_provider.stub(:open_connection) { [sock, ssl] }
      
      ssl.should_receive(:write).exactly(5).times
      ssl.should_receive(:close).once
      sock.should_receive(:close).once

      result =APNS::NotificationSender.send_notifications(notifications_array, connection_provider)

      result.should == [] # empty array / no errors
    end
  end

  describe "#continue_notification_sending?" do
    it "should not continue when there are no errors" do
      logger             = double()
      ssl                = double()

      error_code_handler = double()
      error_code_handler.should_receive(:get_error_if_present) { nil }.with(ssl).once
      result =APNS::NotificationSender.continue_notification_sending?(
          {}, ssl, [],
          error_code_handler,
          logger
      )

      result.should == false
    end

    it "should continue and return appropriate errors when there are errors
and the errors are not for the last
notification in the notification array" do
      logger             = double()
      logger.should_receive(:warn).twice

      ssl                = double()

      n1                = double()
      n2                = double()

      n1.stub(:device_token) { "token_one" }
      n2.stub(:device_token) { "token_two" }
      notifications_array = [n1, n2]

      state = {}
      state[:failures] = []

      sample_error_map =
      {
          :notification_id => 0,
          :error           => {
              :type        => 8,
              :code        => 7,
              :description => "Invalid Payload Size"
          }
      }

      error_code_handler = double()
      error_code_handler.should_receive(:get_error_if_present) { sample_error_map }.with(ssl).once
      result =APNS::NotificationSender.continue_notification_sending?(
          state, ssl, notifications_array,
          error_code_handler,
          logger
      )

      result.should == true

      state[:failures].count.should == 1
      state[:failures][0][:token].should == "token_one"
      state[:failures][0][:error].should == sample_error_map

      state[:start_point] = 1
    end
  end
end