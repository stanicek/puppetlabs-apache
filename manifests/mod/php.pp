class apache::mod::php (
  $package_ensure = 'present',
) {
if ((!defined(Class['apache::mod::prefork'])) and (!defined(Class['apache::mod::worker']))) {
    fail('apache::mod::php requires apache::mod::prefork; please enable mpm_module => \'prefork\' on Class[\'apache\']')
  }
  if (defined(Class['apache::mod::worker'])) {
  ::apache::mod { 'php5':
      package_ensure => 'absent',
    }
  } else {
  ::apache::mod { 'php5':
    package_ensure => $package_ensure,
  }
  }

  include ::apache::mod::mime
  include ::apache::mod::dir
  Class['::apache::mod::mime'] -> Class['::apache::mod::dir'] -> Class['::apache::mod::php']

  $php5_conf_ensure = $package_ensure ? {
    /(present|installed|held|latest)/ => 'file',
    default                           => 'absent',
  }
  
  if (defined(Class['apache::mod::prefork'])) {
    $required_dependencies = [
      Class['prefork'],
      Exec["mkdir ${apache::mod_dir}"],
    ]
  	$php_conf_path = "apache/mod/php5.conf.erb"
  }
  
  if (defined(Class['apache::mod::worker'])) {
    $required_dependencies = [
      Class['worker'],
      Apache::Mod['actions'],
      Exec["mkdir ${apache::mod_dir}"],
    ]
    contain apache::mod::fastcgi
  	$php_conf_path = "apache/mod/php5-fpm.conf.erb"
  }

  file { 'php5.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/php5.conf",
    content => template('apache/mod/php5.conf.erb'),
    require => [
      Exec["mkdir ${::apache::mod_dir}"],
    ],
    before  => File[$::apache::mod_dir],
    notify  => Service['httpd'],
  }
}
