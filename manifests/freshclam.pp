# freshclam.pp
# Set up freshclam config and service.
#

class clamav::freshclam {

  $config_options = $clamav::_freshclam_options

  # NOTE: In RedHat this is part of the base clamav_package
  # NOTE: In Debian this is a dependency of the base clamav_package
  if $clamav::freshclam_package {
    package { 'freshclam':
      ensure => $clamav::freshclam_version,
      name   => $clamav::freshclam_package,
      before => File['freshclam.conf'],
    }
  }

  file { 'freshclam.conf':
    ensure  => file,
    path    => $clamav::freshclam_config,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/clamav.conf.erb"),
  }

  # NOTE: RedHat comes with /etc/cron.daily/freshclam instead of a service
  if $clamav::freshclam_service {
    service { 'freshclam':
      ensure     => $clamav::freshclam_service_ensure,
      name       => $clamav::freshclam_service,
      enable     => $clamav::freshclam_service_enable,
      hasrestart => true,
      hasstatus  => true,
      subscribe  => File['freshclam.conf'],
    }

    # freshclam needs time to download the patterns, but clamd will not start without patterns.
    # Instead of failing clamav-daemon, we wait for this to finish
    exec { 'wait-for-freshclam':
      command => "/bin/bash -c 'while [ ! -e /var/lib/clamav/daily.cvd ]; do sleep 1; done'",
      creates => '/var/lib/clamav/daily.cvd',
      require => Service['freshclam'],
    }
  }

  if $clamav::manage_clamd and $clamav::freshclam_service {
    Exec['wait-for-freshclam'] -> Service['clamd']
  }

  if $clamav::freshclam_package and $clamav::freshclam_service {
    Package['freshclam'] ~> Service['freshclam']
  }
}
