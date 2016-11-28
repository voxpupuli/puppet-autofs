# Class: autofs::mounts
#
# Class used specifically to pass hiera autolookups as a hiera_hash
# to the autofs::mount defined type.
#
# @see autofs
#
# @example using autofs::mounts class with hiera
#    ---
#    autofs::mounts:
#      home:
#        mount: '/home'
#        mapfile: '/etc/auto.home'
#        mapcontents:
#          - '* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'
#        options: '--timeout=120'
#        order: 01
#
# @param mount Passes hiera values as a hash to the autofs::mount defined type
#   using the create_resources function.
#
class autofs::mounts() {
  $mount = hiera_hash('autofs::mounts', [])

  create_resources('autofs::mount', $mount)
}
