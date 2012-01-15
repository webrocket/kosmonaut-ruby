require File.expand_path("../helper", __FILE__)

class TestKosmonautClient < MiniTest::Unit::TestCase
  def setup
    @client = Kosmonaut::Client.new("/test", ENV["VHOST_TOKEN"].to_s)
  end

  def teardown
    @client.disconnect
  end

  def test_api
    rc = @client.connect("tcp://127.0.0.1:8081")
    assert_equal 0, rc
    rc = @client.open_channel("foo", 0)
    assert_equal 0, rc
    rc = @client.broadcast("foo", "test", "{}")
    assert_equal 0, rc
    rc = @client.broadcast("bar", "test", "{}")
    assert_equal 454, rc
    rc = @client.close_channel("foo")
    assert_equal 0, rc
    rc = @client.close_channel("bar")
    assert_equal 454, rc
    token = @client.request_single_access_token(".*")
    assert token
    assert_equal 128, token.size
  end
end
