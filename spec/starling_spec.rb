$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require 'fileutils'
require 'memcache'
require 'digest/md5'
require 'starling'

require 'starling/server'

def safely_fork(&block)
  # anti-race juice:
  blocking = true
  Signal.trap("USR1") { blocking = false }

  pid = Process.fork(&block)

  while blocking
    sleep 0.1
  end

  pid
end

describe "add priorities to the queueing system." do
  before :all do
    @tmp_path = File.join(File.dirname(__FILE__), "tmp")

    begin
      Dir::mkdir(@tmp_path)
    rescue Errno::EEXIST
    end

    @server_pid = safely_fork do
      server = StarlingServer::Base.new(:host => '127.0.0.1',
      :port => 22133,
      :path => @tmp_path,
      :logger => Logger.new(STDERR),
      :log_level => Logger::FATAL)
      Signal.trap("INT") {
        server.stop
        exit
      }

      Process.kill("USR1", Process.ppid)
      server.run
    end


    @starling_client = Starling.new('127.0.0.1:22133')
    
  end  

  describe "insert_with_priority should put an item in the queue named based on the :priority value" do 
    # must get a copy of the queue, perform the operation, and verify the expected output
    it "should have a client. " do
      @starling_client.sizeof(:all).size.should eql(0)  
    end

    it "should insert a new item in the queue at the right place."  do
      @starling_client.set_at(0, 'spec-queue','testvalue')
      @starling_client.get_from(0,'spec-queue').should eql('testvalue')
      # @starling_client.set('spec-queue','testvalue')
      # @starling_client.get('spec-queue').should eql('testvalue')
      
    end
    

  end

end