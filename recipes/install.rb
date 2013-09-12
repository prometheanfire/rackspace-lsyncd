#
# Cookbook Name:: rackspace-lsyncd
# Recipe:: install
#
# Copyright 2013, Rackspace, Inc.
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


#make sure all sync and log dirs exist
directory File.dirname(node['rackspace-lsyncd']['log-file'])
directory File.dirname(node['rackspace-lsyncd']['status-file'])
directory File.dirname(node['rackspace-lsyncd']['config-file'])
directory node['rackspace-lsyncd']['source']

target_servers = search("node", "role:#{node['rackspace-lsyncd']['target-server-role']} AND chef_environment:#{node.chef_environment}") || []


Chef::Log.warn("target-server-role is #{node['rackspace-lsyncd']['target-server-role']}")
Chef::Log.warn("target-server-Environment is #{node.chef_environment}")
Chef::Log.warn("add #{target_servers.length} nodes")
#this logic is based on the excellent Opscode haproxy cookbook
target_servers.map! do |member|
  Chef::Log.warn(member)

  server_ip = begin
    if member.attribute?('cloud')
      if node.attribute?('cloud') && (member['cloud']['provider'] == node['cloud']['provider'])
         member['cloud']['local_ipv4']
      else
        member['cloud']['public_ipv4']
      end
    else
      member['ipaddress']
    end
  end
  {:ipaddress => server_ip, :hostname => member['hostname']}
end


case node['platform']
when "ubuntu", "debian"

  package "lsyncd" do
    action :install
  end
  
  template "/etc/init.d/lsyncd" do
  	source "ubuntu_init.erb"
  	mode 0755
  	owner "root"
  	group "root"
  end

when "redhat","centos","fedora", "amazon","scientific"


end

template node['rackspace-lsyncd']['config-file'] do
  source "lsyncd.conf.erb"
  mode 0755
  owner "root"
  group "root"
  notifies :reload, "service[lsyncd]"
  variables(
    :target_servers => target_servers.uniq
  )
end

service "lsyncd" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end
