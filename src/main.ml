open Parser
open Machine
open Sys
open Arg
open Utils
open Types

let introduce machine =
  let print_title s =
    print_color_str BrightCyan "╔══";
    print_color_str BrightCyan (mk_string (String.length s) "═");
    print_color_str BrightCyan "══╗\n║  ";
    print_color_str BrightYellow s;
    print_color_str BrightCyan "  ║\n╚══";
    print_color_str BrightCyan (mk_string (String.length s) "═");
    print_color_str BrightCyan "══╝\n"
  in
  let print_list name lst separator =
    print_color_str BrightCyan name;
    print_string ": ";
    List.iteri (fun i x ->
      if i > 0 then print_string separator;
      print_string (String.make 1 x)
    ) lst;
    print_newline ()
  in
  let print_string_list name lst separator =
    print_color_str BrightCyan name;
    print_string ": ";
    List.iteri (fun i s ->
      if i > 0 then print_string separator;
      print_string s
    ) lst;
    print_newline ()
  in
  print_title machine.name;
  print_list "Alphabet" machine.alphabet ", ";
  print_string_list "States" machine.state_list ", ";
  print_string_list "Halting States" machine.halting_state ", ";
  print_color_str BrightCyan "Initial State";
  print_string ": ";
  print_string machine.state;
  print_newline ();
  print_color_str BrightCyan (mk_string ((String.length machine.name) + 6) "═");
  print_newline ();
  machine

let print_error e msg = 
  Printf.eprintf "%s%s:%s %s\n" (ansi_of_color Red) e (ansi_of_color Reset) msg;
  exit 1

(* let () = *)
(*   let input_file = ref "" in *)
(*   let tape_input = ref "" in *)
(*   let show_bigO = ref false in *)
(*   let spec_list = [ *)
(*     ("-b", Arg.Set show_bigO, "Enable bonus feature (show Big O analysis)"); *)
(*     ("--bonus", Arg.Set show_bigO, "Enable bonus feature (show Big O analysis)"); *)
(*   ] in *)
(*   let usage_msg = "Usage: " ^ Sys.argv.(0) ^ " <file.json> <tape_input> [-b|--bonus]" in *)
(*   Arg.parse spec_list (fun arg -> *)
(*     if !input_file = "" then *)
(*       input_file := arg *)
(*     else if !tape_input = "" then *)
(*       tape_input := arg *)
(*     else *)
(*       raise (Arg.Bad "Too many arguments") *)
(*   ) usage_msg; *)
(*   if !input_file = "" || !tape_input = "" then *)
(*     begin *)
(*       Printf.eprintf "%s%s:%s %s\n" (ansi_of_color Red) "Error" (ansi_of_color Reset) "Missing arguments"; *)
(*       Arg.usage spec_list usage_msg; *)
(*       exit 1 *)
(*     end *)
(*   else *)
(*     try *)
(*     begin *)
(*       let machine = introduce @@ validate @@ machine_of_json_file !input_file !tape_input in *)
(*       if !show_bigO then *)
(*         ignore @@ run_and_analyze machine *)
(*       else *)
(*         ignore @@ run machine *)
(*     end *)
(*     with *)
(*       | Sys_error msg -> print_error "Please check your inputs" msg *)
(*       | JsonError msg -> print_error "Ill formatted JSON file" msg *)
(*       | Yojson.Json_error msg -> print_error "JSON Structure Error" msg *)
(*       | NeverHalts msg | InvalidState msg -> print_error "Invalid Machine" msg *)
(*       | InfLoop msg -> print_error "Execution error" msg *)
(*       | InvalidInput msg -> print_error "Input error" msg *)

let () =
  let input_file = ref "" in
  let tape_input = ref None in
  let show_bigO = ref false in
  let spec_list = [
    ("-b", Arg.Set show_bigO, "Enable bonus feature (show Big O analysis)");
    ("--bonus", Arg.Set show_bigO, "Enable bonus feature (show Big O analysis)");
  ] in
  let usage_msg = "Usage: " ^ Sys.argv.(0) ^ " <file.json> <tape_input> [-b|--bonus]" in
  let arg_counter = ref 0 in
  Arg.parse spec_list (fun arg ->
    incr arg_counter;
    match !arg_counter with
    | 1 -> input_file := arg
    | 2 -> tape_input := Some (if arg = "" then "" else arg)
    | _ -> raise (Arg.Bad "Too many arguments")
  ) usage_msg;
  if !input_file = "" || !tape_input = None then
    begin
      Printf.eprintf "%s%s:%s %s\n" (ansi_of_color Red) "Error" (ansi_of_color Reset) "Missing arguments";
      Arg.usage spec_list usage_msg;
      exit 1
    end
  else
    try
      begin
      let machine = introduce @@ validate @@ machine_of_json_file !input_file (Option.get !tape_input) in
      if !show_bigO then
        ignore @@ run_and_analyze machine
      else
        ignore @@ run machine
      end
    with
    | Sys_error msg -> print_error "Please check your inputs" msg
    | JsonError msg -> print_error "Ill formatted JSON file" msg
    | Yojson.Json_error msg -> print_error "JSON Structure Error" msg
    | NeverHalts msg | InvalidState msg -> print_error "Invalid Machine" msg
    | InfLoop msg -> print_error "Execution error" msg
    | InvalidInput msg -> print_error "Input error" msg
