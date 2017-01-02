def whyrun_supported?
  true
end

use_inline_resources

action :install do
  node_type = @new_resource.node_type
  Chef::Log.info("Setting up a Druid #{node_type} node")

# Create user, group, and necessary folders
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
    mode '0755'
  end

  directory node[:druid][:log_path] do
    owner node[:druid][:user]
    group node[:druid][:group]
    mode '0755'
  end

# Download and extract
  druid_dir = "druid-#{node[:druid][:version]}"
  druid_archive = "#{druid_dir}-bin.tar.gz"
  remote_file ::File.join(Chef::Config[:file_cache_path], druid_archive) do
    Chef::Log.info("Installing file '#{druid_archive}' from site '#{node[:druid][:mirror]}'")
    owner 'root'
    mode '0644'
    source ::File.join(node[:druid][:mirror], druid_archive)
    checksum node[:druid][:checksum]
    action :create
  end

  # Extract build druid to install dir
  bash 'install druid' do
    cwd Chef::Config[:file_cache_path]
    code "tar -C #{node[:druid][:install_dir]} -zxf #{druid_archive} && " +
         "chown -R #{node[:druid][:user]}:#{node[:druid][:group]} '#{node[:druid][:install_dir]}'"
  end
  
  druid_current_version_path = ::File.join(node[:druid][:install_dir], "druid-#{node[:druid][:version]}")
  link_path = ::File.join(node[:druid][:install_dir], 'current')

  link link_path do
    owner node[:druid][:user]
    group node[:druid][:group]
    to druid_current_version_path
  end

  # Create config directories
  directory ::File.join(node[:druid][:config_dir], node_type) do
    recursive true
    owner node[:druid][:user]
    group node[:druid][:group]
    mode '0755'
  end

  directory ::File.join(node[:druid][:config_dir], '_common') do
    recursive true
    owner node[:druid][:user]
    group node[:druid][:group]
    mode '0755'
  end

  # Select common properties and node type properties
  # Clone doesn't seem to work on node (so just create new Hashes)
  common_props = node[:druid][:properties].inject(Hash.new) { |h, (k, v)| h[k] = v unless v.is_a?(Hash); h }
  type_specific_props = node[:druid][node_type][:properties].inject(Hash.new) { |h, (k, v)| h[k] = v unless v.is_a?(Hash); h }
  type_specific_props['druid.service'] = node_type

  # Write common config file
  common_config_dir = ::File.join(node[:druid][:config_dir], '_common')
  template ::File.join(common_config_dir, 'common.runtime.properties') do
    source 'properties.erb'
    variables({:properties => common_props})
    owner node[:druid][:user]
    group node[:druid][:group]
  end

  # Write node_type specific config file
  type_specific_config_dir = ::File.join(node[:druid][:config_dir], node_type)
  template ::File.join(type_specific_config_dir, 'runtime.properties') do
    source 'properties.erb'
    variables({:properties => type_specific_props})
    owner node[:druid][:user]
    group node[:druid][:group]
  end

  # Write node_type specific log4j2 config file
  template ::File.join(type_specific_config_dir, 'log4j2.xml') do
    source 'log4j2.xml.erb'
    variables({:node_type => node_type})
    owner node[:druid][:user]
    group node[:druid][:group]
  end

  # Install java
  include_recipe 'java'

  # Install supervisor
  include_recipe 'supervisor'

  # Configure supervisord
  service_name = "druid-#{node_type}"
  extra_classpath = node[:druid][node_type]['druid.extra_classpath'] || node[:druid]['druid.extra_classpath']
  install_dir = node[:druid][:install_dir]
  java_opts = node[:druid][node_type][:java_opts] || node[:druid][:java_opts]
  timezone = node[:druid][:timezone]
  encoding = node[:druid][:encoding]
  log_max_size = node['supervisor']['logging']['file']['maxSize']
  log_max_count = node['supervisor']['logging']['file']['maxCount']
  log_dir = node[:druid][:log_path]

  supervisor_service service_name do
    action [:enable, :start, :restart]
    command "nohup java -cp #{common_config_dir}:#{type_specific_config_dir}:#{extra_classpath}#{install_dir}/current/lib/* -server #{java_opts} -Duser.timezone=#{timezone} -Dfile.encoding=#{encoding} io.druid.cli.Main server #{node_type}"
    user node[:druid][:user]
    autorestart true

    stdout_logfile "#{log_dir}/#{service_name}.log"
    stdout_logfile_maxbytes log_max_size
    stdout_logfile_backups log_max_count
    stderr_logfile "#{log_dir}/#{service_name}.err"
    stderr_logfile_maxbytes log_max_size
    stderr_logfile_backups log_max_count
  end
end
