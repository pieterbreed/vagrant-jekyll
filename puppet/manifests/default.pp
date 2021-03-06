$as_vagrant   = 'sudo -u vagrant -H bash -l -c'
$home         = '/home/vagrant'

Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

# --- Preinstall Stage ---------------------------------------------------------

stage { 'preinstall':
  before => Stage['main']
}

class apt_get_update {
  exec { 'sudo apt-get -y update':
    unless => "test -e ${home}/.rvm"
  }
}
class { 'apt_get_update':
  stage => preinstall
}

# --- SQLite -------------------------------------------------------------------

package { ['sqlite3', 'libsqlite3-dev']:
  ensure => installed;
}

# --- MySQL --------------------------------------------------------------------

# class install_mysql {
#   class { 'mysql': }

#   class { 'mysql::server':
#     config_hash => { 'root_password' => '' }
#   }

#   package { 'libmysqlclient15-dev':
#     ensure => installed
#   }
# }
# class { 'install_mysql': }

# --- PostgreSQL ---------------------------------------------------------------

# class install_postgres {
#   class { 'postgresql': }

#   class { 'postgresql::server': }

#   package { 'libpq-dev':
#     ensure => installed
#   }
# }
# class { 'install_postgres': }

# --- Packages -----------------------------------------------------------------

package { 'curl':
  ensure => installed
}

package { 'build-essential':
  ensure => installed
}

package { 'git-core':
  ensure => installed
}

# Nokogiri dependencies.
package { ['libyaml-dev', 'libxml2', 'libxml2-dev', 'libxslt1-dev']:
  ensure => installed
}

# ExecJS runtime.
package { 'nodejs':
  ensure => installed
}

# --- Ruby ---------------------------------------------------------------------

exec { 'install_rvm':
  command => "${as_vagrant} 'curl -k -L https://get.rvm.io | bash -s stable'",
  creates => "${home}/.rvm",
  require => Package['curl']
}

exec { 'install_ruby':
  command => "${as_vagrant} '${home}/.rvm/bin/rvm install 2.0.0 --autolibs=enabled'",
  creates => "${home}/.rvm/bin/ruby",
  timeout => 600,
  require => [ Package['libyaml-dev'], Exec['install_rvm'] ]
}

exec { 'set_default_ruby': 
  command => "${as_vagrant} '${home}/.rvm/bin/rvm --fuzzy alias create default 2.0.0 && ${home}/.rvm/bin/rvm use default'",
  require => Exec['install_ruby']
}

file { 'set_gem_ignore_ssl':
  path    => "${home}/.gemrc",
  ensure  => present,
  mode    => 0664,
  content => ":ssl_verify_mode: 0",
}

exec { 'install jekyll':
  command => "${as_vagrant} 'gem install jekyll less'",
  require => [Exec['set_default_ruby'], File['set_gem_ignore_ssl']]
}

exec { 'install_bundler':
  command => "${as_vagrant} 'gem install bundler --no-rdoc --no-ri'",
  creates => "${home}/.rvm/bin/bundle",
  require => Exec['set_default_ruby']
}