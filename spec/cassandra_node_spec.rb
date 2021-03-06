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
EXPECTED_PORT = 5041
EXPECTED_HOST = "localhost"

def provision
  @default_plan = "free"
  @node.provision(@default_plan)
end

def unprovision
  @node.unprovision(@echoer["name"])
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
    @echoer["port"].should be EXPECTED_PORT

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
      `ps #{pid}`.include?("bin/cassandra").should be_true
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
    unprovision
  end

  it "should not provision more than cassandra_instance_limit" do

    #Setting limit 1 ensures that the limit is maxed out
    begin
      @node.instance_variable_set(:@instance_limit, 1)
      expect { provision }.to raise_error("The Cassandra instance limit (1) has been exhausted for the host localhost")
    ensure
      @node.instance_variable_set(:@instance_limit, 10)
    end

  end

  it "should decrement by a value of 1 the current provision count if a node is unprovisioned" do
    #Setting limit 1 ensures that the limit is maxed out
    begin
      @node.instance_variable_set(:@instance_limit, 2)
      cass_instance = provision
      expect { provision }.to raise_error("The Cassandra instance limit (2) has been exhausted for the host localhost")
      @node.unprovision(cass_instance['name'])
      expect { provision }.to_not raise_error
      expect { provision }.to raise_error("The Cassandra instance limit (2) has been exhausted for the host localhost")
    ensure
      @node.instance_variable_set(:@instance_limit, 10)
    end
  end

  it "should provision a new Cassandra service with correct credential" do
    EM.run do
      @echoer.should be_instance_of Hash
      @echoer["port"].should be EXPECTED_PORT
      @echoer["host"].should eq(EXPECTED_HOST)
      EM.stop
    end
  end

  it "should create a credential when binding" do
    EM.run do
      binding = @node.bind(@echoer["name"], @default_opts)
      binding["port"].should be EXPECTED_PORT
      binding["host"].should eq(EXPECTED_HOST)
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

  it "should delete credential after unbinding" do
    EM.run do
      binding = @node.bind(@echoer["name"], @default_opts)
      @node.unbind(binding)
      EM.stop
    end
  end

end
