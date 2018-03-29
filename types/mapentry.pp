# This type matches a map specfication with map type and optional format,
# or the built-in -hosts map.
# @example program:/etc/auto.smb
# @example file:/etc/auto.file
# @example file,sun:/etc/auto.file
# @example yp:mnt.map
# @example -hosts

type Autofs::Mapentry = Pattern[/\A([a-z]+(,[a-z]+)?:\S+|-hosts)\z/]
