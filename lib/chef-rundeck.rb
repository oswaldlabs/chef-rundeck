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

require 'sinatra'
require 'json'
require 'chef'
require 'chef/node'
require 'chef/mixin/xml_escape'

class ChefRundeck < Sinatra::Base

  before do
    content_type 'text/xml'
  end

  include Chef::Mixin::XMLEscape

  class << self
    attr_accessor :config_file
    attr_accessor :username
    attr_accessor :web_ui_url
    attr_accessor :project_config

    def configure
      Chef::Config.from_file(ChefRundeck.config_file)
      Chef::Log.level = Chef::Config[:log_level]


      if (File.exists?(ChefRundeck.project_config)) then
	puts "Using JSON project file #{ChefRundeck.project_config}"
	projects = File.open(ChefRundeck.project_config, "r") { |f|
	  JSON.parse(f.read)
	}
	projects.keys.each do | project |
	  get "/#{project}" do
	    puts "Loading nodes for /#{project}"
	    response = build_project projects[project]['pattern'], projects[project]['username'], (projects[project]['hostname'].nil? ? "fqdn" : projects[project]['hostname'])
	    response
	  end
	end
      else
	get '/' do
	  puts "Loading all nodes for /"
	  response = build_project
	  response
	end
      end
    end
  end

  def build_project (pattern="*:*", username=ChefRundeck.username, hostname="fqdn")
    response =  '<?xml version="1.0" encoding="UTF-8"?>'
    response << '<!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd">'
    response << '<project>'

    q = Chef::Search::Query.new
    q.search("node",pattern) do |node|
      begin
      #--
      # Certain features in Rundeck require the osFamily value to be set to 'unix' to work appropriately. - SRK
      #++
      os_family = node[:kernel][:os] =~ /winnt/i ? 'winnt' : 'unix'
      nodeexec = node[:kernel][:os] =~ /winnt/i ? "node-executor=\"overthere-winrm\"" : ''
      response << <<-EOH
<node name="#{xml_escape(node[:fqdn])}" #{nodeexec} 
      type="Node" 
      description="#{xml_escape(node.name)}"
      osArch="#{xml_escape(node[:kernel][:machine])}"
      osFamily="#{xml_escape(os_family)}"
      osName="#{xml_escape(node[:platform])}"
      osVersion="#{xml_escape(node[:platform_version])}"
      tags="#{xml_escape(node.run_list.roles.concat(node.run_list.recipes).join(',') + ',' + node.chef_environment)}"
      username="#{xml_escape(username)}"
      hostname="#{xml_escape(node[hostname])}"
      editUrl="#{xml_escape(ChefRundeck.web_ui_url)}/nodes/#{xml_escape(node.name)}/edit"/>
EOH
      rescue Exception => e
        puts "Error generating node #{node.name}:\n---\n#{e.message}\n#{e.backtrace.inspect}"
      end
    end
    response << "</project>"
    return response
  end
end

