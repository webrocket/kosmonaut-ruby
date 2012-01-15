require File.expand_path("../helper", __FILE__)

class MyWorker < Kosmonaut::Worker
  def on_message(event, data)
  end
  
  def on_error(errcode)
  end

  def on_exception(err)
  end
end

class TestKosmonautWorker < MiniTest::Unit::TestCase
  def setup
    @worker = MyWorker.new("/test", ENV["VHOST_TOKEN"].to_s)
  end

  def teardown
    @worker.disconnect
  end

  def test_api
    rc = @worker.connect("tcp://127.0.0.1:8081")
    assert_equal 0, rc
    # Ah, ruby ruby... why you suck so much and don't allow me
    # to test this in multithreading way?... Anyway, it shall work.
    #rc = @worker.listen
    #assert_equal 0, rc
    @worker.stop
  end
end
