# @summary Format an Autofs::Fs value for use in a sun format map entry.
#
# Accepts a filesystem specification as a string or an array of such strings,
# and returns a properly escaped and quoted string suitable for inclusion
# in a sun format map entry.
#
# @param fs the filesystem specification(s) to format
#
# @return [String] the formatted filesystem string
#
function autofs::format_fs(Variant[String[1], Array[String[1]]] $fs) >> String {
  [$fs].flatten.map |$value| {
    if $value =~ /[[:blank:]"]/ {
      "\"${value.regsubst(/\\/, '\\\\', 'G').regsubst(/"/, '\"', 'G')}\""
    } else {
      $value
    }
  }.join(' ')
}
