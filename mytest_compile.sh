#!/bin/bash
# Run the compiler on the mytest.min file
testfile="TestInputs/mytest.min"
cat $testfile | ./parser

# Run the mytest.min compiled code with the inputs 10 and 15.
# I re-created mytest.min in c++ and the output for those inputs should be as follows:
# 0
# 2
# 4
# 6
# 8
# 10
# 12
# 14
# 16
# 18
# 10 (the value input for i)
# 15 (the value input for j)
# 20 (the value of k, which ends at n = 20)
# 30 (the value in t[i]
# 20 (the value in t[j]
 
# Run the primes.min compiled code with input 15.  This should output the prime numbers <= 15 which are 2 3 5 7 13
echo 10 15 > mytest_input.txt
mil_run mil_code.mil < mytest_input.txt
