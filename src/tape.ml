open Utils 
open Types

let make_tape blank = function
  | [] -> {left = []; current = blank; blank = blank; right = []}
  | u::v -> {left = []; current = u; blank = blank; right = v}

let tape_of_str blank str = 
  make_tape blank @@ charlist_of_string str

let write tape c = 
  { tape with current = c}

let move tape direction = 
  let move_left tape = 
    match tape.left with
    | [] -> { tape with right = tape.current::tape.right ; current = tape.blank}
    | u::v -> { tape with left = v; current = u; right = tape.current::tape.right}
  in
  let move_right tape = 
    match tape.right with
    | [] -> {tape with left = tape.current::tape.left ; current = tape.blank}
    | u::v -> { tape with left = tape.current::tape.left ; current = u; right = v}
  in
  match direction with
  | Left -> move_left tape
  | Right -> move_right tape

let print_tape tape = 
  let rec print_lst = function
    [] -> ()
  | u::v -> print_char u; print_lst v
  in
  print_lst @@ rev tape.left;
  print_color tape.current;
  print_lst tape.right;
  print_char ' '
