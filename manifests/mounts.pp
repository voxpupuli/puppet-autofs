# Class: autofs::mounts
#
# Class used specifically to pass hiera autolookups as a hiera_hash
# to the autofs::mount defined type.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
class autofs::mounts {
  deprecation('autofs::mounts', 'Calling autofs::mounts is deprecated and will be removed in a future release.')
}
