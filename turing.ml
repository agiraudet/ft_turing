open Yojson.Basic.Util
open Sys
open Arg

module StringMap = Map.Make(String)
module CharMap = Map.Make(Char)
module StringSet = Set.Make(String)

exception InfLoop of string
exception NeverHalts of string
exception InvalidState of string
exception InvalidInput of string

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
  name: string;
  alphabet: char list;
  state_list: string list;
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
  print_char ' '


let step machine =
  match StringMap.find_opt machine.state machine.transition_map with
  | None -> raise (InvalidState ("State " ^ machine.state ^ " does not have a definition"))
  | Some action_map ->
    match CharMap.find_opt machine.tape.current action_map with
    | None -> raise (InvalidState ( "State " ^ machine.state ^ " does not have a definition for " ^ (String.make 1 machine.tape.current)))
    | Some act -> {machine with 
        tape = move (write machine.tape act.write) act.direction;
        state = act.to_state}

let examine machine = 
  print_tape machine.tape;
  print_endline machine.state; 
  machine

let check_bounds machine = 
  (* if your current state, when reading a blank character, transition into the same state, 
  and move you in a direction where the tape is empty, then you would only ever read blanks,
  and thus stay in that state and keep going forever *)
  match StringMap.find_opt machine.state machine.transition_map with
  | None -> raise (InvalidState ("Current state " ^ machine.state ^ " doesnt have a definition"))
  | Some current_state ->
    let action = CharMap.find_opt machine.tape.current current_state in
    match action with
    | None -> raise (InvalidState (machine.state ^ " encountered not planned case: " ^ (String.make 1 machine.tape.current)))
    | Some act ->
      let dir_tape = if act.direction = Right then machine.tape.right else machine.tape.left in
      if machine.tape.current = machine.tape.blank &&  dir_tape = [] && act.to_state = machine.state then
        raise (InvalidState (machine.state ^ " will now only be able to transition to itself"))
      else
        machine

let run machine =
  (* We really should keep trace only of a set number of previous states to have a limit on the ressource usage.
  That would mean inability to detect complex loops though.
  Since we wont run complex enough algo making this an issue in evaluation context, strict correctness is preferable here*)
  let rec aux machine prev_states =
    if List.mem machine.state machine.halting_state then
      machine
    else if List.mem machine prev_states then
      begin
      ignore @@ examine machine;
      raise (InfLoop ("This exact state happened before, the machine will loop forever"));
      end
    else
      aux (step (check_bounds (examine machine))) (machine::prev_states)
  in
  aux machine []


(* JSON PARSING *)

exception JsonError of string


let validate_states machine =
  let {state_list; alphabet; transition_map; _ } = machine in
  let state_exists state = 
    List.mem state state_list
in
StringMap.iter (fun from_state action_map ->
    CharMap.iter (fun read_symbol action ->
      if not (state_exists action.to_state) then
        raise (InvalidState ("State '" ^ action.to_state ^ "' in transition from state '" ^ from_state ^
                             "' on symbol '" ^ String.make 1 read_symbol ^ "' is not in states list"))
      else if not (List.mem read_symbol alphabet) then
        raise (InvalidState ("State " ^ from_state ^ " read for char " ^ String.make 1 read_symbol ^ " (outside of alphabet)" ))
    ) action_map
) transition_map;
machine

let validate_halt machine = 
  let rec has_common_elems lst = function
    | [] -> false
    | u::v -> if List.mem u lst then true else has_common_elems lst v
  in
  let {halting_state; transition_map; _ } = machine in
  let possible_states = ref  StringSet.empty in
  StringMap.iter (fun _ action_map -> 
    CharMap.iter (fun _ action ->
      possible_states := StringSet.add action.to_state !possible_states
    ) action_map
  ) transition_map;
  if has_common_elems halting_state (StringSet.elements !possible_states) then
    machine
  else
    raise (NeverHalts ("No transition lead to a halting state"))

  let validate_input machine = 
    let check_char c =
      if not (List.mem c machine.alphabet) then
        raise (InvalidInput (String.make 1 c ^ " is outside of alphabet"))
    in
    List.iter check_char machine.tape.right;
    check_char machine.tape.current;
    machine

let validate machine = 
  validate_input @@ validate_halt @@  validate_states machine

let safe_member json key parse_fn =
try
  parse_fn (json |> member key)
 with 
| Yojson.Basic.Util.Type_error (msg, json_part) ->
      raise (JsonError ("Type error in member '" ^ key ^ "': " ^ msg))
  | Yojson.Basic.Util.Undefined (msg, _) ->
      raise (JsonError ("Undefined error in member '" ^ key ^ "': " ^ msg))
  | _ ->
      raise (JsonError ("Error accessing or parsing '" ^ key ^ "'"))

let char_of_string s =
  if String.length s = 1 then s.[0]
  else failwith "Expected a single character string"

let parse_transition json =
  let read = safe_member json "read" (fun m -> m |> to_string |> char_of_string) in
  let to_state = safe_member json "to_state" to_string in
  let write = safe_member json "write" (fun m -> m |> to_string |> char_of_string) in
  let action = safe_member json "action" to_string in
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
  let name = safe_member json "name" to_string in
  let alphabet = safe_member json "alphabet" (fun m -> m |> to_list |> List.map  to_string |> List.map char_of_string) in
  let state_list = safe_member json "states" (fun m -> m |> to_list |> List.map to_string) in
  let blank = safe_member json "blank" (fun m -> m |> to_string |> char_of_string) in
  let init_state = safe_member json "initial" to_string in
  let halt_state = safe_member json "finals" (fun m -> m |> to_list |> List.map to_string) in
  let transition_map = safe_member json "transitions" parse_transition_map in
  {
    name = name;
    alphabet = alphabet;
    state_list = state_list;
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
  else try
    let machine =  validate @@ machine_of_json_file Sys.argv.(1) Sys.argv.(2) in
    let final_machine = run machine in
    ignore @@ examine final_machine;
  with
    | Sys_error msg -> prerr_endline ("Please check your inpupts: " ^ msg ); exit 1
    | JsonError msg -> prerr_endline ("Ill formated JSON file: " ^ msg) ; exit 1
    | Yojson.Json_error msg -> prerr_endline ("JSON Structure Error: " ^ msg) ; exit 1
    | NeverHalts msg | InvalidState msg -> prerr_endline ("Invalid Machine: " ^ msg) ; exit 1
    | InfLoop msg -> prerr_endline ("Execution error: " ^ msg); exit 1
    | InvalidInput msg -> prerr_endline ("Input error: " ^ msg); exit 1
