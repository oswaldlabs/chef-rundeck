$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'chef-rundeck'
require 'rspec'
require 'rspec/autorun'
require 'rack/test'

# setup test environment
# set :environment, :test
# set :run, false
# set :raise_errors, true
# set :logging, false

  def app
    ChefRundeck.new
    ChefRundeck.configure("#{ENV['TRAVIS_BUILD_DIR']}/spec/support/client.rb")
  end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
