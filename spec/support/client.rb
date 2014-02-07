log_level       :debug
log_location    STDOUT
chef_server_url "https://api.opscode.com/organizations/chef-rundeck"
web_ui_url      "https://manage.opscode.com"
client_key      "#{ENV["TRAVIS_BUILD_DIR"]}" + "/spec/support/travis.pem"
node_name       "travis"
username        "travis"
