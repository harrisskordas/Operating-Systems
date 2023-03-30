#!/bin/sh

# Author : Skordas Charisis
# Script follows here:

make

echo "Running the program with text.txt,10 children,5 transactions, 10 lines per segment."
echo "Program has installed makefile."

./a.out text.txt 10 5 10
