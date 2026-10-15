# @summary Format an Autofs::Key value for use in a sun format map entry.
#
# Accepts a map key string and returns it properly escaped and quoted
# if it contains whitespace or quotes, suitable for inclusion in a sun
# format map entry.
#
# @param key the key to format
#
# @return [String] the formatted key string
#
function autofs::format_key(String[1] $key) >> String {
  if $key =~ /[[:blank:]"]/ {
    String($key, '%#p')
  } else {
    $key
  }
}
