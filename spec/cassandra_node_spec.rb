# Copyright (c) 2012 CloudCredo Ltd.
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module VCAP
  module Services
    module Cassandra
      class CassandraError
        attr_reader :error_code
      end
    end
  end
end

#This is the first RPC port picked out of the range.
expected_port = 5041
expected_host = "localhost"

def provision
  @default_plan = "free"
  @node.provision(@default_plan)
end

describe "Cassandra process control" do

  before :all do
    @opts = get_node_test_config
    @opts.freeze
    @logger = @opts[:logger]
    # Setup code must be wrapped in EM.run
    EM.run do
      @node = Node.new(@opts)
      EM.add_timer(1) { EM.stop }
    end
  end

  before :each do

    #Required as the unit will persist the values, if they were stubbed values tests would fail with IntegrityError's
    #(Could consider cleaning up the db on after)
    user_name = UUIDTools::UUID.random_create.to_s
    password = UUIDTools::UUID.random_create.to_s
    name = UUIDTools::UUID.random_create.to_s

    UUIDTools::UUID.should_receive(:random_create).and_return name
    UUIDTools::UUID.should_receive(:random_create).and_return user_name
    UUIDTools::UUID.should_receive(:random_create).and_return password

    @echoer = provision
    @echoer['host'].should eq "localhost"
    @echoer['hostname'].should eq "localhost"

    @echoer['name'].should eq name
    @echoer['username'].should eq user_name
    @echoer['password'].should eq password

  end

  it "should remove the cassandra service dir on unprovision" do
    File.exist?("/tmp/vcap/cassandra/#{@echoer["name"]}").should be_true

    @node.unprovision(@echoer["name"])

    File.exist?("/tmp/vcap/cassandra/#{@echoer["name"]}").should be_false
  end

  it "should start new Cassandra instance" do
    @echoer["port"].should be expected_port

    pid_file = "/tmp/vcap/cassandra/#{@echoer["name"]}/conf/pid"

    puts "Checking pid file #{pid_file}"
    begin
      process_in_pid_file_running(pid_file).should be_true
    ensure
      @node.unprovision(@echoer["name"])
    end
  end

  def process_in_pid_file_running(pid_file)
    begin
      pid = File.read(pid_file)
      Process.getpgid(Integer(pid))
      true
    rescue Errno::ESRCH
      false
    end
  end

end

describe "Cassandra service node" do

  before :all do
    @opts = get_node_test_config
    @opts.freeze
    @logger = @opts[:logger]
    # Setup code must be wrapped in EM.run
    EM.run do
      @node = Node.new(@opts)
      EM.add_timer(1) { EM.stop }
    end
  end

  before :each do
    @echoer = provision
    @echoer.should_not == nil
  end

  after :each do
    @node.unprovision(@echoer["name"])
  end

  it "should provison a cassandra service with correct credential" do
    EM.run do
      @echoer.should be_instance_of Hash
      @echoer["port"].should be expected_port
      @echoer["host"].should eq(expected_host)
      EM.stop
    end
  end

  it "should create a crediential when binding" do
    EM.run do
      binding = @node.bind(@echoer["name"], @default_opts)
      binding["port"].should be expected_port
      binding["host"].should eq(expected_host)
      EM.stop
    end
  end

  it "should supply different credentials when binding invoked with the same input" do
    EM.run do
      binding1 = @node.bind(@echoer["name"], @default_opts)
      binding2 = @node.bind(@echoer["name"], @default_opts)
      binding1.should_not be binding2
      EM.stop
    end
  end

  it "should delete crediential after unbinding" do
    EM.run do
      binding = @node.bind(@echoer["name"], @default_opts)
      @node.unbind(binding)
      EM.stop
    end
  end

  #TODO, delete the directory on service unprovision.
  #maybe do a clean up based on the database?
  #Re-attach control of existing processes, check if they are running using the method ..


end
