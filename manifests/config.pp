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
  $map_options = hiera('mapOptions')

  file { '/etc/auto.master':
    ensure  => present,
  }

  create_resource( autofs::mount, $map_options)

}
