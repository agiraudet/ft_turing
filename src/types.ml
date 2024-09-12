type color =
  | Black | Red | Green | Yellow | Blue | Magenta | Cyan | White
  | BrightBlack | BrightRed | BrightGreen | BrightYellow
  | BrightBlue | BrightMagenta | BrightCyan | BrightWhite
  | Default | Inverted | Reset

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

module StringMap = Map.Make(String)
module CharMap = Map.Make(Char)

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

type state_data = {
  visits: int;
  tape_positions: int list;
}

type complexity_estimate =
  | Constant
  | Linear
  | Quadratic
  | Exponential
  | Infinite
