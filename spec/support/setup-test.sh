#!/bin/sh

# um ... so, obviously, don't run this on a Chef-managed workstation.
mkdir -p /etc/chef/
cp spec/support/client.rb /etc/chef/client.rb
cp spec/support/travis.pem /etc/chef/client.pem
cat /etc/chef/client.rb
cat /etc/chef/client.pem
