#!/bin/bash
# Create the test file to compare from the lexer executable
./lexer fibonacci.min > fibonacci_test.txt

# Compare the expected file to the test file
oldfile="fibonacci_expected.txt"
newfile="fibonacci_test.txt"

diff $oldfile $newfile | cat -t
