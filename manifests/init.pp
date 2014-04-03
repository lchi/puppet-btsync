# = Class: btsync
#
# This class installs and configure BTSync torrent client.
#
# == Parameters:
#
# $glibc23:: The btsync version with glibc23.
#
# $install_dir::  BTSync home path.
#
# $storage_conf_path::  BTSync conf path.
#
# == Requires:
#
# Nothing
#
# == Sample Usage:
#
#   class {'btsync':
#     webui_login => 'my_login',
#     webui_pwd   => 'my_password',
#     api_key     => 'my_api_key',
#   }
#
# == Authors
#
# Gamaliel Sick
#
# == Copyright
#
# Copyright 2014 Gamaliel Sick, unless otherwise noted.
#
class btsync(
  $glibc23           = true,
  $install_dir       = '/opt/btsync',
  $storage_conf_path = '/opt/btsync/.sync',
  $log_directory     = '/var/log/btsync',
  $tmp               = '/tmp',
  $settings          = {},
  $shared_folders    = [],
  $known_hosts       = [],
  $service_ensure    = running,
) {

  case $::architecture {
    'x86_64':        {  $arch = 'x64'}
    'amd64':         {  $arch = 'x64'}
    'i386':          {  $arch = 'i386'}
    default:         {  fail("Architecture not compatible: ${::architecture}")}
  }

  case $glibc23 {
    true:       { $download_url = "http://download-lb.utorrent.com/endpoint/btsync/os/linux-glibc23-${arch}/track/stable"
                  $file_name = "btsync_glibc23_${arch}.tar.gz"}
    default:    { $download_url = "http://download-lb.utorrent.com/endpoint/btsync/os/linux-${arch}/track/stable"
                  $file_name = "btsync_${arch}.tar.gz"}
  }

  file { [$install_dir, $storage_conf_path]:
    ensure => directory,
  }

  file { $log_directory:
    ensure => directory,
    mode   => 0755,
  }

  exec { 'download btsync':
    cwd     => $tmp,
    path    => '/bin:/usr/bin',
    command => "wget -O ${file_name} ${download_url}",
    creates => "${tmp}/${file_name}",
    notify  => Exec['untar btsync'],
    require => Package['wget'],
  }

  exec { 'untar btsync':
    cwd     => $tmp,
    path    => '/bin:/usr/bin',
    command => "tar -zxvf ${file_name} -C ${install_dir}",
    creates => "${install_dir}/btsync",
    require => File[$install_dir],
  }

  file { "${install_dir}/btsync.json":
    ensure  => file,
    require => File[$install_dir],
    content => template("${module_name}/btsync.json.erb"),
  }

  file { "/etc/init.d/btsync":
    ensure  => file,
    mode    => 0755,
    content => template("${module_name}/btsync.init.d.erb"),
    require => Exec['untar btsync']
  }

  service { 'btsync':
    ensure     => $service_ensure,
    hasrestart => true,
    hasstatus  => true,
    require    => File["/etc/init.d/btsync", "${install_dir}/btsync.json"],
  }
}
