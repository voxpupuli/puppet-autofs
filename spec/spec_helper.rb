require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'mocha'
require 'hiera'
require 'erb'
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
# include common helpers
support_path = File.expand_path(File.join(File.dirname(__FILE__), '..',
                                          'spec/support/*.rb'))
Dir[support_path].each {|f| require f}
RSpec.configure do |c|
  c.config = '/doesnotexist'
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.mock_with :mocha
  c.hiera_config = File.join(fixture_path, 'hiera/hiera.yaml')
end