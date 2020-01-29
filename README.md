# THE MONKEY PROGRAMMING LANGUAGE

This project is my implementation of the monkey programming language (monkeylang) in D. monkeylang is interpreted programming language from the books ["Writing an Interpreter in Go"](https://interpreterbook.com/) and ["Writing a compiler in Go"](https://compilerbook.com/) by Thorsten Ball.

## SETUP
The tool needed to test and run this project are:  
- A D compiler (https://dlang.org/download.html)
- The `dub` package manager using (https://github.com/dlang/dub/releases) or the package registry of your operating system.

## TESTING AND RUNNING
With `dub` installed you can run `dub test` fromt the root directory like so:

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