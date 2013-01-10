# Copyright (c) 2012 CloudCredo Ltd.
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'yaml'

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

describe "Cassandra configuration" do

  before :each do
    @base_dir = "/tmp/vcap-cassandra-test"
    @svc = VCAP::Services::Cassandra::Node::ProvisionedService.new(
        :name=>"cassandra-1234",
        :jmx_port=>7766,
        :rpc_port=>7778,
        :storage_port=>7779,
        :ssl_storage_port=>7800,
        :host=>"node_host",
        :runtime_path=>"cassandra",
        :pid=>"12345")
    @configurator = CassandraConfigurator.new(@base_dir, @svc)
  end

  after :each do
    FileUtils.rm_rf @base_dir
  end

  it "should create the expected conf dir" do
    EM.run do
      @configurator.should be_instance_of CassandraConfigurator
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf").should be_true
      EM.stop
    end
  end

  it "should generate the cassandra.yaml" do
    EM.run do
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf/cassandra.yaml").should be_true
      config = YAML.load_file("#@base_dir/cassandra-1234/conf/cassandra.yaml")

      config["cluster_name"].should == @svc.name
      config["data_file_directories"].should == ["#@base_dir/cassandra-1234/data"]
      config["commitlog_directory"].should == "#@base_dir/cassandra-1234/commitlog"
      config["saved_caches_directory"].should == "#@base_dir/cassandra-1234/saved_caches"
      config["rpc_port"].should == @svc.rpc_port
      config["storage_port"].should == @svc.storage_port
      config["ssl_storage_port"].should == @svc.ssl_storage_port

      EM.stop
    end
  end
  it "should generate the cassandra.env" do
    EM.run do
      @configurator.should be_instance_of CassandraConfigurator
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf/cassandra-env.sh").should be_true
      File.read("#@base_dir/cassandra-1234/conf/cassandra-env.sh").should include "JMX_PORT=\"7766\""
      EM.stop
    end
  end
  it "should generate the rackdc.properties" do
    EM.run do
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf/cassandra-rackdc.properties").should be_true
      #currently no content changes in this file..
      EM.stop
    end
  end
  it "should generate the topology.properties" do
    EM.run do
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf/cassandra-topology.properties").should be_true
      #currently no content changes in this file..
      EM.stop
    end
  end
  it "should generate the commitlog_archiving.properties" do
    EM.run do
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf/commitlog_archiving.properties").should be_true
      #currently no content changes in this file..
      EM.stop
    end
  end
  it "should generate the log4j server" do
    EM.run do
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf/log4j-server.properties").should be_true
      File.read("#@base_dir/cassandra-1234/conf/log4j-server.properties").should include "log4j.appender.R.File=#@base_dir/cassandra-1234/system.log"
      EM.stop
    end
  end
  it "should generate the log4j tools" do
    EM.run do
      @configurator.generate_config_dir
      FileTest.exist?("#@base_dir/cassandra-1234/conf/log4j-tools.properties").should be_true
      #currently no content changes in this file..
      EM.stop
    end
  end
end
