# This type matches a map type and path.
# @example program:/etc/auto.smb
# @example file:/etc/auto.file
# @example hosts:-hosts

type Autofs::Mapentry = Pattern[/^[a-z]+:\/([^\/\0]+(\/)?)+$|^-hosts$/]
