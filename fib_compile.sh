#!/bin/bash
# Run the compiler on the fibonacci.min file
testfile="TestInputs/fibonacci.min"
cat $testfile | ./parser
echo 5 > input.txt
mil_run mil_code.mil < input.txt
