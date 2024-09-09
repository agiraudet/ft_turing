open Types

exception JsonError of string

val machine_of_json_file : string -> string -> machine
