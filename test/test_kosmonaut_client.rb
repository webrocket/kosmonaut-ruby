require File.expand_path("../helper", __FILE__)

class TestKosmonautClient < MiniTest::Unit::TestCase
  def setup
    @client = Kosmonaut::Client.new("wr://#{ENV["VHOST_TOKEN"].to_s}@127.0.0.1:8081/test")
  end

  def test_api
    # tests depends each other, so we have to run it in
    # correct order...
    _test_open_channel
    _test_open_channel_with_invalid_name
    _test_broadcast
    _test_broadcast_to_not_existing_channel
    _test_close_channel
    _test_close_not_existing_channel
    _test_request_single_access_token
  end
  
  def _test_open_channel
    @client.open_channel("foo", 0)
  end

  def _test_open_channel_with_invalid_name
    @client.open_channel("%%%", 0)
    assert false
  rescue Kosmonaut::InvalidChannelNameError
  end

  def _test_broadcast
    @client.broadcast("foo", "test", {})
  end

  def _test_broadcast_to_not_existing_channel
    @client.broadcast("foobar", "test", {})
    assert false
  rescue Kosmonaut::ChannelNotFoundError
  end
  
  def _test_close_channel
    @client.close_channel("foo")
  end

  def _test_close_not_existing_channel
    @client.close_channel("bar")
    assert false
  rescue Kosmonaut::ChannelNotFoundError
  end

  def _test_request_single_access_token
    token = @client.request_single_access_token(".*")
    assert token
    assert_equal 128, token.size
  end
end
