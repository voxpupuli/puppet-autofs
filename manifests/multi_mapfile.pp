# @summary Defined type to manage autofs map files with a single multi-mount entry
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
# @author Chip Schweiss <chip.schweiss@wustl.edu>
#
# @param ensure Whether the mapfile should be present on the target system
# @param path An absolute path to the map file
# @param mappings an array of mappings to enroll in the file.  Additional
#     mappings can be specified for this mapfile via autofs::mapping resources
# @param replace Whether to replace the contents of any an existing file
#     at the specified path
# @param execute Whether to make the mapfile executable or not
#
define autofs::multi_mapfile (
  Enum['present', 'absent'] $ensure   = 'present',
  Stdlib::Absolutepath $path          = $title,
  Array[Autofs::Fs_mapping] $multi_mappings = [],
  Optional[Autofs::Options] $options  = undef,
  Boolean $replace                    = true,
  Boolean $execute                    = false,
  Pattern[/\A\S+\z/] $root_path,
) {
  include 'autofs'

  unless $autofs::package_ensure == 'absent' {
    if $autofs::reload_command {
      Concat {
        before => Service[$autofs::service_name],
        notify => Exec['automount-reload'],
      }
    } else {
      Concat {
        notify => Service[$autofs::service_name],
      }
    }
  }

  $mapfile_mode = $execute ? {
    true => '0755',
    false => '0644'
  }

  concat { $path:
    ensure  => $ensure,
    owner   => $autofs::map_file_owner,
    group   => $autofs::map_file_group,
    mode    => $mapfile_mode,
    replace => $replace,
    order   => 'numeric',
    require => Class['autofs::package'],
    warn    => template('autofs/mapfile.banner.erb'),
  }

  if $ensure == 'present' {

    # Format the options string, relying to some extent on the
    # $options parameter, if specified, to indeed match the
    # Autofs::Options data type
    if ($options =~ Undef) or ($options =~  Array[Any,0,0]) { # an empty array
      $formatted_options = ''
    } else {
      $prelim_options = $options ? {
        Array   => join($options, ','),  # a non-empty array
        String  => $options,
        default =>  fail('Unexpected value for parameter $options')
      }
      $formatted_options = $prelim_options ? {
        # even though the user *shouldn't* provide the hyphen, we accommodate
        # them doing so.  But only at the head of the option list, not
        # internally.
        ''      => '', 
        /\A-/   => $prelim_options,
        default => "-${prelim_options}",
      }
    }

    concat::fragment { "autofs::multi_mapping/${title}_root-_path":
      target  => "$path",
      content => "${root_path} ${formatted_options} \\\n",
      order   => 0,
    }

    concat::fragment { "autofs::multi_mapping/${title}_endline":
      target  => "$path",
      content => "\n",
      order   => 999999,
    }

    $multi_mappings.each |$mapping| {
      autofs::multi_mapping { "${path}:${mapping[key]}":
        ensure  => 'present',
        mapfile => $path,
        *       => $mapping,
      }
    }
  }
}
