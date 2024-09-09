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

module StringMap : Map.S with type key = string
module CharMap : Map.S with type key = char

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

