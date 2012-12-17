# Copyright (c) 2009-2011 VMware, Inc.
require 'cassandra_service/common'

class VCAP::Services::Cassandra::Provisioner < VCAP::Services::Base::Provisioner

  include VCAP::Services::Cassandra::Common

end
