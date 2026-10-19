# @api private
#
# @summary Ensure an autofs drop-in map directory exists.
#
# Shared implementation behind autofs::mount (use_dir) and
# autofs::add_master_entry (ensure_dir).  Multiple resources may name the same
# directory; ensure_resource collapses them into a single File resource while
# keeping each caller's dependency edges intact.
#
# @see autofs::mount
# @see autofs::add_master_entry
#
# @param path Absolute path of the directory to ensure.  (default: the title
#   of this resource)
# @param purge When true, files present in the directory that are not declared
#     elsewhere in the catalog are removed.  Defaults to autofs::purge_map_dir.
# @param recurse When true, purging recurses into unmanaged subdirectories.
#     Defaults to autofs::purge_map_dir.
#
define autofs::mapdir (
  Stdlib::Absolutepath $path = $title,
  Boolean $purge   = $autofs::purge_map_dir,
  Boolean $recurse = $autofs::purge_map_dir,
) {
  ensure_resource('file', $path,
    {
      ensure  => directory,
      owner   => $autofs::map_file_owner,
      group   => $autofs::map_file_group,
      mode    => $autofs::map_dir_mode,
      purge   => $purge,
      recurse => $recurse,
    }
  )
}
