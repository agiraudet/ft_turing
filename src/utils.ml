open Types

let charlist_of_string str =
  str |> String.to_seq |> List.of_seq

let rev list =
  let rec aux acc = function
    | [] -> acc
    | h :: t -> aux (h :: acc) t
  in
  aux [] list

let ansi_of_color color =
  match color with
  | Black -> "\027[30m"
  | Red -> "\027[31m"
  | Green -> "\027[32m"
  | Yellow -> "\027[33m"
  | Blue -> "\027[34m"
  | Magenta -> "\027[35m"
  | Cyan -> "\027[36m"
  | White -> "\027[37m"
  | BrightBlack -> "\027[90m"
  | BrightRed -> "\027[91m"
  | BrightGreen -> "\027[92m"
  | BrightYellow -> "\027[93m"
  | BrightBlue -> "\027[94m"
  | BrightMagenta -> "\027[95m"
  | BrightCyan -> "\027[96m"
  | BrightWhite -> "\027[97m"
  | Default -> "\027[39m"
  | Inverted -> "\027[7m"
  | Reset -> "\027[0m"

let print_color_char color c = 
  Printf.printf "%s%c%s" (ansi_of_color color) c (ansi_of_color Reset)

let print_color_str color s = 
  Printf.printf "%s%s%s" (ansi_of_color color) s (ansi_of_color Reset)

let char_of_string s =
  if String.length s = 1 then s.[0]
  else failwith "Expected a single character string"

let mk_string len str = 
  let rec aux len acc =
  if len > 0 then
    aux (len-1) (acc ^ str)
  else
    acc
  in aux len ""

