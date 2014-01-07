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

REQUIRED_ATTRS = [ :kernel, :fqdn, :platform, :platform_version ]

class MissingAttribute < StandardError
  attr_reader :name
  def initialize(name)
    @name = name
  end
end

class ChefRundeck < Sinatra::Base
	

  class << self
    attr_accessor :config_file
    attr_accessor :username
    attr_accessor :api_url
    attr_accessor :web_ui_url
    attr_accessor :client_key

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

    def create_node_xml(node,node_name)
        begin
	      #--
	      # Certain features in Rundeck require the osFamily value to be set to 'unix' to work appropriately. - SRK
	      #++
	      os_family = node[:kernel][:os] =~ /windows/i ? 'windows' : 'unix'
 <<-EOH
	<node name="#{Chef::Mixin::XMLEscape::xml_escape(node[:fqdn])}"
	      type="Node"
	      description="#{Chef::Mixin::XMLEscape::xml_escape(node_name)}"
	      osArch="#{Chef::Mixin::XMLEscape::xml_escape(node[:kernel][:machine])}"
	      osFamily="#{Chef::Mixin::XMLEscape::xml_escape(os_family)}"
	      osName="#{Chef::Mixin::XMLEscape::xml_escape(node[:platform])}"
	      osVersion="#{Chef::Mixin::XMLEscape::xml_escape(node[:platform_version])}"
	      tags="#{Chef::Mixin::XMLEscape::xml_escape([node.chef_environment, node[:tags].join(','), node.run_list.roles.join(',')].join(','))}"
	      username="#{Chef::Mixin::XMLEscape::xml_escape(ChefRundeck.username)}"
	      hostname="#{Chef::Mixin::XMLEscape::xml_escape(node[:fqdn])}"
	      editUrl="#{Chef::Mixin::XMLEscape::xml_escape(ChefRundeck.web_ui_url)}/nodes/#{Chef::Mixin::XMLEscape::xml_escape(node_name)}/edit"/>
EOH

 	rescue => e
	 	Chef::Log.error("=== ERROR: could not generate xml for Node: #{node_name} \n #{e.message}")
		Chef::Log.debug(e.backtrace.join('\n'))
		return "<node name=\"#{Chef::Mixin::XMLEscape::xml_escape(node_name)}\" description=\"Error occured retrieving node information\" 
		hostname=\"Error \"  username=\"Error\" />"
	end

    end
  end

  get '/' do
    content_type 'text/xml'
    response = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd"><project>'
    Chef::Node.list(true).each do |node_array|
      node = node_array[1]
      if node_is_valid? node
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
  end
    response << "</project>"

    Chef::Log.debug(response)

    response
  end
end

def node_is_valid?(node)
  node[:fqdn] and
    node.name and
    node[:kernel] and
    node[:kernel][:machine] and
    node[:kernel][:os] and
    node[:platform] and
    node[:platform_version] and
    node.chef_environment and
    node.run_list.respond_to?(:join)    
end