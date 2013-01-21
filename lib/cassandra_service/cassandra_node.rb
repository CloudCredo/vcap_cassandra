# Copyright (c) 2012 CloudCredo Ltd.
require "fileutils"
require "logger"
require "datamapper"
require "uuidtools"
require "set"
require 'vcap/common'


module VCAP
  module Services
    module Cassandra
      class Node < VCAP::Services::Base::Node
      end
    end
  end
end

require "cassandra_service/cassandra_conf"
require "cassandra_service/free_port_locator"
require "cassandra_service/common"
require "cassandra_service/cassandra_error"

class VCAP::Services::Cassandra::Node

  include VCAP::Services::Cassandra::Common

  #The object that is persisted into the service.db (usually /var/vcap/services/{service-name}.db)
  #If you wish to save instance related data such as ports and hosts this is the object that will
  #persist the data for you.
  class ProvisionedService

    include DataMapper::Resource

    property :name, String, :key => true
    property :jmx_port, Integer
    property :storage_port, Integer
    property :ssl_storage_port, Integer
    property :rpc_port, Integer
    property :host, String
    property :hostname, String
    property :runtime_path, String, :length => 255
    property :pid, Integer
    property :user, String
    property :pword, String

    def kill(sig=:SIGTERM)
      @wait_thread = Process.detach(pid)
      Process.kill(sig, pid) if running?
    end

    def running?
      VCAP.process_running? pid
    end

  end

  def initialize(options)
    super(options)

    @instance_count = 0
    @instance_limit = options[:instance_limit]
    @runtime_path = options[:runtime_path]
    @local_db = options[:local_db]
    @port_range = options[:port_range]
    @ssl_port_range = options[:ssl_port_range]
    @jmx_port_range = options[:jmx_port_range]
    @rpc_port_range = options[:rpc_port_range]
    @host = options[:host]
    @base_dir = options[:base_dir]
    @supported_versions = options[:supported_versions]
    @user = ""
    @pword = ""
  end

  #TODO make this in to a module/mixin and import
  def get_free_port(port_range)
    FreePortLocator.new(@host, port_range.to_set).find_free_port
  end

  def pre_send_announcement
    super
    FileUtils.mkdir_p(@base_dir) if @base_dir
    start_db
    @capacity_lock.synchronize do
      ProvisionedService.all.each do |instance|
        @capacity -= capacity_unit
      end
    end
  end

  def announcement
    @capacity_lock.synchronize do
      {:available_capacity => @capacity,
       :capacity_unit => capacity_unit}
    end
  end

  def provision(plan, credential = nil, version=nil)

    @logger.debug("Using PLAN=#{plan}, CRED=#{credential}, VERSION=#{version}")

    if(@instance_count < @instance_limit)
      @instance_count += 1
    else
      raise "The Cassandra instance limit (#{@instance_limit}) has been exhausted for the host #{@host}"
    end

    instance = ProvisionedService.new
    instance.runtime_path = @runtime_path

    instance.storage_port = get_free_port(@port_range)
    instance.ssl_storage_port = get_free_port(@ssl_port_range)
    instance.jmx_port = get_free_port(@jmx_port_range)
    instance.rpc_port = get_free_port(@rpc_port_range)

    @logger.debug("Found free storage port #{instance.storage_port}")

    instance.host = @host

    instance.name = credential ? credential["name"] : UUIDTools::UUID.random_create.to_s

    instance.user = UUIDTools::UUID.random_create.to_s
    instance.pword = UUIDTools::UUID.random_create.to_s

    @logger.debug("Created service with name '#{instance.name}'")

    begin
      generate_config(instance)
      start_cassandra(instance)
      write_pid_file(instance)
      save_instance(instance)
      @logger.info("#{instance.inspect} provisioned")
    rescue => e1
      @logger.error("Could not save instance: #{instance.name}, cleaning up. Exception: #{e1}")
      begin
        destroy_instance(instance)
      rescue => e2
        @logger.error("Could not clean up instance: #{instance.name}. Exception: #{e2}")
      end
      raise e1
    end

    gen_credential(instance)
  end

  def unprovision(name, credentials = [])
    return if name.nil?
    @logger.debug("Unprovision Cassandra service: #{name}")
    instance = get_instance(name)
    destroy_instance(instance)
    @instance_count -= 1
    true
  end

  def bind(name, binding_options, credential = nil)
    instance = nil
    if credential
      instance = get_instance(credential["name"])
    else
      instance = get_instance(name)
    end
    @logger.debug("Attempting to bind service: #{instance.inspect}")
    gen_credential(instance)
  end

  def unbind(credential)
    @logger.debug("Unbind service: #{credential.inspect}")
    true
  end

  def start_db
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, @local_db)
    DataMapper::auto_upgrade!
  end


  def generate_config(instance)
    CassandraConfigurator.new(@base_dir, instance).generate_config_dir
  end

  #Starts the instance of the Cassandra server by executing the :runtime_path property
  def start_cassandra(instance)

    @logger.info "Starting Cassandra Service #{instance.name}"

    pidfile = "#{get_config_dir(instance)}/pid"
    cmd = "#{@runtime_path} -f -p #{pidfile}"
    @logger.info "Executing #{cmd} with CASSANDRA_CONF=#{get_config_dir(instance)}"

    instance.pid=fork

    begin
      exec({"CF_USER" => instance.user, "CF_PASSWORD" => instance.pword, "CASSANDRA_CONF" => get_config_dir(instance)}, cmd) if instance.pid.nil?
    rescue => e
      @logger.error "exec #{cmd} failed #{e}"
    end
  end

  def write_pid_file(instance)
    File.open("#{get_config_dir(instance)}/pid", 'w') { |f| f.write(instance.pid) }
  end

  def save_instance(instance)
    @logger.debug("Attempting to save #{instance.inspect}")
    raise CassandraError.new(CassandraError::CASSANDRA_SAVE_INSTANCE_FAILED, instance.inspect) unless instance.save
    @logger.debug("#{instance.inspect} saved.")
  end

  def destroy_instance(instance)

    @logger.warn("About to kill #{instance.name}")
    instance.kill(:SIGKILL) if instance.running?
    FileUtils.rm_rf("#@base_dir/#{instance.name}")
    @logger.warn("#{instance.name} is now dead, and its configuration and data has been destroyed")

    raise CassandraError.new(CassandraError::CASSANDRA_DESTROY_INSTANCE_FAILED, instance.inspect) unless instance.destroy
  end

  def get_config_dir(instance)
    "#@base_dir/#{instance.name}/conf"
  end

  def get_instance(name)
    @logger.info("Looking for ProvisionedService with name: #{name}")
    instance = ProvisionedService.get(name)
    raise CassandraError.new(CassandraError::CASSANDRA_FIND_INSTANCE_FAILED, name) if instance.nil?
    instance
  end

  private
  def gen_credential(instance)
    credential = {
        "host" => instance.host,
        "port" => instance.rpc_port,
        "cluster_name" => instance.name,
        "name" => instance.name,
        "username" => instance.user,
        "password" => instance.pword
    }
  end
end
