open Types

val make_tape : 'a -> 'a list -> 'a tape
val tape_of_str: char -> string -> char tape
val write : 'a tape -> 'a -> 'a tape
val move : 'a tape -> direction -> 'a tape
val print_tape : char tape -> unit
val count : 'a -> 'a tape -> int
