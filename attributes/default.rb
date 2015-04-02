# Copyright 2014 N3TWORK, Inc.
#
# Licensed under Apache 2.0 - see the LICENSE file

# Select git revision for building druid from source
default[:druid][:version] = '0.7.0'
default[:druid][:repository] = 'https://github.com/druid-io/druid.git'
default[:druid][:revision] = 'e81ac2ba4302d488f6c9a3dda8a89af9c10d35e8' # Release 0.7.0

# Installation
default[:druid][:user] = "druid"
default[:druid][:group] = "druid"
default[:druid][:src_dir] = "/opt/druid_src"
default[:druid][:install_dir] = "/opt/druid"
default[:druid][:config_dir] = "/etc/druid"
default[:druid][:log_path] = "/var/log/druid"

#################################################################
# Configuration follows. Settings with ':properties' make their #
# way into configuration files                                  #
#################################################################

#Common configuration
default[:druid][:log_to_syslog] = 1
default[:druid][:properties]["druid.host"] = node[:ipaddress]
default[:druid][:timezone] = "UTC"
default[:druid][:encoding] = "UTF-8"
default[:druid][:java_opts] = "-Xmx1G"
default[:druid][:extra_classpath] = ""
default[:druid][:properties]["druid.monitoring.monitors"] = '["com.metamx.metrics.SysMonitor","com.metamx.metrics.JvmMonitor","io.druid.server.metrics.ServerMonitor"]'
default[:druid][:properties]["druid.emitter"] = "logging"
default['java']['jdk_version'] = '7'

# Node-type-specific configuration. In cases of conflict,
# the type-specific config overrides the common config.

# Broker specific config
default[:druid][:broker][:properties]["druid.service"] = "broker"
default[:druid][:broker][:properties]["druid.port"] = 8080

# Coordinator specific config
default[:druid][:coordinator][:properties]["druid.service"] = "coordinator"
default[:druid][:coordinator][:properties]["druid.port"] = 8081

# Realtime specific config
default[:druid][:realtime][:properties]["druid.service"] = "realtime"
default[:druid][:realtime][:properties]["druid.port"] = 8082
default[:druid][:realtime][:properties]["druid.monitoring.monitors"] = '["com.metamx.metrics.SysMonitor","com.metamx.metrics.JvmMonitor","io.druid.server.metrics.ServerMonitor","io.druid.segment.realtime.RealtimeMetricsMonitor"]'

# Historical specific config
default[:druid][:historical][:properties]["druid.service"] = "historical"
default[:druid][:historical][:properties]["druid.port"] = 8083

# Overlord specific config
default[:druid][:overlord][:properties]["druid.service"] = "overlord"
default[:druid][:overlord][:properties]["druid.port"] = 8084

# Indexer specific config
default[:druid][:indexer][:properties]["druid.port"] = 8085

# Middle manager specific config
default[:druid][:middlemanager][:properties]["druid.service"] = "middlemanager"
default[:druid][:middleManager][:properties]["druid.port"] = 8086



