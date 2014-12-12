# = Class: autofs::config
#
# Creates /automount directory and, if used, the automount directory and links
# for automount home directories
#
# Requires the use of environments and hieradata.
# Requires Hiera YAML backend and File backend.
#
# == Variables:
#
# [$autofs_homedir]
#   Set to "yes" or "no" in the hieradata *.yml file. This tells the module if
#   that the home directory is being mounted from automount. If autofsHomeDir in
#   the yaml file is set to "yes", then the /automount/home directory and
#   symlink from /home to /automount/home will be created. If autofsHomeDir is
#   set to "no" then /automount/home a symlink to /home will not be created.
#
# [$auotfs_conf_files]
#   This is a yaml array of autofs configuration files. Add the array to your
#   yaml file under autofsConfFiles. When the autofs::autofiles defined type is
#   called, the defined type will "loop" through the array, creating the files
#   list. The files will be expected to be stored in the Hiera File Backend.
#
# [$audofs_mnt_dir]
#   This references a yaml array in hiera that lists the parent mount
#   directories for each autofs config file. Ensure that the directory that the
#   autofsConfFiles are mounting to is in this array, otherwise those
#   directories will not be created.
#

class autofs::config {
  $autofs_homedir        = hiera('autofsHomeDir')
  $autofs_conf_files     = hiera('autofsConfFiles')
  $autofs_mnt_dir        = hiera('autofsMntDir')

  File {
    owner => 'root',
    group => 'root',
    mode  => '0755'
  }

  file { '/automount':
    ensure => directory
  }

  case $autofs_homedir {
    yes: {
      file { '/automount/home':
      ensure  => directory,
      require => File[ '/automount' ]
      }

      file { '/home':
      ensure  => link,
      target  => '/automount/home',
      force   => true,
      require => File[ '/automount/home' ]
      }
    }
    no: {
      file { '/automount/home':
        ensure => absent
      }
    }
    default: {
      fail("String ${autofs_homedir} is not supported!")
    }
  }

  autofs::mount { $autofs_mnt_dir: }
  autofs::autofiles { $autofs_conf_files: }


}
