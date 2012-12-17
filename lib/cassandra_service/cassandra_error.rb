# Copyright (c) 2009-2011 VMware, Inc.
module VCAP
  module Services
    module Cassandra
      class CassandraError < VCAP::Services::Base::Error::ServiceError
        CASSANDRA_SAVE_INSTANCE_FAILED        = [32100, HTTP_INTERNAL, "Could not save instance: %s"]
        CASSANDRA_DESTORY_INSTANCE_FAILED     = [32101, HTTP_INTERNAL, "Could not destroy instance: %s"]
        CASSANDRA_FIND_INSTANCE_FAILED        = [32102, HTTP_NOT_FOUND, "Could not find instance: %s"]
        CASSANDRA_START_INSTANCE_FAILED       = [32103, HTTP_INTERNAL, "Could not start instance: %s"]
        CASSANDRA_STOP_INSTANCE_FAILED        = [32104, HTTP_INTERNAL, "Could not stop instance: %s"]
        CASSANDRA_INVALID_PLAN                = [32105, HTTP_INTERNAL, "Invalid plan: %s"]
        CASSANDRA_CLEANUP_INSTANCE_FAILED     = [32106, HTTP_INTERNAL, "Could not cleanup instance, the reasons: %s"]
      end
    end
  end
end
