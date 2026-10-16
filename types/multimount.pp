# A single filesystem of a multi-mount map entry, as described under
# "Multiple Mounts" in autofs(5).  A multi-mount entry lists several
# filesystems under one map key; a single lookup mounts them all, each at its
# own relative mount point, the per-mountpoint options (if any) appended to the
# entry's default options.
#
# The type is named 'Autofs::Multimount' rather than 'Autofs::Mount' because
# Puppet resolves the name 'Autofs::Mount' to the built-in 'mount' resource
# type instead of a custom type, so the latter name cannot be declared.
#
# "Accept as-is": a specified mountpoint is written to the map verbatim, so it
# begins with '/' (for example '/docs' or, for the automount point itself,
# '/').  Omit it to mount the first filesystem at the automount point itself.
#
# @example Mount at a subdirectory with its own options
#   { 'mountpoint' => '/docs', 'options' => 'ro', 'fs' => 'nfs1:/d2' }
#
# @example Mount at the automount point (offset omitted)
#   { 'mountpoint' => undef, 'fs' => 'nfs1:/d1' }
#
type Autofs::Multimount = Struct[
  {
    mountpoint => Optional[String[1]],
    options    => Optional[Autofs::Options],
    fs         => String[1],
  }
]
