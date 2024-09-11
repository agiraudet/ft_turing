# Encoding

We encode transitions as `READ - NEXT_STATE - TO_WRITE - DIRECTION`
Direction are represented by `<` and `>`.
The start of a transition description is marked by a `(`
We can now compose a state description like this `STATE_NAME - transitionA - transitionB - etc`
We mark the beginning of a state description with a `#`
`*` is a special state marker that denote the current state of the simulated machine.
Thus, we should use it to specify the initial state.
`$` is a special symbol that we use to mark the beginning of our tape,
and `|` separate the machine description from the input tape of the simulated machine.
Other special characters reserved for the machine are :

- `?` which represent the head of the simulated machine on the tape
- `[` which is used to mark the currently simulated transition

## Example: Simple add

This example encoding the algorithm of `simple_add.json`:
We represent the states like so:

- find_add = A
- find_last = B
- del_one = C

with alphabet `{1, +, .}` for the simulated machine, where `.` is blank.

|   | 1 | + | . |
|---|---|---|---|
| A |A1>|B1>|A.>|
| B |B1>|H+<|C.<|
| C |H.<|C.<|C.<|

With the rules given earlier, we can encode our state table like so :

- `#A(1A1>(+B1>(.A.>`
- `#B(1B1>(+H+<(.C.<`
- `#C(1H.<(+C.<(.C.<`

We then just have to add our special beginning and end markers, concatenate all the descriptions, and set our initial state.

`$*A(1A1>(+B1>(.A.>#B(1B1>(+H+<(.C.<#C(1H.<(+C.<(.C.<|...`
