# Copyright (c) 2012 CloudCredo Ltd.

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'spec_helper'
require 'socket'
require 'set'


require 'cassandra_service/free_port_locator'

describe "The free port locator" do

  before :all do
    @range = (5000..5002).to_set
    @locator = FreePortLocator.new("localhost", @range)
  end

  it "should find the first free port in the range 5000-5002" do
    @locator.find_free_port.should be 5000
  end

  it "should find the first free port of 5001 in the range 5000-5002 when 5000 is already taken" do
    server = TCPServer.open(5000)
    @locator.find_free_port.should be 5001
    server.close
  end

  it "should raise an error when all of the ports in the range are taken" do
    servers = Set.new
    @range.each { |port|
      servers << TCPServer.open(port)
    }
    expect { @locator.find_free_port }.to raise_error "All of the ports in the provided range #{@range.inspect} are taken.
    Please reconfigure your service.yml port range or free up the expected ports"
    servers.each { |server| server.close }
  end

end
