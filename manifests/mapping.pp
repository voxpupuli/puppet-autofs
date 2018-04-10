# Define autofs::mapping
#
# Defined type to manage a single filesystem mapping in a single map file.
# When ensured 'present', a autofs::mapfile resource managing the overall
# target map file must also be present in the catalog.  This resource
# implements Autofs's 'sun' map format, which is the default.
#
# It is not supported to declare multiple autofs::mappings with the
# same key, targetting the same map file, and ensured 'present'.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @param ensure Whether the mapping should be present in the target mapfile;
#     ensuring 'absent' is not meaningfully different from omitting the
#     resource declaration altogether
# @param fs the remote filesystem to mount
# @param key the autofs key for this mappingr. For indirect maps it is the
#     basename of the mountpoint directory for $fs (not to be confused with
#     an _autofs_ mount point, which is the parent directory).  For direct
#     maps it is the absolute path to the mountpoint directory.
# @param mapfile the absolute path to the file containing the Autofs map
#     to which this mapping belongs
# @param options a comma-delimited mount options string or an array of
#     individual mount options; neither individual options nor the overall
#     option list should be specified with a leading hyphen (-); that is
#     part of the map file format, not of the options themselves, and
#     it is provided by this resource
# @param order an integer describing the relative order of the mapping
#     represented by this resource within the target map file (default 10).
#     The order matters only if the same kay is enrolled more than once
#     in the map, in which case only the first is effective.
#
# @example Options given as a string
#   autofs::mapping{ '/etc/auto.data_data':
#     mapfile => '/etc/auto.data',
#     key     => 'data',
#     options => 'rw,sync,suid',
#     fs      => 'storage_host.my.com:/path/to/data'
#  }
#
# @example Options given as an array
#   autofs::mapping{ '/etc/auto.data_data':
#     mapfile => '/etc/auto.data',
#     key     => 'data',
#     options => ['ro', 'noexec', 'nodev'],
#     fs      => 'storage_host.my.com:/path/to/data'
#  }
#
# @example No options
#   autofs::mapping{ '/etc/auto.data_data':
#     mapfile => '/etc/auto.data',
#     key     => 'data',
#     fs      => 'storage_host.my.com:/path/to/data'
#  }
#
define autofs::mapping (
  Stdlib::Absolutepath $mapfile,
  Pattern[/\A\S+\z/] $key,
  Pattern[/\S/] $fs,
  Enum['present', 'absent'] $ensure  = 'present',
  Optional[Autofs::Options] $options = undef,
  Integer $order                     = 10,
) {
  unless $ensure == 'absent' {
    # Format the options string, relying to some extent on the
    # $options parameter, if specified, to indeed match the
    # Autofs::Options data type
    if ($options =~ Undef) or ($options =~  Array[Any,0,0]) { # an empty array
      $formatted_options = ''
    } else {
      $prelim_options = $options ? {
        Array   => join($options, ','),  # a non-empty array
        String  => $options,
        default => fail('Unexpected value for parameter $options')
      }
      $formatted_options = $prelim_options ? {
        # even though the user *shouldn't* provide the hyphen, we accommodate
        # them doing so.  But only at the head of the option list, not
        # internally.
        /\A-/   => $prelim_options,
        default => "-${prelim_options}",
      }
    }

    # Declare an appropriate fragment of the target map file
    concat::fragment { "autofs::mapping/${title}":
      target  => $mapfile,
      content => "${key}	${formatted_options}	${fs}\n",
      order   => $order,
    }
  }
}
