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
| B |B1>|H+_|C.<|
| C |H._|C.<|C.<|

With the rules given earlier, we can encode our state table like so :

- `#A(1A1>(+B1>(.A.>`
- `#B(1B1>(+H+<(.C.<`
- `#C(1H.<(+C.<(.C.<`

For halting, we use few special symbols. As you can see from the state table, we have an H state, and we signify that it is a halting one be swapping the direction for `_`.
If we stop as soon as the H state was marked, we would miss the last write operation.

We then just have to add our special beginning and end markers, concatenate all the descriptions, and set our initial state.

`$*A(1A1>(+B1>(.A.>#B(1B1>(+H+_(.C.<#C(1H._(+C.<(.C.<#H|`

Then, since the subject specify that blanks are not allowed in the input tape, we swap them for a placeholder, like `,`, that will get replaced buy actual blanks at the start of the machine execution.

`$*A(1A1>(+B1>(,A,>#B(1B1>(+H+_(,C,<#C(1H,_(+C,<(,C,<#H|`

# Executing

At run time, the root machine will proceed like so:
  1. We start by moving to find the input tape and read the first character. On the way, we substitute blank placeholders for actual blanks.
  2. We replace the read character by a `?`, that marks our simulated machine head. We remember that character via a state.
  3. We find our current state, by going left until we find the `*` marker. We then unmark that state, swapping `*` for our regular state marker `#`. We are going to switch state anyway.
  4. Next, we move right, checking every transition description `(` to find the one matching what we read. We mark that with `[`
  5. We can now read our next state, and mark it as well.
  6. We go back to our marked transition, unmark it, and memorise what to read and which direction to go via a state.
  7. We find our `?`, and proceed with the writing and moving.
  8. we go back to step 2
