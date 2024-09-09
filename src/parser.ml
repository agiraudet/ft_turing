open Utils
open Types
open Tape
open Yojson.Basic.Util

exception JsonError of string

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

