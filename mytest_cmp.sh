#!/bin/bash
# Remove the test file if it currently exists
rm -f mytest_test.txt

# Create the test file to compare from the lexer executable
./lexer mytest.min > mytest_test.txt

# Compare the expected file to the test file
oldfile="mytest_expected.txt"
newfile="mytest_test.txt"

diff $oldfile $newfile | cat -t
