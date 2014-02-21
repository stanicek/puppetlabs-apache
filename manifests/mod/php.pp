class apache::mod::php (
  $package_ensure = 'present',
) {
  if ! (defined(Class['apache::mod::prefork']) || defined(Class['apache::mod::php5-fpm'])) {
    fail('apache::mod::php requires apache::mod::prefork or apache::mod::php5-fpm; please enable mpm_module => \'prefork\' or \'php5-fpm\' on Class[\'apache\']')
  }
  apache::mod { 'php5':
    package_ensure => $package_ensure,
  }

  include apache::mod::mime
  include apache::mod::dir
  Class['apache::mod::mime'] -> Class['apache::mod::dir'] -> Class['apache::mod::php']

  $php5_conf_ensure = $package_ensure ? {
    /(present|installed|held|latest)/ => 'file',
    default                           => 'absent',
  }

  file { 'php5.conf':
    ensure  => $php5_conf_ensure,
    path    => "${apache::mod_dir}/php5.conf",
    content => template('apache/mod/php5.conf.erb'),
    require => [
      Class['apache::mod::prefork'],
      Exec["mkdir ${apache::mod_dir}"],
    ],
    before  => File[$apache::mod_dir],
    notify  => Service['httpd'],
  }
}
