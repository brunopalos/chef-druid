# Copyright 2014 N3TWORK, Inc.
#
# Licensed under Apache 2.0 - see the LICENSE file

# Download/install
default[:druid][:version] = '0.7.0'
default[:druid][:mirror] = 'http://static.druid.io/artifacts/releases'
default[:druid][:druid_dir] = 'druid-#{default[:druid][:version]}'
default[:druid][:archive] = '#{default[:druid][:druid_dir]}-bin.tar.gz'
default[:druid][:checksum] = "bd3f25b2c8711515c0c5786639bddee5019bd1655cc96b95559f183fbf08e853"

default[:druid][:repository] = 'https://github.com/druid-io/druid.git'
default[:druid][:revision] = 'e81ac2ba4302d488f6c9a3dda8a89af9c10d35e8' # Release 0.7.0

# Installation
default[:druid][:user] = "druid"
default[:druid][:group] = "druid"
default[:druid][:src_dir] = "/opt/druid_src"
default[:druid][:install_dir] = "/opt/druid"
default[:druid][:config_dir] = "/etc/druid"

# Configuration defaults
default[:druid][:log_to_syslog] = 1
default[:druid][:properties]["druid.host"] = node[:ipaddress]
default[:druid][:timezone] = "UTC"
default[:druid][:encoding] = "UTF-8"
default[:druid][:java_opts] = "-Xmx1G"
default[:druid][:extra_classpath] = ""

# Type-specific defaults
default[:druid][:broker][:properties]["druid.port"] = 8080
default[:druid][:coordinator][:properties]["druid.port"] = 8081
default[:druid][:realtime][:properties]["druid.port"] = 8082
default[:druid][:historical][:properties]["druid.port"] = 8083
default[:druid][:overlord][:properties]["druid.port"] = 8084
default[:druid][:indexer][:properties]["druid.port"] = 8085
default[:druid][:middleManager][:properties]["druid.port"] = 8086

# Other
default['java']['jdk_version'] = '7'

