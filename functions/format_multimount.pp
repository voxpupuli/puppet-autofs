# @summary Format the location portion of a multi-mount map entry.
#
# Renders an ordered list of mount specs as the space-separated sequence of
# tokens autofs expects after the entry's default options, as described under
# "Multiple Mounts" in autofs(5):
#
#   [mountpoint] [ -options ] source [mountpoint] [ -options ] source ...
#
# A mount's mountpoint is emitted verbatim (it begins with '/'); an omitted
# mountpoint produces no token, so the filesystem mounts at the automount
# point itself.  Per-mountpoint options (already hyphenated here) appear
# between the mountpoint and the source.
#
# The mount-spec type is named 'Autofs::Multimount' (see types/multimount.pp)
# rather than 'Autofs::Mount', because Puppet resolves that name to the
# built-in 'mount' resource type instead of a custom type.
#
# @param mounts the ordered list of filesystems to mount under one key
#
# @return [String] the location portion of the map entry
#
function autofs::format_multimount(
  Array[Autofs::Multimount] $mounts,
) >> String {
  $segments = $mounts.map |$m| {
    $source = autofs::format_fs($m['fs'])
    $mpo    = autofs::format_options($m['options'])
    $mp     = $m['mountpoint']

    # Assemble the tokens in canonical order (mountpoint, options, source) and
    # drop any that are unspecified.  'filter' removes both the undef produced
    # by an omitted mountpoint and the empty string produced by an omitted
    # option set, so only specified values remain, with no leading space.
    $tokens = [
      $mp,
      $mpo,
      $source,
    ].filter |$t| { $t =~ String[1] }

    join($tokens, ' ')
  }

  join($segments, ' ')
}
