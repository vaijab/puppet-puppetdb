# == Class: puppetdb
#
# This class installs and configures puppetdb. Currently it is only supported
# to run on the same host as puppet master.
#
# This module needs to be extended if you want to be able to provision PuppetDB
# on a separate host than puppet master.
#
# === Parameters
#
# [*vardir*]
#   Where to store MQ/DB data
#   Default: <code>/var/lib/puppetdb</code>
#
# [*logging_config*]
#   Use an external log4j config file.
#   Default: <code>/etc/puppetdb/log4j.properties</code>
#
# [*resource_query_limit*]
#   Maximum number of results that a resource query may return
#   Default: 20000
#
# [*threads*]
#   How many command-processing threads to use, defaults to (CPUs / 2), so
#   It is set to <code>undef</code> here, because puppetdb process does
#   calculation itself. It can be specified to whatever number you want if
#   needed.
#
# [*db_subprotocol*]
#   What database backend protocol should be used.
#   Valid values: <code>hsqldb</code> or <code>postgresql</code>
#   Default: <code>hsqldb</code> - embedded db
#
# [*psql_host*]
#   Postgresql database host.
#   Default: <code>undef</code>
#
# [*psql_username*]
#   Connect to psql database as a specific user.
#   Default <code>undef</code>
#
# [*psql_password*]
#   Connect to psql database with a specific password.
#   Default: <code>undef</code>
#
# [*gc_interval*]
#   How often in minutes to compact the database.
#   Default: <code>60</code>
#
# [*node_ttl*]
#   Auto-deactivate nodes that haven't seen any activity (no new catalogs,
#   facts, etc) in the specified amount of time.
#     Valid values:
#       `d`  - days
#       `h`  - hours
#       `m`  - minutes
#       `s`  - seconds
#       `ms` - milliseconds
#
#   Default: <code>undef</code>.
#
# [*log_slow_statements*]
#   Number of seconds before any SQL query is considered 'slow'.
#   Default: <code>10</code>
#
# [*jvm_heap_size*]
#   JVM heap size for PuppetDB. It accepts memory size with a letter
#   m for megabytes, g for gigabytes, etc.
#   Default: <code>512m</code>
#
# === Requires
#
# None
#
# === Examples
#
#     ---
#     classes:
#       - puppetdb
#
#     puppetdb::threads: '4'
#
# === Authors
#
# - Vaidas Jablonskis <jablonskis@gmail.com>
#
class puppetdb(
    $ensure               = 'running',
    $enable               = true,
    $vardir               = '/var/lib/puppetdb',
    $logging_config       = '/etc/puppetdb/log4j.properties',
    $resource_query_limit = '20000',
    $threads              = undef,
    $db_subprotocol       = 'hsqldb',
    $psql_host            = undef,
    $psql_username        = undef,
    $psql_password        = undef,
    $gc_interval          = '60',
    $node_ttl             = undef,
    $log_slow_statements  = '10',
    $jvm_heap_size        = '512m',
  ) {
  case $::operatingsystem {
    CentOS, RedHat: {
      $package_name = 'puppetdb'
      $service_name = 'puppetdb'
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

  $config_file         = '/etc/puppetdb/conf.d/config.ini'
  $db_config_file      = '/etc/puppetdb/conf.d/database.ini'
  $conf_template       = 'config.ini.erb'
  $sysconfig_file      = '/etc/sysconfig/puppetdb'
  $sysconf_template    = 'sysconfig_puppetdb.erb'
  $db_conf_template    = 'database.ini.erb'
  $store_password_file = '/etc/puppetdb/ssl/puppetdb_keystore_pw.txt'

  # Check what database backend is configured to be used, if psql, fail if
  # psql credentials are not set.
  if ($db_subprotocol == 'postgresql') and
      (($psql_host == undef) or
      ($psql_username == undef) or
      ($psql_password == undef)) {
    fail('Incomplete postgresql configuration.')
  }

  package { $package_name:
    ensure => installed,
  }

  service { $service_name:
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true,
    require    => Package[$package_name],
  }

  file { $config_file:
    ensure  => file,
    require => Package[$package_name],
    owner   => 'root',
    group   => 'puppetdb',
    mode    => '0640',
    content => template("${module_name}/${conf_template}"),
    notify  => Service[$service_name],
  }

  file { $sysconfig_file:
    ensure  => file,
    require => Package[$package_name],
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template("${module_name}/${sysconf_template}"),
    notify  => Service[$service_name],
  }

  file { $db_config_file:
    ensure  => file,
    require => Package[$package_name],
    owner   => 'root',
    group   => 'puppetdb',
    mode    => '0640',
    content => template("${module_name}/${db_conf_template}"),
    notify  => Service[$service_name],
  }
}
