open Utils 
open Types

let make_tape blank = function
  | [] -> {left = []; current = blank; blank = blank; right = []}
  | u::v -> {left = []; current = u; blank = blank; right = v}

let tape_of_str blank str = 
  let check_char c =
    if c = blank then
      raise (InvalidInput ("No blanks are allowed on the input tape"))
  in
  let chr_lst = charlist_of_string str in 
  List.iter check_char chr_lst;
  make_tape blank chr_lst

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
  print_color_char Inverted tape.current;
  print_lst tape.right;
  print_char '\n'

let count c tape = 
  let add_t a b =
    let (a1, a2) = a in
    let (b1, b2) = b in
    (a1+b1, a2+b2)
  in
  let rec acc n t = function
  | [] -> (n, t)
  | u::v ->
  if u = c then
    acc (n+1) (t+1) v
  else
    acc n (t+1) v
  in
  let cur = ((if tape.current = c then 1 else 0), 1) in
  let (nc, nt) = add_t cur (acc 0 0 (tape.right@tape.left)) in
  if nt > 10 then
    begin
    nc * 100 / nt
      end
  else
    0
