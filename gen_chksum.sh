#!/bin/bash
# x = 0
# FOR i = 0134h TO 014Ch
# x = x - MEM[i] - 1
# NEXT

set -uex

# 0x0134 - 0x013f (12 Bytes)
#   0x0134 35 36 37 38 39 3a 3b 3c 3d 3e 3f
HEADER="42 4F 4E 55 53 20 44 45 4D 4F 00 00"
# HEADER="00 00 00 00 00 00 00 00 00 00 00 00"

# 0x0140 - 0x014c (13 Bytes)
#           0x0140 41 42 43 44 45 46 47 48 49 4a 4b 4c
HEADER="$HEADER 00 00 00 80 00 00 03 01 01 00 00 33 00"
# HEADER="$HEADER 00 00 00 00 00 00 00 01 01 00 00 00 00"

x=0
for v in $HEADER; do
	x=$(echo "obase=16;ibase=16;$x - $v - 1" | bc)
done

# この時、xはマイナスの値
# 2の補数表現へ変換するため、
# 0x10^(計算結果桁数) - (計算結果絶対値)
# を計算する
# 例えば x = -0x39D の時、「0x1000 - 0x39D」を計算する
# コレが「全ビットを反転させて1を足す」操作とイコールになる
x_abs=$(echo "obase=16;ibase=16;-1 * $x" | bc)
num_digits=$(echo -n $x_abs | wc -c)
result=$(echo "obase=16;ibase=16;10^$num_digits - $x_abs" | bc)

# 計算結果の下位8ビットが
# 014D - Header Checksum
# の値
echo $result | rev | cut -c-2 | rev
