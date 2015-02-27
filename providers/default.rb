def whyrun_supported?
  true
end

use_inline_resources

action :install do
  node_type = @new_resource.node_type
  Chef::Log.info("Setting up a Druid #{node_type} node")

# Create user and group
  group node[:druid][:group] do
    action :create
  end

  user node[:druid][:user] do
    gid node[:druid][:group]
    home node[:druid][:install_dir]
  end

  directory node[:druid][:install_dir] do
    owner node[:druid][:user]
    group node[:druid][:group]
    mode "0755"
  end

  # Download and extract
  druid_dir = node[:druid][:druid_dir]
  druid_archive = node[:druid][:archive]
  remote_file ::File.join(Chef::Config[:file_cache_path], druid_archive) do
    Chef::Log.info("Installing druid from site '#{node[:druid][:mirror]}'")
    owner "root"
    mode "0644"
    source ::File.join(node[:druid][:mirror], druid_archive)
    checksum node[:druid][:checksum]
    action :create
  end

  execute 'install druid' do
    cwd Chef::Config[:file_cache_path]
    command "chown -R root:root '#{node[:druid][:install_dir]}' && " +
            "tar -C '#{node[:druid][:install_dir]}' -zxf '#{druid_archive}' && " +
            "chown -R #{node[:druid][:user]}:#{node[:druid][:group]} '#{node[:druid][:install_dir]}'"
  end

  link_path = ::File.join(node[:druid][:install_dir], "current")
  Chef::Log.info("Creating #{link_path}")
  # link link_path do
  #   owner node[:druid][:user]
  #   group node[:druid][:group]
  #   to ::File.join(node[:druid][:install_dir], druid_dir)
  #   action :delete
  #   only_if "test -L #{link_path}"
  # end

  link link_path do
    owner node[:druid][:user]
    group node[:druid][:group]
    to ::File.join(node[:druid][:install_dir], druid_dir)
  end


  # Create config directories
  directory ::File.join(node[:druid][:config_dir], node_type) do
    recursive true
    owner node[:druid][:user]
    group node[:druid][:group]
    mode "0755"
  end

  directory ::File.join(node[:druid][:config_dir], "_common") do
    recursive true
    owner node[:druid][:user]
    group node[:druid][:group]
    mode "0755"
  end


  # Select common properties and node type properties
  # Clone doesn't seem to work on node (so just create new Hashes)
  common_props = node[:druid][:properties].inject(Hash.new) { |h, (k, v)| h[k] = v unless v.is_a?(Hash); h }
  type_specific_props = node[:druid][node_type][:properties].inject(Hash.new) { |h, (k, v)| h[k] = v unless v.is_a?(Hash); h }
  type_specific_props["druid.service"] = node_type

  # Write common config file
  common_config_dir = ::File.join(node[:druid][:config_dir], "_common")
  template ::File.join(common_config_dir, "common.runtime.properties") do
    source "properties.erb"
    variables({:properties => common_props})
    owner node[:druid][:user]
    group node[:druid][:group]
  end

  # Write node_type specific config file
  type_specific_config_dir = ::File.join(node[:druid][:config_dir], node_type)
  template ::File.join(type_specific_config_dir, "runtime.properties") do
    source "properties.erb"
    variables({:properties => type_specific_props})
    owner node[:druid][:user]
    group node[:druid][:group]
  end

  # Startup script, works with upstart template
  service_name = "druid-#{node_type}"
  extra_classpath = node[:druid][node_type]["druid.extra_classpath"] || node[:druid]["druid.extra_classpath"]
  template "/etc/init/#{service_name}.conf" do
    source "upstart.conf.erb"
    variables({
                  :node_type => node_type,
                  :user => node[:druid][:user],
                  :group => node[:druid][:group],
                  :type_specific_config_dir => type_specific_config_dir,
                  :common_config_dir => common_config_dir,
                  :install_dir => node[:druid][:install_dir],
                  :java_opts => node[:druid][node_type][:java_opts] || node[:druid][:java_opts],
                  :timezone => node[:druid][:timezone],
                  :encoding => node[:druid][:encoding],
                  :command_suffix => node[:druid][:log_to_syslog].to_s == "1" ? "2>&1 | logger -t #{service_name}" : "",
                  :port => type_specific_props["druid.port"],
                  :extra_classpath => (extra_classpath.nil? || extra_classpath.empty?) ? "" : "#{extra_classpath}:"
              })
  end

  service "druid-#{node_type}" do
    provider Chef::Provider::Service::Upstart
    supports :restart => true, :start => true, :stop => true
    action [:enable, :restart]
  end
end
