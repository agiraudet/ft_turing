module StringMap = Map.Make(String)

let state_lst = StringMap.empty 


type action = {
  read: string;
  to_state: string;
  write: string;
  direction: string;
}

type state_def = string * action list

let sc_placeholder = '?'
let sc_curstate = '*'
let sc_nopstate = '#'
let sc_transi = '('
let sc_mkrtransi = '['
let sc_init = '$'
let sc_left = '<'
let sc_right = '>'

let state_alphabet = ['A';'B';'C']
let basic_alphabet = ['1';'+';'.']
let sc_alphabet = [sc_placeholder; sc_curstate; sc_nopstate; sc_transi; sc_mkrtransi; sc_init; sc_left; sc_right ]
let full_alphabet = state_alphabet @ basic_alphabet @ sc_alphabet

let string_of_char c = String.make 1 c

let string_of_dir d = if d = sc_left then "LEFT" else "RIGHT"

let make_statedef name def : state_def = (name, def)

let w_c_ c = 
  let state_name = "w_" ^ string_of_char c ^ "_" in
  let rec aux acc = function
    | [] -> acc
    | u::v -> aux ({read = string_of_char u;
      to_state = state_name ^ string_of_char u;
      write = string_of_char u;
      direction = "RIGHT" }::acc) v
  in make_statedef state_name @@ aux [] [sc_left;sc_right]

let w_c_d c d alphabet = 
  let state_name = "w_" ^ string_of_char c ^ "_" ^ string_of_char d in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e = 
    if u <> sc_placeholder then
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "RIGHT"}
    else
      {read = string_of_char sc_placeholder;
      to_state = "r_?";
      write = string_of_char c;
      direction = string_of_dir d}
    in aux (e::acc) v
  in make_statedef state_name @@ aux [] alphabet

let r_c_gt_curstate c alphabet =
  let state_name = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char sc_curstate in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e = 
    if u <> sc_curstate then
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "LEFT"}
    else
      {read = string_of_char sc_curstate;
      to_state = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char sc_transi;
      write = string_of_char sc_nopstate;
      direction = "RIGHT"}
    in aux (e::acc) v
  in make_statedef state_name @@ aux [] alphabet

let r_c_gt_transi c alphabet = 
  let state_name = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char sc_transi in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e = 
    if u <> sc_transi then
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "RIGHT"}
    else
      {read = string_of_char sc_transi;
      to_state = "r_" ^ string_of_char c ^ "_ck_" ^ string_of_char sc_transi;
      write = string_of_char sc_transi;
      direction = "RIGHT"}
    in aux (e::acc) v
  in make_statedef state_name @@ aux [] alphabet

let r_c_ck_transi c alphabet = 
  let state_name = "r_" ^ string_of_char c ^ "_ck_" ^ string_of_char sc_transi in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e = 
    if u <> c then
      {read = string_of_char u;
      to_state = "r_" ^ string_of_char c ^ "_gt_" ^ string_of_char sc_transi;
      write = string_of_char u;
      direction = "RIGHT"}
    else
      {read = string_of_char c;
      to_state = "mk_" ^ string_of_char sc_mkrtransi;
      write = string_of_char c;
      direction = "LEFT"}
    in aux (e::acc) v
  in make_statedef state_name @@ aux [] alphabet

let mk_t = 
  make_statedef ("mk_" ^ string_of_char sc_mkrtransi)
    [{read = string_of_char sc_transi;
    to_state = "pick_state_1";
    write = string_of_char sc_mkrtransi;
      direction = "RIGHT"}]

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
  in make_statedef "pick_state_1" @@ aux [] alphabet

let pick_state state_alphabet = 
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e =
    {read = string_of_char u;
      to_state = "set_state_" ^ string_of_char u ^ "_" ^ string_of_char sc_right;
      write = string_of_char u;
      direction = "LEFT"}
    in aux (e::acc) v
  in make_statedef "pick_state" @@ aux [] state_alphabet

let set_state_c_d c d alphabet = 
  let state_name = "set_state_" ^ string_of_char c ^ "_" ^ string_of_char d in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e = 
    if u <> c then
      {read = string_of_char u;
    to_state = state_name;
    write = string_of_char u;
    direction = string_of_dir d}
    else
      {read = string_of_char c;
      to_state = "mk_s";
      write = string_of_char c;
      direction = "LEFT";}
    in aux (e::acc) v
  in make_statedef state_name @@ aux [] alphabet

let mk_s =
  make_statedef "mk_s" @@ 
  [{read = string_of_char sc_nopstate;
  to_state = "gt_" ^ string_of_char sc_init ^ "_gt_" ^ string_of_char sc_mkrtransi;
  write = string_of_char sc_curstate;
    direction = "LEFT"}]

let gt_init_gt_mkrtransi alphabet = 
  let state_name = "gt_" ^ string_of_char sc_init ^ "_gt_" ^ string_of_char sc_mkrtransi in
  let rec aux acc = function
    | [] -> acc
    | u::v ->
    let e =
    if u = sc_init then
      {read = string_of_char sc_init;
      to_state = "gt_" ^ string_of_char sc_mkrtransi;
      write = string_of_char sc_init;
      direction = "RIGHT"}
    else if u = sc_mkrtransi then
      {read = string_of_char sc_mkrtransi;
      to_state = "skip_1_pick_r_d";
      write = string_of_char sc_transi;
      direction = "RIGHT"}
    else
      {read = string_of_char u;
      to_state = state_name;
      write = string_of_char u;
      direction = "LEFT"}
    in aux (e::acc) v
  in make_statedef state_name @@ aux [] alphabet

let add_statedef state_def =
  let (k, v) = state_def in
  StringMap.add k v state_lst

let test fn lst =
  let rec aux acc = function
  | [] -> acc
  | u::v -> aux ((fn u)::acc) v
  in aux [] lst


