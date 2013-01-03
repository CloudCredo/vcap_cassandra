# Copyright (c) 2012 CloudCredo Ltd.
require "fileutils"
require "logger"
require "erb"
require 'ostruct'

class CassandraConfigurator

  class RenderErb < OpenStruct
    def render(template)
      erb = ERB.new(File.read(File.expand_path("../../../resources/#{template}.erb", __FILE__)))
      erb.result(binding)
    end
  end

  def initialize(base_dir, instance, logger)
    @logger = logger
    @base_dir = base_dir
    @instance = instance
    @instance_dir = "#@base_dir/#{@instance.name}"
    @config_dir = "#@instance_dir/conf"

  end

  def generate_config_dir

    @logger.info "Creating directory #{@config_dir}"
    FileUtils.mkdir_p @config_dir
    @logger.info "Directory #{@config_dir} created"

    write_cassandra_env
    write_rackdc
    write_topology
    write_cassandra_yaml
    write_commitlog_archiving
    write_log4j_server
    write_log4j_tools

  end

  def write_cassandra_env
    write_config("cassandra-env.sh",
                 {:jmx_port=>@instance.jmx_port})
  end

  def write_rackdc
    write_config("cassandra-rackdc.properties",
                 {})

  end
  def write_topology
    write_config("cassandra-topology.properties",
                 {})

  end
  def write_cassandra_yaml
    write_config("cassandra.yaml",
                 {:cluster_name=>@instance.name,
                  :data_file_dir=>"#@instance_dir/data",
                  :commit_log_dir=>"#@instance_dir/commitlog",
                  :saved_caches_dir=>"#@instance_dir/saved_caches",
                  :storage_port=>@instance.storage_port,
                  :ssl_storage_port=>@instance.ssl_storage_port,
                  :rpc_port=>@instance.rpc_port})
  end
  def write_commitlog_archiving
    write_config("commitlog_archiving.properties",
                 {})

  end
  def write_log4j_server
    write_config("log4j-server.properties",
                 {:log_file=>"#@instance_dir/system.log"})

  end
  def write_log4j_tools
    write_config("log4j-tools.properties",
                 {})
  end

  def get_template(name)
    ERB.new(File.read(File.expand_path("../../../resources/#{name}", __FILE__)))
  end

  def write_config(templateName, bind)

    render = RenderErb.new(bind)
    config = render.render(templateName)

    config_path = File.join(@config_dir, templateName)

    FileUtils.rm_f(config_path)
    File.open(config_path, "w") {|f| f.write(config)}
  end

end
