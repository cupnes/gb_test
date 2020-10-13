#!/bin/bash

set -uex

# 0x0134 - 0x013f (12 Bytes)
HEADER="00 00 00 00 00 00 00 00 00 00 00 00"

# 0x0140 - 0x014c (13 Bytes)
#           0x0140 41 42 43 44 45 46 47 48 49 4a 4b 4c
HEADER="$HEADER 00 00 00 00 00 00 00 01 01 00 00 00 00"

x=0
for v in $HEADER; do
	x=$(echo "obase=16;ibase=16;$x - $v - 1" | bc)
done

x_abs=$(echo "obase=16;ibase=16;-1 * $x" | bc)

echo "obase=16;ibase=16;100 - $x_abs" | bc
