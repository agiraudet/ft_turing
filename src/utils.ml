let charlist_of_string str =
  str |> String.to_seq |> List.of_seq

let rev list =
  let rec aux acc = function
    | [] -> acc
    | h :: t -> aux (h :: acc) t
  in
  aux [] list

let print_color c = 
  let inverse = "\027[7m" in
  let reset = "\027[0m" in
  Printf.printf "%s%c%s" inverse c reset

let char_of_string s =
  if String.length s = 1 then s.[0]
  else failwith "Expected a single character string"
