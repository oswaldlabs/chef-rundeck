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

    def configure
      Chef::Config.from_file(ChefRundeck.config_file)
      Chef::Log.level = Chef::Config[:log_level]
    end
  end

  get '/' do
    response = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd"><project>'
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
      tags="#{xml_escape(node.run_list.roles.join(','))}"
      username="#{xml_escape(ChefRundeck.username)}"
      hostname="#{xml_escape(node[:fqdn])}"
      editUrl="#{xml_escape(ChefRundeck.web_ui_url)}/nodes/#{xml_escape(node.name)}/edit"/>
EOH
    end
    response << "</project>"
    response
  end
end

