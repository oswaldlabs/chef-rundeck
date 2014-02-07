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

  include Chef::Mixin::XMLEscape

  class << self
    attr_accessor :config_file
    attr_accessor :username
    attr_accessor :web_ui_url
    attr_accessor :api_url
    attr_accessor :client_key
    attr_accessor :project_config

    def configure
      Chef::Config.from_file(ChefRundeck.config_file)
      Chef::Log.level = Chef::Config[:log_level]

      unless ChefRundeck.api_url
        ChefRundeck.api_url = Chef::Config[:chef_server_url]
      end

      unless ChefRundeck.client_key
        ChefRundeck.client_key = Chef::Config[:client_key]
      end

      if (File.exists?(ChefRundeck.project_config)) then
        Chef::Log.info("Using JSON project file #{ChefRundeck.project_config}")
        projects = File.open(ChefRundeck.project_config, "r") { |f| JSON.parse(f.read) }
        projects.keys.each do | project |
          get "/#{project}" do
            content_type 'text/xml'
            Chef::Log.info("Loading nodes for /#{project}")
            response = build_project projects[project]['pattern'], projects[project]['username'], (projects[project]['hostname'].nil? ? "fqdn" : projects[project]['hostname']), projects[project]['attributes']
            response
          end
        end
      end
      
      get '/' do
        content_type 'text/xml'
        Chef::Log.info("Loading all nodes for /")
        response = build_project
        response
      end
    end
  end

  def build_project (pattern="*:*", username=ChefRundeck.username, hostname="fqdn", custom_attributes=nil)
    response =  '<?xml version="1.0" encoding="UTF-8"?>'
    response << '<!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd">'
    response << '<project>'

    q = Chef::Search::Query.new
    q.search("node",pattern) do |node|
      
      begin
      if node_is_valid? node
        response << build_node(node, username, hostname, custom_attributes)
      else
        Chef::Log.warn("invalid node element: #{node.inspect}")
      end
      rescue Exception => e
        Chef::Log.error("=== could not generate xml for Node: #{node.name} - #{e.message}")
        Chef::Log.debug(e.backtrace.join('\n'))
      end
    end
    
    response << "</project>"
    Chef::Log.debug(response)
    
    return response
  end
end

def build_node (node, username, hostname, custom_attributes)
      #--
      # Certain features in Rundeck require the osFamily value to be set to 'unix' to work appropriately. - SRK
      #++
      data = ''
      os_family = node[:kernel][:os] =~ /winnt|windows/i ? 'winnt' : 'unix'
      nodeexec = node[:kernel][:os] =~ /winnt|windows/i ? "node-executor=\"overthere-winrm\"" : ''
      data << <<-EOH
<node name="#{xml_escape(node[:fqdn])}" #{nodeexec} 
      type="Node" 
      description="#{xml_escape(node.name)}"
      osArch="#{xml_escape(node[:kernel][:machine])}"
      osFamily="#{xml_escape(os_family)}"
      osName="#{xml_escape(node[:platform])}"
      osVersion="#{xml_escape(node[:platform_version])}"
      tags="#{xml_escape(node.run_list.roles.concat(node.run_list.recipes).join(',') + ',' + node.chef_environment)}"
      roles="#{xml_escape(node.run_list.roles.join(','))}"
      recipes="#{xml_escape(node.run_list.recipes.join(','))}"
      environment="#{xml_escape(node.chef_environment)}"
      username="#{xml_escape(username)}"
      hostname="#{xml_escape(node[hostname])}"
      editUrl="#{xml_escape(ChefRundeck.web_ui_url)}/nodes/#{xml_escape(node.name)}/edit" #{custom_attributes.nil? ? '/': ''}>
EOH
     if !custom_attributes.nil? then
       custom_attributes.each do |attr|
        attr_name = attr
        attr_value = get_custom_attr(node, attr.split('.'))
        data << <<-EOH
      <attribute name="#{attr_name}"><![CDATA[#{attr_value}]]></attribute>
EOH
        end
        data << "</node>"
      end

  return data
end

def get_custom_attr (obj, params)
  value = obj
  Chef::Log.debug("loading custom attributes for node: #{obj} with #{params}")
  params.each do |p|   
    value = value[p.to_sym]
    if value.nil? then
      break
    end
  end
  return value.nil? ? "" : value.to_s
end

def node_is_valid?(node)
  node[:fqdn] and
    node.name and
    node[:kernel] and
    node[:kernel][:machine] and
    node[:kernel][:os] and
    node[:platform] and
    node[:platform_version] and
    node.chef_environment     
end
