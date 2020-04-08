#!/bin/bash
# Remove the test file if it currently exists
rm -f primes_test.txt

# Create the test file to compare from the lexer executable
./lexer primes.min > primes_test.txt

# Compare the expected file to the test file
oldfile="primes_expected.txt"
newfile="primes_test.txt"

diff $oldfile $newfile | cat -t
