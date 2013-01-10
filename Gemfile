source 'http://rubygems.org'

gem 'eventmachine', :git => 'git://github.com/cloudfoundry/eventmachine.git', :branch => 'release-0.12.11-cf'
gem 'em-http-request', '1.0.0.beta.3'
gem 'nats', '>= 0.4.8'
gem 'ruby-hmac', '= 0.4.0'
gem 'uuidtools', '= 2.1.3'
gem 'datamapper', '= 1.1.0'
gem 'dm-sqlite-adapter', '1.2.0'
gem 'do_sqlite3', '0.10.8'
gem 'sinatra', '~> 1.2.3'
gem 'thin', '1.3.1'

gem 'vcap_common', :require => ['vcap/common', 'vcap/component'], :git => 'https://github.com/cloudfoundry/vcap-common.git'
gem 'vcap_logging', :require => ['vcap/logging'], :git => 'git://github.com/cloudfoundry/common.git', :ref => 'b96ec1192'
gem 'vcap_services_base', :git => 'git://github.com/cloudfoundry/vcap-services-base.git', :ref => 'db367f31'
gem 'warden-client', :require => ['warden/client'], :git => 'git://github.com/cloudfoundry/warden.git', :ref => '21f9a32ab50'
gem 'warden-protocol', :require => ['warden/protocol'], :git => 'git://github.com/cloudfoundry/warden.git', :ref => '21f9a32ab50'

group :test do
  gem 'rake'
  gem 'rspec'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'ci_reporter'
end
