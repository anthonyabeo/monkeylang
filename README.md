# THE MONKEY PROGRAMMING LANGUAGE

This project is my implementation of the monkey programming language (monkeylang) in D. monkeylang is interpreted programming language from the books ["Writing an Interpreter in Go"](https://interpreterbook.com/) and ["Writing a compiler in Go"](https://compilerbook.com/) by [Thorsten Ball](https://twitter.com/thorstenball).

## SETUP
The tools needed to test and run this project are:  
- A D compiler (https://dlang.org/download.html)
- The `dub` package manager using (https://github.com/dlang/dub/releases) or the package registry of your operating system.

## TESTING AND RUNNING
With `dub` installed run the unit tests using `dub test` from the root directory. You should get an output similar to the one below.

```
$ dub test
Generating test runner configuration 'monkey-test-library' for 'library' (library).
Performing "unittest" build using /usr/local/bin/ldc2 for x86_64.
monkey ~master: building configuration "monkey-test-library"...
Linking...
Running ./monkey-test-library 
All unit tests have been run successfully.
```

Then run with `dub` like so:
```
$ dub
Hello! This is the Monkey programming language!
Feel free to type in commands

>>> puts("Hello World!")
Hello World!
>>> 
```

## MONKEYLANG IN ACTION
```rust
// Integers & arithmetic expressions
let version = 1 + (50 / 2) - (8 * 3);

// Strings
let name = "The Monkey programming language";

// Booleans
let isMonkeyFastNow = true;

// Arrays & Hashes
let people = [{"name": "Anna", "age": 24}, {"name": "Bob", "age": 99}];

// Functions
let getName = fn(person) { person["name"]; };
getName(people[0]); // => "Anna"
getName(people[1]); // => "Bob"

// `newAdder` returns a closure that makes use of the free variables `a` and `b`:
let newAdder = fn(a, b) {
    fn(c) { a + b + c };
};
// This constructs a new `adder` function:
let adder = newAdder(1, 2);

adder(8); // => 11
```