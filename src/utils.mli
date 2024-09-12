open Types

val charlist_of_string : string -> char list
val rev : 'a list -> 'a list
val print_color_char : color -> char -> unit
val print_color_str : color -> string -> unit
val char_of_string : string -> char
val mk_string : int -> string -> string
val ansi_of_color : color -> string
