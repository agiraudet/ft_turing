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
  Printf.eprintf "%s%s:%s %s\n" (ansi_of_color RED) e (ansi_of_color RESET) msg;
  exit 1;

let () =
  if Array.length Sys.argv <> 3 then
    begin
    Printf.printf "Usage: %s <file.json> <tape_input>\n" Sys.argv.(0);
    exit 1
    end
  else try
    let show_bigO = false in
    let machine = introduce @@ validate @@ machine_of_json_file Sys.argv.(1) Sys.argv.(2) in
    if show_bigO then
      ignore @@ run_and_analyze machine
    else
      ignore @@ run machine
  with
    | Sys_error msg -> print_error "Please check your inpupts"  msg;
    | JsonError msg -> print_error "Ill formated JSON file"  msg;
    | Yojson.Json_error msg -> print_error "JSON Structure Error" msg;
    | NeverHalts msg | InvalidState msg -> print_error "Invalid Machine"  msg;
    | InfLoop msg -> print_error "Execution error"  msg;
    | InvalidInput msg -> print_error "Input error" msg;
