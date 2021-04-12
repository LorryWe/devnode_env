# Applied to devnodes hostgroup

class devnode_env (
  Hash $config = {},
)
{

#########################################################
# Generic Stuff

# Setup user
  group { $config[dn_username]:
    ensure => 'present',
    gid    => $config[dn_gid],
  }

  user { $config[dn_username]:
    ensure           => 'present',
    gid              => $config[dn_gid],
    home             => $config[dn_homefolder],
    groups           => $config[dn_groups],
    password         => '!!',
    password_max_age => '99999',
    password_min_age => '0',
    shell            => $config[dn_shell],
    uid              => $config[dn_uid],
    managehome       => true,
  }

# Install packages
  if $config[dn_packages] {
    package { $config[dn_packages]:
      ensure => 'installed',
    }
  }

#########################################################	

# Application Upgrade Test
##########################
  if $config[perform_app_upgrade] {
  # Uninstall old package
    package { 'uninstall_old_package':
      ensure => 'purged',
      name   => $config['app_upgrade_package_uninstall'],
      before => Package['install_new_package'],
    }

  # Install new package
    package { 'install_new_package':
      ensure => 'installed',
      name   => $config['app_upgrade_package_install'],
      notify => Exec['run_app_installer'],
    }

  # Run App installer only run after install new package
    exec {'run_app_installer':
      command     => '/usr/bin/cp /etc/.deviceID_old_id /etc/.deviceID_installed',
      onlyif      => '/bin/test -f /etc/.deviceID_old_id',
      creates     => '/etc/.deviceID_installed',
      refreshonly => true,
      notify      => Exec['update_app_id'],
    }

  # Update application id only run after run_app_installer
    exec {'update_app_id':
      command     => '/usr/bin/cp /etc/.deviceID_installed /etc/.deviceID_updated',
      onlyif      => '/bin/test -f /etc/.deviceID_installed',
      creates     => '/etc/.deviceID_updated',
      refreshonly => true,
    }

  # Get old application id
    exec {'get_old_app_id':
      command => '/usr/bin/cp /root/deviceID_orig_id /etc/.deviceID_old_id',
      onlyif  => '/bin/test -f /root/deviceID_orig_id',
      creates => '/etc/.deviceID_old_id',
      before  => Package['uninstall_old_package'],
    }
  }
}

