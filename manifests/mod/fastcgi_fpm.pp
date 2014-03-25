class apache::mod::fastcgi_fpm {

  ::apache::mod { 'fastcgi': }

  # Template uses:
  # - $fastcgi_server
  # - $fastcgi_socket
  # - $fastcgi_dir
  file { 'fastcgi-fpm.conf':
    ensure  => file,
    path    => "${::apache::mod_dir}/fastcgi-fpm.conf",
    content => template('apache/mod/fastcgi-fpm.conf.erb'),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Service['httpd'],
  }

}
