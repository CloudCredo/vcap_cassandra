CloudFoundry Cassandra Service
===============================

_Author: **Chris Hedley**_

This code represent the adapter layer between [Cassandra] [1] and [CloudFoundry] [2].


Adding a service.
-----------------

We have stuck as closely as possible to the Cloud Foundry conventions of adding a service. Currently we support the
addition fo the Cassandra support through BOSH and Chef.



Chef:
-----

The steps for adding Cassandra as a service using Chef as briefly described below, for the official documentation on adding services
to Cloud Foundry See [Adding a System Service to OSS Cloud Foundry] [3].
Chef.

1. Add 'cassandra_node' and 'cassandra_gateway' to the `components` hash located in the file
  `$CF_HOME/cloudfoundry/.deployments/devbox/config/vcap_components.json`

2. Add the Cassandra service token to the `builtin_services` hash found in the file
   `$CF_HOME/cloudfoundry/.deployments/devbox/config/cloud_controller.yml`. The cassandra token by default is
   'cassandra_token' and can be changed in ???? as decribed in step xxxx. The Cassandra built in service should look
   like:

                   builtin_services:
                       redis:
                         token: changeredistoken
                       mongodb:
                         token: changemongodbtoken
                       mysql:
                         token: changemysqltoken
                       cassandra:
                         token: cassandratoken

3. On the Service host add the line `File.expand_path("../../cassandra/config/cassandra_gateway.yml", __FILE__)` to the `default_configs`
hash found in the file `$CF_HOME/cloudfoundry/vcap/services/tools/misc/bin/nuke_service.rb`

4. Clone [vcap_cassandra] [4] into `$CF_HOME/cloudfoundry/vcap/services/`

5. Download and install a Cassandra distribution.  We have tested vcap_cassandra against [Datastax] [6] distribution
versions 1.1.6 and 1.1.7 which are available to download from the [Datastax community page] [7]. We reccommend that one
of these versions is used for CloudFoundry.

Where Cassandra is intalled is not too important as by default when provisioning a new service the cassandra_node will
look for the `cassandra` executable on the sytem path ($PATH). This value is configurable via the `runtime_path` property
in [vcap_cassandra/config/cassandra_node.yml] [5]. The property value can either remain as is in which case you must add
the Cassandra distributiion `bin` directory to the $PATH or it can configured to be an abolsute path pointing to the
`cassandra` executable of your installation.



Bosh:
-----

A Bosh installation has also been created that allows Cassandra to be seamlessly deployed in to a bosh deployed CloudFoundry
For more information on our Bosh deployment please email chris@cloudcredo.com and we will point you in the right direction.

Copyright 2012 - CloudCredo Ltd.

[1]: http://cassandra.apache.org                                                        "Cassandra"
[2]: http://www.cloudfoundry.org                                                        "CloudFoundry"
[3]: https://github.com/cloudfoundry/oss-docs/tree/master/vcap/adding_a_system_service  "Adding a System Service to OSS Cloud Foundry"
[4]: https://github.com/CloudCredo/vcap_cassandra                                       "vcap_cassandra"
[5]: https://github.com/CloudCredo/vcap_cassandra/blob/master/config/cassandra_node.yml "vcap_cassandra/config/cassandra_node.yml"
[6]: http://www.datastax.com/                                                           "Datastax"
[7]: http://www.datastax.com/download/community                                         "Datastax community page"


