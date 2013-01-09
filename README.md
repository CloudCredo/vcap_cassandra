# CloudFoundry Cassandra Service

_Author: **Chris Hedley**_

This code represent the adapter layer between [Cassandra] [1] and [CloudFoundry] [2].


## Adding a service.

We have stuck as closely as possible to the Cloud Foundry conventions of adding a service. Currently we support the
addition fo the Cassandra support through BOSH and Chef.



## Chef:

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

6. Clone and build and deploy the Cassandra security module.
   <ol>
     <li>Clone and Build the artifact. You can find the code and instructions on how to build to module at [cassandra_chastity] [8].</li>
     <li>Copy the jar artifact to $CASSANDRA_INSTALL_LOCATION/lib</li>
     <li>Set the below properties in $CASSANDRA_DEPLOYMENT/conf/cassandra.yaml to the below values:
         <ul>
           <li>authenticator: com.cloudcredo.cassandra.auth.CloudCredoAuthenticator</li>
           <li>authority: org.apache.cassandra.auth.AllowAllAuthority</li>
    </ol>

7. On the Service host add Cassandra to the `gateway` and `node` loops in the file `$CF_HOME/cloudfoundry/vcap/dev_setup/lib/vcap_components.rb`

8. Bundle the necessary dependencies for the Cassandra node and gateway by executing the command
`source $HOME/.cloudfoundry_deployment_profile && bundle package` from the `$CF_HOME/cloudfoundry/vcap/services/cassandra`
directory

9. Restart the cloud controller using the command `$CF_HOME/cloudfoundry/vcap/dev_setup/bin/vcap_dev restart`. A Cassandra node
and gateway should now appear in the list of running components. Running the command `vmc services` from a client targeted
at the newly configured Cloud Foudry instance should reveal Cassandra as a new services.

10. Code to test your deployment can be found at [cassandra-test-jvm-client] [9] along with
instructions on how to build and deploy to your CloudFoundry instance.







## Bosh:

A Bosh installation has also been created that allows Cassandra to be seamlessly deployed in to a bosh deployed CloudFoundry
For more information on our Bosh deployment please email chris@cloudcredo.com.

Copyright 2012 - CloudCredo Ltd.

[1]: http://cassandra.apache.org                                                        "Cassandra"
[2]: http://www.cloudfoundry.org                                                        "CloudFoundry"
[3]: https://github.com/cloudfoundry/oss-docs/tree/master/vcap/adding_a_system_service  "Adding a System Service to OSS Cloud Foundry"
[4]: https://github.com/CloudCredo/vcap_cassandra                                       "vcap_cassandra"
[5]: https://github.com/CloudCredo/vcap_cassandra/blob/master/config/cassandra_node.yml "vcap_cassandra/config/cassandra_node.yml"
[6]: http://www.datastax.com/                                                           "Datastax"
[7]: http://www.datastax.com/download/community                                         "Datastax community page"
[8]: https://github.com/CloudCredo/cassandra_chastity                                   "cassandra_chastity"
[9]: https://github.com/CloudCredo/cassandra-test-jvmclient                             "cassandra-test-jvm-client"


