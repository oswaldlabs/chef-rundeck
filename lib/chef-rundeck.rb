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

class ChefRundeck < Sinatra::Base

  include Chef::Mixin::XMLEscape

  class << self
    attr_accessor :config_file
    attr_accessor :username
    attr_accessor :web_ui_url
    attr_accessor :env_node_only

    def configure
      Chef::Config.from_file(ChefRundeck.config_file)
      Chef::Log.level = Chef::Config[:log_level]
    end
  end

  set :environment, :production
  set :lock, true
  get '/' do

    content_type 'text/xml'
    response = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd"><project>'
    if ChefRundeck.env_node_only
      #Get all Chef envs, get all nodes for each env
      #Use inflate = false to reduce load time
      #Tag nodes with their envs in a hash
      #Expand hash into response
      node_hash = {}
      Chef::Environment.list(false).each do |envr|
        Chef::Node.list_by_environment(envr[0], false).each do |node_info|
          #print envr[0], "->", node_arr[0], "->", node_arr[1], "\n"
          node = node_info[0]
          if node_hash.has_key?(node)
            node_hash[node] = "#{node_hash[node]} , #{envr[0]}"
          else
            node_hash[node] = envr[0]
          end
        end
      end
      node_hash.sort_by{ |envs, nodes| nodes }
      node_hash.each_pair do |nodename, nodeenv|
        nodename = xml_escape(nodename)
        response << <<-EOH
  <node name="#{nodename}" 
        type="Node" 
        osFamily="unix"
        tags="#{xml_escape(nodeenv)}"
        username="#{xml_escape(ChefRundeck.username)}"
        hostname="#{nodename}"/>
EOH
      end
      response << "</project>"
      response
    else
      Chef::Node.list(true).each do |node_array|
        node = node_array[1]
        #--
        # Certain features in Rundeck require the osFamily value to be set to 'unix' to work appropriately. - SRK
        #++
        os_family = node[:kernel][:os] =~ /windows/i ? 'windows' : 'unix'
        response << <<-EOH
  <node name="#{xml_escape(node[:fqdn])}"
        type="Node"
        description="#{xml_escape(node.name)}"
        osArch="#{xml_escape(node[:kernel][:machine])}"
        osFamily="#{xml_escape(os_family)}"
        osName="#{xml_escape(node[:platform])}"
        osVersion="#{xml_escape(node[:platform_version])}"
        tags="#{xml_escape([node.chef_environment, node.run_list.roles.join(',')].join(','))}"
        username="#{xml_escape(ChefRundeck.username)}"
        hostname="#{xml_escape(node[:fqdn])}"
        editUrl="#{xml_escape(ChefRundeck.web_ui_url)}/nodes/#{xml_escape(node.name)}/edit"/>
EOH
      end
      response << "</project>"
      response        
    end
  end
end
