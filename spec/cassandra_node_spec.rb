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

#The port defined in the ../config/cassandra_node.yml :port property
expected_port = 5000
expected_host = "localhost"
provisioned_service_name = "test-name"

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

  def provision
    @default_plan = "free"
    @node.provision(@default_plan)
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

  it "should throw exception if the runtime_path executable cannot be found and executed" do
     
  end

  it "should start new Cassandra instance" do
    pid = @echoer["pid"] #Process id of the service provisioned by the before statement
    pid.should_not be_nil
    @echoer["port"].should be expected_port

    new_service = provision
    new_pid =  new_service['pid'] #provision a new service instance
    new_pid.should_not be_nil
    #new_service['\'].should be expected_port+1

    pid.should_not == new_pid

    @node.unprovision(new_service['name'])
  end

end
