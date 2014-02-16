class apache::mod::php5-fpm (
  $startservers        = '8',
  $minspareservers     = '5',
  $maxspareservers     = '20',
  $serverlimit         = '256',
  $maxclients          = '256',
  $maxrequestsperchild = '4000',
) {
  if defined(Class['apache::mod::event']) {
    fail('May not include both apache::mod::php5-fpm and apache::mod::event on the same node')
  }
  if defined(Class['apache::mod::itk']) {
    fail('May not include both apache::mod::php5-fpm and apache::mod::itk on the same node')
  }
  if defined(Class['apache::mod::peruser']) {
    fail('May not include both apache::mod::php5-fpm and apache::mod::peruser on the same node')
  }
  if defined(Class['apache::mod::worker']) {
    fail('May not include both apache::mod::php5-fpm and apache::mod::worker on the same node')
  }
  if defined(Class['apache::mod::prefork']) {
    fail('May not include both apache::mod::php5-fpmand apache::mod::preform on the same node')
  }
  File {
    owner => 'root',
    group => $apache::params::root_group,
    mode  => '0644',
  }

  # Template uses:
  # - $startservers
  # - $minspareservers
  # - $maxspareservers
  # - $serverlimit
  # - $maxclients
  # - $maxrequestsperchild
  file { "${apache::mod_dir}/php5-fpm.conf":
    ensure  => file,
    content => template('apache/mod/php5-fpm.conf.erb'),
    require => Exec["mkdir ${apache::mod_dir}"],
    before  => File[$apache::mod_dir],
    notify  => Service['httpd'],
  }

  case $::osfamily {
    'redhat': {
      file_line { '/etc/sysconfig/httpd prefork enable':
        ensure  => present,
        path    => '/etc/sysconfig/httpd',
        line    => '#HTTPD=/usr/sbin/httpd.worker',
        match   => '#?HTTPD=/usr/sbin/httpd.worker',
        require => Package['httpd'],
        notify  => Service['httpd'],
      }
    }
    'debian': {
      file { "${apache::mod_enable_dir}/php5-fpm.conf":
        ensure  => link,
        target  => "${apache::mod_dir}/php5-fpm.conf",
        require => Exec["mkdir ${apache::mod_enable_dir}"],
        before  => File[$apache::mod_enable_dir],
        notify  => Service['httpd'],
      }
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }
}
