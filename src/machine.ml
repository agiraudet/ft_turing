open Types
open Tape
open Utils

exception InfLoop of string
exception NeverHalts of string
exception InvalidState of string
exception InvalidInput of string

module StringSet = Set.Make(String)

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
    if c = machine.tape.blank then
      raise (InvalidInput ("No blanks are allowed on the input tape"))
    else if not (List.mem c machine.alphabet) then
      raise (InvalidInput (String.make 1 c ^ " is outside of alphabet"))
  in
  List.iter check_char machine.tape.right;
  check_char machine.tape.current;
  machine

let validate machine = 
  validate_input @@ validate_halt @@  validate_states machine

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
  let str = machine.state in
  let max_len = List.fold_left (fun acc s -> max acc (String.length s)) 0 machine.state_list in
  let padding = max_len - String.length str in
  let left_pad = padding / 2 in
  let right_pad = padding - left_pad in
  Printf.printf "[%*s" left_pad "";
  print_color_str Green str;
  Printf.printf "%*s] " right_pad "";
  print_tape machine.tape;
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
      examine machine
    else if List.mem machine prev_states then
      begin
      ignore @@ examine machine;
      raise (InfLoop ("This exact state happened before, the machine will loop forever"));
      end
    else if ((not @@ List.is_empty prev_states) && (List.length (machine.tape.left@machine.tape.right) > List.length (let old = List.hd prev_states in old.tape.left@old.tape.right)) && (count machine.tape.blank machine.tape) > 75) then
      raise (InfLoop ("The halting problem tells us we cannot be sure, but this machine looks awfully likes its looping forever"))
    else
      aux (step (check_bounds (examine machine))) (machine::prev_states)
  in
  aux machine []

let estimate_complexity (machines: machine list) : complexity_estimate * int * int * int * int =
  let state_data = ref StringMap.empty in
  let tape_length = ref 1 in
  let steps = List.length machines - 1 in (* Subtract 1 to exclude initial state *)
  let tape_position tape =
    List.length tape.left
  in
  List.iteri (fun i m ->
    let pos = tape_position m.tape in
    tape_length := max !tape_length (pos + 1 + List.length m.tape.right);
    let data = match StringMap.find_opt m.state !state_data with
      | Some d -> { visits = d.visits + 1; tape_positions = pos :: d.tape_positions }
      | None -> { visits = 1; tape_positions = [pos] }
    in
    state_data := StringMap.add m.state data !state_data
  ) machines;
  let max_visits = StringMap.fold (fun _ data acc -> max acc data.visits) !state_data 0 in
  let unique_states = StringMap.cardinal !state_data in
  let estimate = 
    if steps > 1000000 then Infinite
    else if max_visits > !tape_length * 2 then Exponential
    else if max_visits > !tape_length then Quadratic
    else if unique_states > !tape_length / 2 then Linear
    else Constant
  in
  (estimate, steps, !tape_length, max_visits, unique_states)

let complexity_to_string = function
  | Constant -> "O(1)"
  | Linear -> "O(n)"
  | Quadratic -> "O(n^2)"
  | Exponential -> "O(2^n)"
  | Infinite -> "Potentially infinite"

let run_and_analyze machine =
  let rec aux machine nstep prev_states =
    if List.mem machine.state machine.halting_state then
      (List.rev ((examine machine):: prev_states), nstep)
    else if List.mem machine prev_states then
      begin
      ignore @@ examine machine;
      raise (InfLoop ("This exact state happened before, the machine will loop forever"));
      end
    else if ((not @@ List.is_empty prev_states) && (List.length (machine.tape.left@machine.tape.right) > List.length (let old = List.hd prev_states in old.tape.left@old.tape.right)) && (count machine.tape.blank machine.tape) > 75) then
      raise (InfLoop ("The halting problem tells us we cannot be sure, but this machine looks awfully like it's looping forever"))
    else
      aux (step (check_bounds (examine machine))) (nstep+1) (machine :: prev_states)
  in
  let (machine_states, steps) = aux machine 0 [] in
  let (complexity, steps, tape_length, max_visits, unique_states) = estimate_complexity machine_states in
  print_color_str BrightCyan (mk_string ((String.length machine.name) + 6) "═");
  print_newline ();
  Printf.printf "%sTime complexity:%s %s\n" (ansi_of_color BrightCyan) (ansi_of_color Reset) (complexity_to_string complexity);
  Printf.printf "%sTotal steps:%s %d\n" (ansi_of_color BrightCyan) (ansi_of_color Reset) steps;
  Printf.printf "%sMaximum tape length:%s %d\n" (ansi_of_color BrightCyan) (ansi_of_color Reset) tape_length;
  Printf.printf "%sMaximum visits to a single state:%s %d\n" (ansi_of_color BrightCyan) (ansi_of_color Reset) max_visits;
  Printf.printf "%sNumber of unique states visited:%s %d\n" (ansi_of_color BrightCyan) (ansi_of_color Reset) unique_states;
  List.hd @@ List.rev machine_states
