# @summary Format an Autofs::Options value for use in a sun format map entry.
#
# Accepts undef, an empty array, a single non-empty options string, or an
# array of such strings, and returns a leading-hyphen options string
# suitable for inclusion in a sun format map entry.  The hyphen is part of
# the map file format, not of the options themselves, so it is supplied
# here.
#
# @param options the options to format
#
# @return [String] the formatted options string, possibly empty
#
function autofs::format_options(Optional[Autofs::Options] $options) >> String {
  if ($options =~ Undef) or ($options =~ Array[Any,0,0]) { # undef or an empty array
    ''
  } else {
    if $options =~ Array {
      $prelim_options = join($options, ',')  # a non-empty array
    } else {
      $prelim_options = $options             # a string
    }
    # even though the user *shouldn't* provide the hyphen, we accommodate
    # them doing so.  But only at the head of the option list, not
    # internally.
    if $prelim_options =~ /\A-/ {
      $prelim_options
    } else {
      "-${prelim_options}"
    }
  }
}
