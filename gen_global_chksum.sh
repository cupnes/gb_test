#!/bin/bash

# 指定されたGB ROMファイルのグローバルチェックサムを出力する

set -ue

usage() {
	echo 'Usage:' 1>&2
	echo -e "\t$0 GB_ROM_FILE_NAME" 1>&2
	echo -e "\t$0 -h" 1>&2
}

while getopts h option; do
	case $option in
	h)
		usage
		exit 0
		;;
	*)
		usage
		exit 1
	esac
done
shift $((OPTIND - 1))
if [ $# -ne 1 ]; then
	usage
	exit 1
fi

GB_ROM_FILE_NAME=$1

GLOBAL_CHKSUM_IDX_1=$(bc <<< 'ibase=16;014E')
GLOBAL_CHKSUM_IDX_2=$((GLOBAL_CHKSUM_IDX_1 + 1))

i=0
sum_hex=0
for byte in $(od -A n -t x1 -v -w1 nemesis.gb | tr '[a-z]' '[A-Z]'); do
	if [ $i -eq $GLOBAL_CHKSUM_IDX_1 ]; then
		echo "global_chksum_1=$byte"
		i=$((i + 1))
		continue
	fi
	if [ $i -eq $GLOBAL_CHKSUM_IDX_2 ]; then
		echo "global_chksum_2=$byte"
		i=$((i + 1))
		continue
	fi

	sum_hex=$(bc <<< "obase=16;ibase=16;$sum_hex + $byte")
	i=$((i + 1))
done

echo "sum_hex=$sum_hex"
