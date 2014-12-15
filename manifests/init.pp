# = Class: autofs
#
# Manages autofs mount points
#
# This class includes defined types for looping through arrays of configuration
# file names.
#
# Requires the use of environments and hieradata.
#

class autofs {
  anchor { 'autofs::begin': }
  class { 'autofs::install': } ->
  class { 'autofs::config': } ~>
  class { 'autofs::service': }
  anchor { 'autofs::end': }
}
