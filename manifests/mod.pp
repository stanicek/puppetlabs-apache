define apache::mod (
  $package = undef,
  $package_ensure = 'present',
  $lib = undef,
  $lib_path = $apache::params::lib_path,
  $id = undef,
  $path = undef,
) {
  if ! defined(Class['apache']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  $mod = $name
  #include apache #This creates duplicate resources in rspec-puppet
  $mod_dir = $apache::mod_dir

  # Determine if we have special lib
  $mod_libs = $apache::params::mod_libs
  $mod_lib = $mod_libs[$mod] # 2.6 compatibility hack
  if $lib {
    $my_lib = $lib
  } elsif "${mod_lib}" {
    $my_lib = $mod_lib
  } else {
    $my_lib = "mod_${mod}.so"
  }

  # Determine if declaration specified a path to the module
  if $path {
    $my_path = $path
  } else {
    $my_path = "${lib_path}/${my_lib}"
  }

  if $id {
    $my_id = $id
  } else {
    $my_id = "${mod}_module"
  }

  # Determine if we have a package
  $mod_packages = $apache::params::mod_packages
  $mod_package = $mod_packages[$mod] # 2.6 compatibility hack
  if $package {
    $my_package = $package
  } elsif "${mod_package}" {
    $my_package = $mod_package
  }
  if $my_package and ! defined(Package[$my_package]) {
    # note: FreeBSD/ports uses apxs tool to activate modules; apxs clutters
    # httpd.conf with 'LoadModule' directives; here, by proper resource
    # ordering, we ensure that our version of httpd.conf is reverted after
    # the module gets installed.
    $package_before = $::osfamily ? {
      'freebsd' => [
        File["${mod_dir}/${mod}.load"],
        File["${apache::params::conf_dir}/${apache::params::conf_file}"]
      ],
      default => File["${mod_dir}/${mod}.load"],
    }
    # $my_package may be an array
    package { $my_package:
      ensure  => $package_ensure,
      require => Package['httpd'],
      before  => $package_before,
    }
  }

  $mod_load_ensure = $package_ensure ? {
    /(present|installed|held|latest)/ => 'file',
    default                           => 'absent',
  }

  $mod_symlink_ensure = $package_ensure ? {
    /(present|installed|held|latest)/ => 'link',
    default                           => 'absent',
  }

  file { "${mod}.load":
    ensure  => $mod_load_ensure,
    path    => "${mod_dir}/${mod}.load",
    owner   => 'root',
    group   => $apache::params::root_group,
    mode    => '0644',
    content => "LoadModule ${my_id} ${my_path}\n",
    require => [
      Package['httpd'],
      Exec["mkdir ${mod_dir}"],
    ],
    before  => File[$mod_dir],
    notify  => Service['httpd'],
  }

  if $::osfamily == 'Debian' {
    $enable_dir = $apache::mod_enable_dir
    file{ "${mod}.load symlink":
      ensure  => $mod_symlink_ensure,
      path    => "${enable_dir}/${mod}.load",
      target  => "${mod_dir}/${mod}.load",
      owner   => 'root',
      group   => $apache::params::root_group,
      mode    => '0644',
      require => [
        File["${mod}.load"],
        Exec["mkdir ${enable_dir}"],
      ],
      before  => File[$enable_dir],
      notify  => Service['httpd'],
    }
    # Each module may have a .conf file as well, which should be
    # defined in the class apache::mod::module
    # Some modules do not require this file.
    if defined(File["${mod}.conf"]) {
      file{ "${mod}.conf symlink":
        ensure  => $mod_symlink_ensure,
        path    => "${enable_dir}/${mod}.conf",
        target  => "${mod_dir}/${mod}.conf",
        owner   => 'root',
        group   => $apache::params::root_group,
        mode    => '0644',
        require => [
          File["${mod}.conf"],
          Exec["mkdir ${enable_dir}"],
        ],
        before  => File[$enable_dir],
        notify  => Service['httpd'],
      }
    }
  }
}
