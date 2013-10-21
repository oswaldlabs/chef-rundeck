#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'sinatra/base'
require 'chef'
require 'chef/node'
require 'chef/mixin/xml_escape'
require 'chef/rest'

require 'chef-rundeck/vendor/partial_search'

class ChefRundeck < Sinatra::Base

  include Chef::Mixin::XMLEscape

  class << self
    attr_accessor :config_file
    attr_accessor :username
    attr_accessor :api_url
    attr_accessor :web_ui_url
    attr_accessor :client_key
    attr_accessor :use_partial_search

    def configure
      Chef::Config.from_file(ChefRundeck.config_file)
      Chef::Log.level = Chef::Config[:log_level]

      unless ChefRundeck.api_url
        ChefRundeck.api_url = Chef::Config[:chef_server_url]
      end

      unless ChefRundeck.client_key
        ChefRundeck.client_key = Chef::Config[:client_key]
      end
    end
  end

  get '/' do
    nodes = if ChefRundeck.use_partial_search
      request_nodes_via_partial_search
    else
      request_nodes_via_rest
    end

    content_type 'text/xml'
    response = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd"><project>'
    nodes.each do |node|
      begin
        response << <<-EOH
<node name="#{xml_escape(node['fqdn'])}"
      type="Node"
      description="#{xml_escape(node['name'])}"
      osArch="#{xml_escape(node['kernel_machine'])}"
      osFamily="#{xml_escape(node['os_family'] =~ /windows/i ? 'windows' : 'unix')}"
      osName="#{xml_escape(node['platform'])}"
      osVersion="#{xml_escape(node['platform_version'])}"
      tags="#{xml_escape([node['chef_environment'], node['tags'], node['roles']].flatten.join(','))}"
      username="#{xml_escape(ChefRundeck.username)}"
      hostname="#{xml_escape(node['fqdn'])}"
      editUrl="#{xml_escape(ChefRundeck.web_ui_url)}/nodes/#{xml_escape(node['name'])}/edit"/>
EOH
      rescue
        warn $!
      end
    end
    response << "</project>"
    response
  end

  def request_nodes_via_rest
    rest = Chef::REST.new(ChefRundeck.api_url)
    nodes = rest.get_rest('/nodes/')
      
    nodes.keys.map do |node_name|
      node = rest.get_rest("/nodes/#{node_name}")
      #--
      # Certain features in Rundeck require the osFamily value to be set to 'unix' to work appropriately. - SRK
      #++
      { 'os_family' => (node[:kernel] && node[:kernel][:os] =~ /windows/i ? 'windows' : 'unix'),
        'fqdn' => node[:fqdn],
        'name' => node_name,
        'kernel_machine' => (node[:kernel] && node[:kernel][:machine]),
        'platform' => node[:platform],
        'platform_version' => node[:platform_version],
        'chef_environment' => node.chef_environment,
        'tags' =>  node[:tags],
        'roles' => node.run_list.roles
      }
    end
  end

  def request_nodes_via_partial_search
    keys = {
      kernel_os: ['kernel','os'],
      fqdn: ['fqdn'],
      name: ['name'],
      kernel_machine: ['kernel','machine'],
      platform: ['platform'],
      platform_version: ['platform_version'],
      chef_environment: ['chef_environment'],
      tags:  ['tags'],
      roles: ['roles']
    }

    results = Array.new
    Chef::PartialSearch.new.search(:node, '*:*', keys: keys) do |o|
      results << o
    end
    results
  end
end

