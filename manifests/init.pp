# == Class: puppetdb
#
# This class installs and configures PuppetDB. Currently it is only supported
# to run on the same host as puppet master.
#
# This module needs to be extended if you want to be able to provision PuppetDB
# on a separate host than puppet master.
#
# === Parameters
#
# See README.md
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
    $node_purge_ttl       = undef,
    $log_slow_statements  = '10',
    $jvm_heap_size        = '512m',
  ) {
  case $::osfamily {
    RedHat: {
      $package_name   = 'puppetdb'
      $service_name   = 'puppetdb'
      $sysconfig_file = '/etc/sysconfig/puppetdb'
    }
    Debian: {
      $package_name   = 'puppetdb'
      $service_name   = 'puppetdb'
      $sysconfig_file = '/etc/default/puppetdb'
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

  $config_file      = '/etc/puppetdb/conf.d/config.ini'
  $db_config_file   = '/etc/puppetdb/conf.d/database.ini'
  $conf_template    = 'config.ini.erb'
  $sysconf_template = 'sysconfig_puppetdb.erb'
  $db_conf_template = 'database.ini.erb'

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
    notify => Exec['/usr/sbin/puppetdb-ssl-setup']
  }

  exec { '/usr/sbin/puppetdb-ssl-setup':
    creates     => '/etc/puppetdb/ssl/private.pem',
    refreshonly => true,
    before      => Service[$service_name],
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
