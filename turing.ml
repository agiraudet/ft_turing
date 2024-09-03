open Yojson.Basic.Util
open Sys
open Arg

module StringMap = Map.Make(String)
module CharMap = Map.Make(Char)

type 'a tape = {
  left: 'a list;
  current: 'a;
  blank: 'a;
  right: 'a list;
}

type direction = Left | Right

type action = {
  to_state: string;
  write: char;
  direction: direction;
}

type action_map = action CharMap.t
type transition_map = action_map StringMap.t

type machine = {
  (* name: string; *)
  (* alphabet: char list; *)
  (* state_list: string list; *)
  tape: char tape;
  transition_map: transition_map;
  state: string;
  halting_state: string list;
}

let charlist_of_string str =
  str |> String.to_seq |> List.of_seq

let rev list =
  let rec aux acc = function
    | [] -> acc
    | h :: t -> aux (h :: acc) t
  in
  aux [] list

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

(* let print_color c =  *)
(*   let yellow = "\027[33m" in *)
(*   let reset = "\027[0m" in *)
(*   Printf.printf "%s%c%s" yellow c reset *)

(* let print_color c =  *)
(*   let bold = "\027[1m" in *)
(*   let underline = "\027[4m" in *)
(*   let reset = "\027[0m" in *)
(*   Printf.printf "%s%s%c%s" bold underline c reset *)

let print_color c = 
  let inverse = "\027[7m" in
  let reset = "\027[0m" in
  Printf.printf "%s%c%s" inverse c reset

let print_tape tape = 
  let rec print_lst = function
    [] -> ()
  | u::v -> print_char u; print_lst v
  in
  print_lst @@ rev tape.left;
  print_color tape.current;
  print_lst tape.right;
  print_char '\n'


let step machine =
  match StringMap.find_opt machine.state machine.transition_map with
  | None -> machine
  | Some action_map ->
    match CharMap.find_opt machine.tape.current action_map with
    | None -> machine
    | Some act -> {machine with 
        tape = move (write machine.tape act.write) act.direction;
        state = act.to_state}

let examine machine = 
  (* print_endline machine.state; *)
  print_tape machine.tape;
  (* {machine with state = "HALT"} *)
  machine

let rec run machine =
  if List.mem machine.state machine.halting_state then
    machine
  else
    run @@ step (examine machine)


(* JSON PARSING *)

let char_of_string s =
  if String.length s = 1 then s.[0]
  else failwith "Expected a single character string"

let parse_transition json =
  let read = json |> member "read" |> to_string |> char_of_string in
  let to_state = json |> member "to_state" |> to_string in
  let write = json |> member "write" |> to_string |> char_of_string in
  let action = json |> member "action" |> to_string in
  let direction = if action = "RIGHT" then Right else Left in
  (read, { to_state; write; direction })

let parse_state_transition json = 
  json |> to_list |> List.map parse_transition

let parse_transition_map json =
  json |> to_assoc |> List.fold_left (fun acc (state, transitions) ->
    let action_map = 
      parse_state_transition transitions
      |> List.fold_left (fun map (read, action) -> 
          CharMap.add read action map
        ) CharMap.empty
    in
    StringMap.add state action_map acc
  ) StringMap.empty

let machine_of_json json input = 
  let blank = json |> member "blank" |> to_string |> char_of_string in
  let init_state = json |> member "initial" |> to_string in
  let halt_state = json |> member "finals" |> to_list |> List.map to_string in
  let transition_map = json |> member "transitions" |> parse_transition_map in
  {
    tape = tape_of_str blank input;
    transition_map = transition_map;
    state = init_state;
    halting_state = halt_state;
  }

let machine_of_json_file filename input = 
  let json = Yojson.Basic.from_file filename in
  machine_of_json json input


let () =
  if Array.length Sys.argv <> 3 then
    begin
    Printf.printf "Usage: %s <file.json> <tape_input>\n" Sys.argv.(0);
    exit 1
    end
  else
    let machine =  machine_of_json_file Sys.argv.(1) Sys.argv.(2) in
    let final_machine = run machine in
    print_tape final_machine.tape
