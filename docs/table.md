# 7x4 UTM

## State table

|   | 0 | a | b | c |
|---|---|---|---|---|
| T |0<T|0<T|b<U| H |
| U |a>U|0<T|b>U|a<V|
| V |a<Z|a<V|b<W|c<V|
| W |a<X|a<V|   |   |
| X |a>Y|0>X|b>X|0>T|
| Y |c<V|a<Y|b>Y|c>Y|
| Z |a<V|a<Z|b<Z|c<Z|

# Tag System

## Alphabet

N function :

```
N(0) = 0; N(k) = N(k-1) + 1 + len(prod_of_a(k))
```

| j | b | W    |
|---|---|------|
| 0 | . |      |
| 1 | _ | a    |
| 2 | 1 | aa   |
| 3 | + | aaa  |
| 4 | = | aaaa |

## Production rules

where H is Halt:

| R | W |
|---|---|
| _ | 1 |
| + | = |
| 1 | H |
