type action = {
  read: string;
  to_state: string;
  write: string;
  direction: string;
}

type sc_alphabet = {
  placeholder: char;
  curstate: char;
  nopstate: char;
  transi: char;
  mkrtransi: char;
  init: char;
  left: char;
  right: char;
  halt: char;
  input: char;
  blank: char;
  mkrblank: char;
}

type alphabet = {
  states: char list;
  basics: char list;
  sc: sc_alphabet;
  full: char list;
}

type state_def = string * action list

let string_of_char c = String.make 1 c

let string_of_dir alphabet d = if d = alphabet.sc.left then "LEFT" else "RIGHT"

let make_statedef name def : state_def = (name, def)

let w_c_ alphabet =
  let build c = 
    let state_name = "w_" ^ string_of_char c ^ "_" in
    let rec aux acc = function
      | [] -> acc
      | u::v -> aux ({read = string_of_char u;
        to_state = state_name ^ string_of_char u;
        write = string_of_char u;
        direction = "RIGHT" }::acc) v
    in make_statedef state_name @@ aux [] [alphabet.sc.left;alphabet.sc.right;alphabet.sc.halt]
  in List.map build alphabet.basics

let w_c_d alphabet = 
  let build d alphabet next_state c = 
    let state_name = "w_" ^ string_of_char c ^ "_" ^ string_of_char d in
    let rec aux acc = function
      | [] -> acc
      | u::v ->
      let e = 
      if u <> alphabet.sc.placeholder then
        {read = string_of_char u;
        to_state = state_name;
        write = string_of_char u;
        direction = "RIGHT"}
      else
        {read = string_of_char alphabet.sc.placeholder;
        to_state = next_state;
        write = string_of_char c;
        direction = string_of_dir alphabet d}
      in aux (e::acc) v
    in make_statedef state_name @@ aux [] alphabet.full
  in List.map (build alphabet.sc.left alphabet ("r_" ^ string_of_char alphabet.sc.placeholder)) alphabet.basics
  @ List.map (build alphabet.sc.right alphabet ("r_" ^ string_of_char  alphabet.sc.placeholder)) alphabet.basics
  @ List.map (build alphabet.sc.halt alphabet "HALT") alphabet.basics

let r_c_gt_curstate alphabet =
  let build alphabet c =
    let state_name = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char alphabet.sc.curstate in
    let rec aux acc = function
      | [] -> acc
      | u::v ->
      let e = 
      if u <> alphabet.sc.curstate then
        {read = string_of_char u;
        to_state = state_name;
        write = string_of_char u;
        direction = "LEFT"}
      else
        {read = string_of_char alphabet.sc.curstate;
        to_state = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char alphabet.sc.transi;
        write = string_of_char alphabet.sc.nopstate;
        direction = "RIGHT"}
      in aux (e::acc) v
    in make_statedef state_name @@ aux [] alphabet.full
  in List.map (build alphabet) alphabet.basics 

let r_c_gt_transi alphabet = 
  let build alphabet c = 
    let state_name = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char alphabet.sc.transi in
    let rec aux acc = function
      | [] -> acc
      | u::v ->
      let e = 
      if u <> alphabet.sc.transi then
        {read = string_of_char u;
        to_state = state_name;
        write = string_of_char u;
        direction = "RIGHT"}
      else
        {read = string_of_char alphabet.sc.transi;
        to_state = "r_" ^ string_of_char c ^ "_ck_" ^ string_of_char alphabet.sc.transi;
        write = string_of_char alphabet.sc.transi;
        direction = "RIGHT"}
      in aux (e::acc) v
    in make_statedef state_name @@ aux [] alphabet.full
  in List.map (build alphabet) alphabet.basics

let r_c_ck_transi alphabet = 
  let build alphabet c = 
    let state_name = "r_" ^ string_of_char c ^ "_ck_" ^ string_of_char alphabet.sc.transi in
    let rec aux acc = function
      | [] -> acc
      | u::v ->
      let e = 
      if u <> c then
        {read = string_of_char u;
        to_state = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char alphabet.sc.transi;
        write = string_of_char u;
        direction = "RIGHT"}
      else
        {read = string_of_char c;
        to_state = "mk_" ^ string_of_char alphabet.sc.mkrtransi;
        write = string_of_char c;
        direction = "LEFT"}
      in aux (e::acc) v
    in make_statedef state_name @@ aux [] alphabet.full
  in List.map (build alphabet) alphabet.basics

let mk_t alphabet = 
  [make_statedef ("mk_" ^ string_of_char alphabet.sc.mkrtransi)
    [{read = string_of_char alphabet.sc.transi;
    to_state = "pick_state_1";
    write = string_of_char alphabet.sc.mkrtransi;
      direction = "RIGHT"}]]

