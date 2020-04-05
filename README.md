# CS152_Project
Spring 2020
Ford St. John, 862125078 
Eduardo Rocha

## Phase 1: Lexical Analyzer Generation Using flex
We wrote a .lex specification file to use with flex in order to generate a lexical analyzer for the MINI-L language (for more information on the language see here https://www.cs.ucr.edu/~amazl001/teaching/cs152/S20/webpages1/mini_l.html).
A make file has been created to compile the code.  Assuming make is installed on one's system, the code can be compiled with:
```console
make clean
make
```
MINI-L compiled files can then be passed for lexical analysis using:
```console
./lexer fibonacci.min
```
for example
