# This type matches a map type and path.
# @example program:/etc/auto.smb
# @example file:/etc/auto.file

type Autofs::Mapentry = Pattern[/^[a-z]+:\/([^\/\0]+(\/)?)+$/]

