type action = {
  read : string;
  to_state : string;
  write : string;
  direction : string;
}
type sc_alphabet = {
  placeholder : char;
  curstate : char;
  nopstate : char;
  transi : char;
  mkrtransi : char;
  init : char;
  left : char;
  right : char;
  halt : char;
  input : char;
  blank : char;
  mkrblank : char;
}
type alphabet = {
  states : char list;
  basics : char list;
  sc : sc_alphabet;
  full : char list;
}
type state_def = string * action list
val string_of_char : char -> string
val string_of_dir : alphabet -> char -> string
val make_statedef : string -> action list -> state_def
val w_c_ : alphabet -> state_def list
val w_c_d : alphabet -> state_def list
val r_c_gt_curstate : alphabet -> state_def list
val r_c_gt_transi : alphabet -> state_def list
val r_c_ck_transi : alphabet -> state_def list
val mk_t : alphabet -> state_def list
val pick_state_1 : alphabet -> state_def list
val pick_state : alphabet -> state_def list
val gt_init_set_state_c : alphabet -> state_def list
val set_state_c : alphabet -> state_def list
val ck_state_c : alphabet -> state_def list
val mk_s : alphabet -> state_def list
val gt_init_gt_mkrtransi : alphabet -> state_def list
val gt_mkrtransi : alphabet -> state_def list
val gt_input : alphabet -> state_def list
val r_placeholder : alphabet -> state_def list
val skip_1_pick_r_d : alphabet -> state_def list
val skip_pick_r_d : alphabet -> state_def list
val pick_r_d : alphabet -> state_def list
val build_all : alphabet -> state_def list
val default_alphabet : alphabet
val action_to_json : action -> Yojson.Basic.t
val state_def_to_json : state_def -> string * Yojson.Basic.t
val extract_state_names : state_def list -> string list
val compose_json : state_def list -> string -> alphabet -> Yojson.Basic.t
val write_json : alphabet -> string -> unit