let pick_state_1 alphabet = 
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e = 
    {read = string_of_char u;
      to_state = "pick_state";
      write = string_of_char u;
      direction = "RIGHT"}
    in aux (e::acc) v
  in [make_statedef "pick_state_1" @@ aux [] alphabet.full]

let pick_state alphabet = 
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e =
    {read = string_of_char u;
          to_state = "gt_" ^ string_of_char alphabet.sc.init ^ "_set_state_" ^ string_of_char u;
      write = string_of_char u;
      direction = "LEFT"}
    in aux (e::acc) v
  in [make_statedef "pick_state" @@ aux [] alphabet.states]

let gt_init_set_state_c alphabet = 
  let build alphabet c =
    let state_name = "gt_" ^ string_of_char alphabet.sc.init ^ "_set_state_" ^ string_of_char c in
    let rec aux acc = function
      | [] -> acc
      | u::v ->
      let e =
      if u = alphabet.sc.init then
        {read = string_of_char alphabet.sc.init;
        to_state = "set_state_" ^ string_of_char c;
        write = string_of_char alphabet.sc.init;
        direction = "RIGHT"}
      else
        {read = string_of_char u;
        to_state = state_name;
        write = string_of_char u;
        direction = "LEFT"}
      in aux (e::acc) v
    in make_statedef state_name @@ aux [] alphabet.full
  in List.map (build alphabet) alphabet.states

let set_state_c alphabet = 
  let build alphabet c = 
    let state_name = "set_state_" ^ string_of_char c in
    let rec aux acc = function
      | [] -> acc
      | u::v ->
      let e = 
      if u <> alphabet.sc.nopstate && u <> alphabet.sc.curstate then
        {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "RIGHT"}
      else
        {read = string_of_char u;
        to_state = "ck_state_" ^ string_of_char c;
        write = string_of_char u;
        direction = "RIGHT";}
      in aux (e::acc) v
    in make_statedef state_name @@ aux [] alphabet.full
  in List.map (build alphabet) alphabet.states

let ck_state_c alphabet = 
  let build alphabet c = 
    let state_name = "ck_state_" ^ string_of_char c in
    let rec aux acc = function
    | [] -> acc
    | u::v -> 
    let e = 
    if u <> c then
      {read = string_of_char u;
      to_state = "set_state_" ^ string_of_char c;
      write = string_of_char u;
      direction = "RIGHT"}
    else
      {read = string_of_char c;
      to_state = "mk_s";
      write = string_of_char c;
        direction = "LEFT"}
    in aux (e::acc) v
  in make_statedef state_name @@ aux [] alphabet.states
in List.map (build alphabet) alphabet.states

let mk_s alphabet =
  let e =
  {read = string_of_char alphabet.sc.nopstate;
  to_state = "gt_" ^ string_of_char alphabet.sc.init ^ "_gt_" ^ string_of_char alphabet.sc.mkrtransi;
  write = string_of_char alphabet.sc.curstate;
  direction = "LEFT"}
  in 
  [make_statedef "mk_s" @@ [ e; {e with read = string_of_char alphabet.sc.curstate}]]

let gt_init_gt_mkrtransi alphabet = 
  let state_name = "gt_" ^ string_of_char alphabet.sc.init ^ "_gt_" ^ string_of_char alphabet.sc.mkrtransi in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e =
    if u = alphabet.sc.init then
      {read = string_of_char alphabet.sc.init;
      to_state = "gt_" ^ string_of_char alphabet.sc.mkrtransi;
      write = string_of_char alphabet.sc.init;
      direction = "RIGHT"}
    else if u = alphabet.sc.mkrtransi then
      {read = string_of_char alphabet.sc.mkrtransi;
      to_state = "skip_1_pick_r_d";
      write = string_of_char alphabet.sc.transi;
      direction = "RIGHT"}
    else
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "LEFT"}
    in aux (e::acc) v
  in [make_statedef state_name @@ aux [] alphabet.full]


let gt_mkrtransi alphabet =
  let state_name = "gt_" ^ string_of_char alphabet.sc.mkrtransi in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e =
    if u <> alphabet.sc.mkrtransi then
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "RIGHT";}
    else
      {read = string_of_char alphabet.sc.mkrtransi;
      to_state = "skip_1_pick_r_d";
      write = string_of_char alphabet.sc.transi;
      direction = "RIGHT";}
    in aux (e::acc) v
  in [make_statedef state_name @@ aux [] alphabet.full]

