require File.expand_path("../helper", __FILE__)

class MyWorker < Kosmonaut::Worker
  def on_message(event, data)
    puts "MSG", event, data
  end
  
  def on_error(err)
    puts "ERR", err.to_s
  end

  def on_exception(err)
    puts "EXC", err.to_s
  end
end

class TestKosmonautWorker < MiniTest::Unit::TestCase
  def setup
    @worker = MyWorker.new("wr://#{ENV["VHOST_TOKEN"].to_s}@127.0.0.1:8081/test")
  end

  def test_api
    Thread.new {
      sleep(10)
      @worker.stop
    }
    @worker.listen
  end
end
