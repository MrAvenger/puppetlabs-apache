class apache::mod::ssl (
  $ssl_compression        = false,
  $ssl_options            = [ 'StdEnvVars' ],
  $ssl_cipher             = 'HIGH:MEDIUM:!aNULL:!MD5',
  $ssl_protocol           = [ 'all', '-SSLv2', '-SSLv3' ],
  $ssl_pass_phrase_dialog = 'builtin',
  $ssl_random_seeds       = [
    'startup builtin',
    'startup file:/dev/urandom 512',
    'connect builtin',
    'connect file:/dev/urandom 512',
  ],
  $apache_version         = $::apache::apache_version,
  $package_name           = undef,
) {
  $session_cache = $::osfamily ? {
    'debian'  => "\${APACHE_RUN_DIR}/ssl_scache(512000)",
    'redhat'  => '/var/cache/mod_ssl/scache(512000)',
    'freebsd' => '/var/run/ssl_scache(512000)',
    'gentoo'  => '/var/run/ssl_scache(512000)',
  }

  case $::osfamily {
    'debian': {
      if versioncmp($apache_version, '2.4') >= 0 {
        $ssl_mutex = 'default'
      } elsif $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease == '10.04' {
        $ssl_mutex = 'file:/var/run/apache2/ssl_mutex'
      } else {
        $ssl_mutex = "file:\${APACHE_RUN_DIR}/ssl_mutex"
      }
    }
    'redhat': {
      $ssl_mutex = 'default'
    }
    'freebsd': {
      $ssl_mutex = 'default'
    }
    'gentoo': {
      $ssl_mutex = 'default'
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }

  ::apache::mod { 'ssl':
    package => $package_name,
  }

  if versioncmp($apache_version, '2.4') >= 0 {
    ::apache::mod { 'socache_shmcb': }
  }

  # Template uses
  #
  # $ssl_compression
  # $ssl_options
  # $session_cache,
  # $ssl_mutex
  # $ssl_random_seeds
  # $apache_version
  #
  file { 'ssl.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/ssl.conf",
    content => template('apache/mod/ssl.conf.erb'),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Class['apache::service'],
  }
}
