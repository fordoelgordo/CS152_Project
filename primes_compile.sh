#!/bin/bash
# Run the compiler on the primes.min file
testfile="TestInputs/primes.min"
cat $testfile | ./parser

# Run the primes.min compiled code with input 15.  This should output the prime numbers <= 15 which are 2 3 5 7 13
echo 15 > primes_input.txt
mil_run mil_code.mil < primes_input.txt
