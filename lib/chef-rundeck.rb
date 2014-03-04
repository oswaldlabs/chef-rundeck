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
require 'chef/role'
require 'chef/environment'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'partial_search'

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
    attr_accessor :cache_timeout
    attr_accessor :partial_search

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
            send_file build_project project, projects[project]['pattern'], projects[project]['username'], (projects[project]['hostname'].nil? ? "fqdn" : projects[project]['hostname']), projects[project]['attributes']
          end
        end
      end
      
      get '/' do
        content_type 'text/xml'
        Chef::Log.info("Loading all nodes for /")
        send_file build_project
      end
    end
  end

  def build_project (project="default", pattern="*:*", username=ChefRundeck.username, hostname="fqdn", custom_attributes=nil)
    response = nil
    begin

      # file is too new use it again
      if (File.exists?("#{Dir.tmpdir}/chef-rundeck-#{project}.xml") && (Time.now - File.atime("#{Dir.tmpdir}/chef-rundeck-#{project}.xml") < ChefRundeck.cache_timeout)) then 
        return "#{Dir.tmpdir}/chef-rundeck-#{project}.xml"
      end

      results = []
      if ChefRundeck.partial_search then
        keys = { 'name' => ['name'],
                 'kernel_machine' => [ 'kernel', 'machine' ],
                 'kernel_os' => [ 'kernel', 'os' ],
                 'fqdn' => [ 'fqdn' ],
                 'run_list' => [ 'run_list' ],
                 'roles' => [ 'roles' ],
                 'recipes' => [ 'recipes' ],
                 'chef_environment' => [ 'chef_environment' ],
                 'platform' => [ 'platform'],
                 'platform_version' => [ 'platform_version' ],
                 'hostname' => [ 'hostname' ]
               }  
        if !custom_attributes.nil? then
          custom_attributes.each do |attr|
          attr_name = attr.gsub('.', '_')
          attr_value = attr.split('.')
          keys[attr_name] = attr_value
          end
        end
        
        # do search
        Chef::Log.info("partial search started (project: '#{project}')")
        results = partial_search(:node,pattern, :keys => keys)
        Chef::Log.info("partial search finshed (project: '#{project}', count: #{results.length})")
      else 
        q = Chef::Search::Query.new
        Chef::Log.info("search started (project: '#{project}')")
        results = q.search("node",pattern)[0]
        Chef::Log.info("search finshed (project: '#{project}', count: #{results.length})")
      end
      
      response = File.open("#{Dir.tmpdir}/chef-rundeck-#{project}.xml", 'w')
      response.write '<?xml version="1.0" encoding="UTF-8"?>'
      response.write '<!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd">'
      response.write '<project>'

      Chef::Log.info("building nodes (project: '#{project}')")
      failed = 0
      results.each do |node|
        begin
          # validate the node
          begin
            node_is_valid? node
          rescue ArgumentError => ae
            Chef::Log.warn("invalid node element: #{ae}")
            failed = failed +1
            next
          end
          
          #write the node to the project
          response.write build_node(node, username, hostname, custom_attributes)
        rescue Exception => e
          Chef::Log.error("=== could not generate xml for #{node}:  #{e.message}")
          Chef::Log.debug(e.backtrace.join('\n'))
        end
      end
      Chef::Log.info("nodes complete (project: '#{project}', total: #{results.length - failed}, failed: #{failed})")
      
      response.write "</project>"
      Chef::Log.debug(response)
    ensure
      response.close unless response == nil
    end
    return response.path
  end
end

def build_node (node, username, hostname, custom_attributes)
      #--
      # Certain features in Rundeck require the osFamily value to be set to 'unix' to work appropriately. - SRK
      #++
      data = ''
      os_family = node['kernel_os'] =~ /winnt|windows/i ? 'winnt' : 'unix'
      nodeexec = node['kernel_os'] =~ /winnt|windows/i ? "node-executor=\"overthere-winrm\"" : ''
      data << <<-EOH
