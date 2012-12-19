# Copyright (c) 2012 CloudCredo Ltd.
require 'cassandra_service/common'

class VCAP::Services::Cassandra::Provisioner < VCAP::Services::Base::Provisioner

  include VCAP::Services::Cassandra::Common

end
