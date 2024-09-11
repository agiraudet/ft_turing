# Turing Machine

This project is composed of three major parts:

1. Writing an OCaml Turing Machine (TM) emulator
2. Programming some small algorithms for it (or, TM descriptions)
3. Programming a TM that can run another TM

The last part is particularly interesting (and potentially quite tricky).

## 1. OCaml TM Emulator

### Data Structures

Implementing the TM emulator is quite straightforward. You will need, mostly, a tape and a way to move alongside it. Then you need to read a cell of the tape, and match it, depending on your state, to an action to take.

Defining some simple data structures makes that more clear:

The tape is a simple zipper list: a struct that holds two lists, representing the left and right sides of the tape, and the current cell.

```ocaml
type 'a tape = {
  left: 'a list;
  current: 'a;
  right: 'a list;
}
```

Moving alongside the tape is simple from there:

```ocaml
let move_left tape = 
    match tape.left with
    | [] -> { tape with right = tape.current::tape.right ; current = tape.blank}
    | u::v -> { tape with left = v; current = u; right = tape.current::tape.right}
```

Actions can be defined as a record for ease of use, and stored in maps representing the "instruction book" of a TM:

```ocaml
type direction = Left | Right

type action = {
  to_state: string;
  write: char;
  direction: direction;
}

type action_map = action CharMap.t
type transition_map = action_map StringMap.t
```

All of these structures can then be grouped together in a `machine` record.

### Building the Machine

Now you have to parse a JSON file to populate that `machine` record. I used the Yojson library to do that, and then a few helper functions to validate the machine.

A lot can be checked before running it:

- Does it have a halt state?
- Is that state reachable? (Meaning, starting from the initial state, can you reach that final state?)
  Recursivity makes it not too hard to think about this, but it may be very resource-intensive for some TMs to check all possible branches.
- Are all characters used part of the defined alphabet?
- etc.

Some checks, of course, can only be done at runtime.

### Detecting Blocking

There are several ways the machine could go into a "blocked" state:

1. Infinite run
2. Infinite loop

While checking for an infinite run is quite trivial, checking for infinite loops might be a bit resource-intensive.

#### 1. Infinite Run

If your current state, when reading a blank character, transitions into the same state and moves you in a direction where the tape is empty, then you would only ever read blanks, and thus stay in that state and keep going forever.

#### 2. Infinite Loop

TMs being deterministic, any given state will always produce an identical output. Here we use state in a general sense, including both the actual state value of the machine and the content of its tape.

So, if during execution, a similar state is repeated, it means the output of its first computation took you to itself again, and that this will, inevitably, happen again.

A way to detect that is to keep track of previous states, and compare at each step the current one to the past states. This, obviously, might use an exponential amount of resources, even though there are a lot of tweaks to do for optimizations.

In the end, if you want a systematic detection of loops, you need to store a number of states equal to the number of steps taken by the machine. You might want to compromise here, and keep fewer of them, but that limits the complexity of the loops you can detect.

Here, since the algorithms we will run are not very complex, I choose the path of strict correctness and decide to store all previous states.

## 2. Programming TMs

This is the fun part, since crafting small TMs that perform a basic task is made not too hard by including good validation and blocking detection into our emulator, making debugging easier.

Taking this example:

```
A machine able to decide if the input is a word of the language 0^2n, for instance
the words 00 or 0000, but not the words 000 or 00000.
```

Not counting HALT (H), you only need two states for this, since you will check zeros by pair, and only navigate from left to right. So a "starting pair" (S) state, and an "ending pair" (E) state. If you read a blank while in "ending pair" mode, then the answer is false since you just read a lonely zero. If you read a blank in "starting pair", you have reached the end of an input made only of pairs, so the result is true. This can be summed up like this:

Where the action is `new state - write - direction` and `.` is blank:

|   | 0 | . |
|---|---|---|
| S |E0>|Hy>|
| E |S0>|Hn>|

## 3. Universal Turing Machine (UTM)... Or not ?

The last exercise is to build a machine that can run another machine, given in an encoded form as input. This is precisely what a UTM is, and there is a **lot** of research on this topic, most of it is sadly not very digestible if you don't have some academic affinity.
There is a rabbit hole to fell into here, and you have to make a choice: go the full universal way, or do just what is needed for the subject.
After trying the first option for a while, I realized it was to time consuming without some previous academic knowledge on that subject to just get up-to-date.
In case you feel like doing this anyway, here are some pointers I found along the way. Also, check the `docs` directory of this repo, that holds some paper with the answer in them.

### UTMs

1. Pick a UTM
   Researchers have discovered quite a few of them and proved them to be actually universal. There is a competition among them to find the simplest one, meaning the one with the fewest commands. They are usually described as *U(m,n)* where *U* is the UTM, *m* the number of states, and *n* the number of symbols in its alphabet.

   Finding an existing one, like Minsky's U(7,4), and implementing its commands is quite trivial. But finding how to encode other TMs to feed to it is less so.

2. Encode TMs
   One of the key elements that make UTMs provable as universal is the fact that any list of transitions (described usually as quintuples `(CurrentState, Reading, Writing, Direction, NextState)`) can be described as a 2-tag system.
   (This is proven in the paper "Minsky's Small Universal Turing Machine" by Raphael M. Robinson, 1991)

   A tag system, according to Wikipedia, is:

   ```
   A tag system is a triplet (m, A, P), where
     m is a positive integer, called the deletion number.
     A is a finite alphabet of symbols, one of which can be a special halting symbol. All finite (possibly empty) strings on A are called words.
     P is a set of production rules, assigning a word P(x) (called a production) to each symbol x in A. The production (say P(H)) assigned to the halting symbol is seen below to play no role in computations, but for convenience is taken to be P(H) = 'H'.
   ```

   Let's say that it is a set of rules that tells you to consume the *m* first elements of the input, and append to the end of it a word that you get by finding a match for the first of the consumed symbols in the list of production rules.

   It turns out, Minsky's U(7,4) UTM processes 2-tag systems. So, we have to take our list of quintuples describing the TM we want to encode, turn it into a 2-tag system, and feed that to the UTM. Easy, no?

Well, if you are familiar with mathematics, probably yes, and you will find a good state tabe for a U(7,4) machine with the encoding equation in Claudio Baiocchi paper, `Three Small Universal Turing Machines`.

If however, you would rather go a creative but not really universal way, well you can come up with your own way o do stuff !

### Not-UTMs, but a little ?

What is asked by the subject is to make a machine that get fed the description of our unary addition machine and simulate it. It's up to us to find an encoding to represent its states, transitions, etc.
So you will need to store on the tape : the description of the machine, its input tape, and some information regarding the current state mid-simulation.
While there is a lot of way to go about that, you will face on problem. How to store and move information around ?
For example, let's say you decide to store the description of the machine (meaning description of state and transitions) at the beginning of the tape, and the simulated tape at the right of it. You will need to read a character, and then figure out which state the machine is in to then lookup what to do next (what to write, where to move, etc).
But how do you move around, and still remember the character you just read ?
Well, the answer is states. A lot of them. After all states are a form a memory. Obviously, writing the description of that NUTM (Not Universal Turing Machine) by hand, would be very tedious, and so you are probably gonna want to generate it.
So, we will need to :

- figure out the algorithm for our NUTM
- make up the encoding we want to use
- write some code to generate the json file describing that.
Lest proceed step by step here.