<node name="#{xml_escape(node['fqdn'])}" #{nodeexec} 
      type="Node" 
      description="#{xml_escape(node['name'])}"
      osArch="#{xml_escape(node['kernel_machine'])}"
      osFamily="#{xml_escape(os_family)}"
      osName="#{xml_escape(node['platform'])}"
      osVersion="#{xml_escape(node['platform_version'])}"
      roles="#{xml_escape(node['roles'].join(','))}"
      recipes="#{xml_escape(node['recipes'].join(','))}"
      tags="#{xml_escape(node['roles'].concat(node['recipes']).join(',') + ',' + node['chef_environment'])}"
      environment="#{xml_escape(node['chef_environment'])}"
      username="#{xml_escape(username)}"
      hostname="#{xml_escape(node['hostname'])}"
      editUrl="#{xml_escape(ChefRundeck.web_ui_url)}/nodes/#{xml_escape(node['name'])}/edit" #{custom_attributes.nil? ? '/': ''}>
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
  Chef::Log.debug("loading custom attributes for node: #{obj['name']} with #{params}")
  params.each do |p|   
    value = value[p.to_sym]
    if value.nil? then
      break
    end
  end
  return value.nil? ? "" : value.to_s
end


# Helper def to validate the node 
def node_is_valid?(node)
  raise ArgumentError, "#{node} missing 'name'" if !node['name']
  raise ArgumentError, "#{node} missing 'chef_environment'" if !node['chef_environment']
  raise ArgumentError, "#{node} missing 'run_list'" if !node['run_list']
  raise ArgumentError, "#{node} missing 'recipes'" if !node['recipes']
  raise ArgumentError, "#{node} missing 'roles'" if !node['roles']
  raise ArgumentError, "#{node} missing 'fqdn'" if !node['fqdn']
  raise ArgumentError, "#{node} missing 'kernel.machine'" if !node['kernel_machine']
  raise ArgumentError, "#{node} missing 'kernel.os'" if !node['kernel_os']
  raise ArgumentError, "#{node} missing 'platform'" if !node['platform']
  raise ArgumentError, "#{node} missing 'platform_version'" if !node['platform_version']
end


# partial_search(type, query, options, &block)
#
# Searches for nodes, roles, etc. and returns the results.  This method may
# perform more than one search request, if there are a large number of results.
#
# ==== Parameters
# * +type+: index type (:role, :node, :client, :environment, data bag name)
# * +query+: SOLR query.  "*:*", "role:blah", "not role:blah", etc.  Defaults to '*:*'
# * +options+: hash with options:
# ** +:start+: First row to return (:start => 50, :rows => 100 means "return the
#               50th through 150th result")
# ** +:rows+: Number of rows to return.  Defaults to 1000.
# ** +:sort+: a SOLR sort specification.  Defaults to 'X_CHEF_id_CHEF_X asc'.
# ** +:keys+: partial search keys.  If this is not specified, the search will
#             not be partial.
#
# ==== Returns
#
# This method returns an array of search results.  Partial search results will
# be JSON hashes with the structure specified in the +keys+ option.  Other
# results include +Chef::Node+, +Chef::Role+, +Chef::Client+, +Chef::Environment+,
# +Chef::DataBag+ and +Chef::DataBagItem+ objects, depending on the search type.
#
# If a block is specified, the block will be called with each result instead of
# returning an array.  This method will not block if it returns
#
# If start or row is specified, and no block is given, the result will be a
# triple containing the list, the start and total:
#
#     [ [ row1, row2, ... ], start, total ]
#
# ==== Example
#
#     partial_search(:node, 'role:webserver',
#                    keys: {
#                      name: [ 'name' ],
#                      ip: [ 'amazon', 'ip', 'public' ]
#                    }
#     ).each do |node|
#       puts "#{node[:name]}: #{node[:ip]}"
#     end
#
def partial_search(type, query='*:*', *args, &block)
  # Support both the old (positional args) and new (hash args) styles of calling
  if args.length == 1 && args[0].is_a?(Hash)
    args_hash = args[0]
  else
    args_hash = {}
    args_hash[:sort] = args[0] if args.length >= 1
    args_hash[:start] = args[1] if args.length >= 2
    args_hash[:rows] = args[2] if args.length >= 3
  end
  # If you pass a block, or have the start or rows arguments, do raw result parsing
  if Kernel.block_given? || args_hash[:start] || args_hash[:rows]
    ChefRundeck::PartialSearch.new.search(type, query, args_hash, &block)
 
  # Otherwise, do the iteration for the end user
  else
    results = Array.new
    ChefRundeck::PartialSearch.new.search(type, query, args_hash) do |o|
        results << o
    end
     results
  end
end
