# A type representing an autofs options list, represented either as a single
# non-empty string or an array of such strings
#
type Autofs::Options = Variant[Pattern[/\A\S+\z/], Array[Pattern[/\A\S+\z/]]]

