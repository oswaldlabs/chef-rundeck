#!/bin/sh

# um ... so, obviously, don't run this on a Chef-managed workstation.
mkdir -p /etc/chef/
cp client.rb /etc/chef/
cp travis.pem /etc/chef/client.pem
