define rbenv::install(
  $user  = $title,
  $group = $user,
  $home  = '',
  $root  = '',
  $rc    = '.profile'
) {

  # Workaround http://projects.puppetlabs.com/issues/9848
  $home_path = $home ? { '' => "/home/${user}", default => $home }
  $root_path = $root ? { '' => "${home_path}/.rbenv", default => $root }

  $rbenvrc = "${home_path}/.rbenvrc"
  $shrc  = "${home_path}/${rc}"

  if ! defined( Class['rbenv::dependencies'] ) {
    require rbenv::dependencies
  }

  vcsrepo { $root_path:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/sstephenson/rbenv.git',
    user     => $user,
    group    => $group,
  }

  file { "rbenv::rbenvrc ${user}":
    path    => $rbenvrc,
    owner   => $user,
    group   => $group,
    content => template('rbenv/dot.rbenvrc.erb'),
    require => Vcsrepo[$root_path],
  }

  exec { "rbenv::shrc ${user}":
    command => "echo 'source ${rbenvrc}' >> ${shrc}",
    user    => $user,
    group   => $group,
    unless  => "grep -q rbenvrc ${shrc}",
    path    => ['/bin', '/usr/bin', '/usr/sbin'],
    require => File["rbenv::rbenvrc ${user}"],
  }

  file { "rbenv::cache-dir ${user}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    path    => "${root_path}/cache",
    require => Vcsrepo[$root_path],
  }
}
