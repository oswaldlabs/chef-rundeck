log_level       :info
log_location    STDOUT
chef_server_url "https://api.opscode.com/organizations/chef-rundeck"
client_key      "#{ENV["TRAVIS_BUILD_DIR"]}" + "/spec/support/travis.pem"
node_name       "travis"
