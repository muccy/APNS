require File.dirname(__FILE__) + '/../spec_helper'

describe APNS::ApnsErrorCodeHandler do

  describe "get_error_if_present" do
    it "retrieve an error if one is present in the connection" do

      error_code_handler = APNS::ApnsErrorCodeHandler
      error_code_handler.should_receive(:connection_have_output?){ true }.once

      error_code_handler.should_receive(:get_apns_error){ "example_error" }.once

      ssl = double()
      ssl.should_receive(:read).once

      result = error_code_handler.get_error_if_present ssl
      result.should == "example_error"
    end
  end

  describe "connection_have_output?" do
    it "should return true when the connection have output" do
      connection = double()
      Kernel.should_receive(:select){ ["sample_error", nil, nil] }

      result = APNS::ApnsErrorCodeHandler.connection_have_output? connection
      result.should == true
    end

    it "should return false when the connection doesn't have output" do
      connection = double()
      Kernel.should_receive(:select){ [nil, nil, nil] }

      result = APNS::ApnsErrorCodeHandler.connection_have_output? connection
      result.should == false
    end
  end
end