let gt_input alphabet =
  let state_name = "gt_" ^ string_of_char alphabet.sc.input in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e =
    if u = alphabet.sc.mkrblank then
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char alphabet.sc.blank;
      direction = "RIGHT";}
    else if u = alphabet.sc.input then
      {read = string_of_char alphabet.sc.input;
      to_state = "r_" ^ string_of_char alphabet.sc.placeholder;
      write = string_of_char alphabet.sc.input;
      direction = "RIGHT";}
    else
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "RIGHT";}
    in aux (e::acc) v
  in [make_statedef state_name @@ aux [] alphabet.full]

let r_placeholder alphabet = 
  let state_name = "r_" ^ string_of_char alphabet.sc.placeholder in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e = 
    {read = string_of_char u;
    to_state = "r_" ^ string_of_char u ^ "_gt_" ^ string_of_char alphabet.sc.curstate;
    write = string_of_char alphabet.sc.placeholder;
    direction = "LEFT";}
    in aux (e::acc) v
  in [make_statedef state_name @@ aux [] alphabet.basics]

let skip_1_pick_r_d alphabet =
  let state_name = "skip_1_pick_r_d" in
  let rec aux acc = function
    | [] -> acc
    | u::v -> 
    let e =
    {read = string_of_char u;
    to_state = "skip_pick_r_d";
    write = string_of_char u;
    direction = "RIGHT";}
    in aux (e::acc) v
  in [make_statedef state_name @@ aux [] alphabet.full]


let skip_pick_r_d alphabet =
  let state_name = "skip_pick_r_d" in
  let rec aux acc = function
    | [] -> acc
    | u::v -> 
    let e =
    {read = string_of_char u;
    to_state = "pick_r_d";
    write = string_of_char u;
    direction = "RIGHT";}
    in aux (e::acc) v
  in [make_statedef state_name @@ aux [] alphabet.full]

let pick_r_d alphabet = 
  let state_name = "pick_r_d" in
  let rec aux acc = function
  | [] -> acc
  | u::v -> 
  let e = 
  {read = string_of_char u;
  to_state = "w_" ^ string_of_char u ^ "_";
  write = string_of_char u;
  direction = "RIGHT";}
  in aux (e::acc) v
  in [make_statedef state_name @@ aux [] alphabet.basics]


let build_all alphabet =
  let fns = [
    w_c_;
    w_c_d;
    r_c_gt_curstate;
    r_c_gt_transi;
    r_c_ck_transi;
    mk_t;
    pick_state_1;
    pick_state;
    gt_init_set_state_c;
    set_state_c;
    ck_state_c;
    mk_s;
    gt_init_gt_mkrtransi;
    gt_mkrtransi;
    r_placeholder;
    gt_input;
    skip_1_pick_r_d;
    skip_pick_r_d;
    pick_r_d;
  ] in
  let rec aux acc = function
  | [] -> acc
  | u::v -> aux ((u alphabet)@acc) v
  in aux [] fns

let default_alphabet = 
  let sc = {
    placeholder = '?';
    curstate = '*';
    nopstate = '#';
    transi = '(';
    mkrtransi = '[';
    init = '$';
    left = '<';
    right = '>';
    halt = '_';
    blank = '.';
    input = '|';
    mkrblank = ','
  } in
  {
    states = ['A';'B';'C';'H'];
    basics = ['1';'+';'.'];
    sc = sc;
    full = ['A';'B';'C';'H';'1';'+';'.';'?';'*';'#';'(';'[';'$';'<';'>';'|';'_';',']
  }

open Yojson.Basic

let action_to_json (action: action) : Yojson.Basic.t =
  `Assoc [
    ("read", `String action.read);
    ("to_state", `String action.to_state);
    ("write", `String action.write);
    ("action", `String action.direction)
  ]

let state_def_to_json ((state, actions): state_def) : string * Yojson.Basic.t =
  (state, `List (List.map action_to_json actions))

let extract_state_names (state_defs: state_def list) : string list =
  List.map fst state_defs

let compose_json (state_defs: state_def list) json_name alphabet: Yojson.Basic.t =
  let transitions = `Assoc (List.map state_def_to_json state_defs) in
  let states = `List ((`String "HALT")::(List.map (fun s -> `String s) (extract_state_names state_defs))) in
  let name = `String json_name in
  let alp = `List (List.map (fun c -> `String (string_of_char c)) alphabet.full) in
  let finals = `List (List.map (fun s -> `String s) ["HALT"]) in
  `Assoc [
    ("name", name);
    ("alphabet", alp);
    ("blank", `String (string_of_char alphabet.sc.blank));
    ("states", states);
    ("initial", `String ("gt_" ^ string_of_char alphabet.sc.input));
    ("finals", finals);
    ("transitions", transitions)
  ]

let write_json alphabet json_name =
  let state_defs = build_all alphabet in
  let json = compose_json state_defs  json_name  alphabet in
  Yojson.Basic.to_file (json_name ^ ".json") json

let () =
  write_json default_alphabet "test"
