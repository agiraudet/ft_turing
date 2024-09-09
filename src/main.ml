open Parser
open Machine
open Sys
open Arg

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
