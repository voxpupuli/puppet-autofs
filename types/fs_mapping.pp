# A type representing a single filesystem mapping, relative to the
# context provided by an (unspecified) autofs map.  "Single" refers to
# a single _key_, but not necessarily a single mounted filesystem. Autofs
# has the concept of a multi-mount, where the map specifies multiple
# filesystems to mount via a single key, and the concept of shared mounts,
# where multiple keys reference subdirectories of a single (auto-)mounted
# file system.  This type simply provides for a generic representation of
# all those alternatives via the 'fs' member.
#
# @example Typical mapping for an indirect map
# { 'key' => 'data', 'options' => 'rw,sync', 'fs' => 'fs.host.com:/path/to/data' }
#
# @example Mapping for a direct map, demonstrating also that the options may be omitted
# { 'key' => '/path/to/mnt', fs => 'remote.org:/exported/path' }
#
# @example Demonstrating specifying an array of options
# { 'key' => 'other', 'options' => [ 'ro', 'noexec' ], 'fs' => 'external.net:/the/exported/fs' }
#
type Autofs::Fs_mapping = Struct[{
  key        => Pattern[/\A\S+\z/],
  options    => Optional[Autofs::Options],
  fs         => Pattern[/\S/]  # contains at least one non-whitespace character
}]
