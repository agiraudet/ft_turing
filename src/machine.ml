open Types
open Tape

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
    if not (List.mem c machine.alphabet) then
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
