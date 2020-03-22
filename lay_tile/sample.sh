#!/bin/bash

# set -uex
set -ue

. include/common.sh
. include/lr35902.sh
. include/gb.sh

print_prog_const() {
	# タイルデータ(16バイト)
	echo -en '\xf0\xff\xe1\xfe\xc3\xfc\x87\xf8'
	echo -en '\x0f\xf0\x1e\xe0\x3c\xc0\x78\x80'
}

print_prog_main() {
	# 割り込みは使わないので止める
	lr35902_disable_interrupts

	# スクロールレジスタクリア
	gb_reset_scroll_pos

	# パレット初期化
	gb_set_palette_to_default

	# V-Blankの開始を待つ
	gb_wait_for_vblank_to_start

	# LCDを停止する
	# - 停止の間はVRAMとOAMに自由にアクセスできる(vblankとか関係なく)
	# - Bit 7の他も明示的に設定

	# [LCD制御レジスタの設定値]
	# - Bit 7: LCD Display Enable (0=Off, 1=On)
	#   -> LCDを停止させるため0
	# - Bit 6: Window Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
	#   -> 9800-9BFFは背景に使うため、
	#      ウィンドウタイルマップには9C00-9FFFを設定
	# - Bit 5: Window Display Enable (0=Off, 1=On)
	#   -> ウィンドウは使わないので0
	# - Bit 4: BG & Window Tile Data Select (0=8800-97FF, 1=8000-8FFF)
	#   -> タイルデータの配置領域は8000-8FFFにする
	# - Bit 3: BG Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
	#   -> 背景用のタイルマップ領域に9800-9BFFを使う
	# - Bit 2: OBJ (Sprite) Size (0=8x8, 1=8x16)
	#   -> スプライトはまだ使わないので適当に8x8を設定
	# - Bit 1: OBJ (Sprite) Display Enable (0=Off, 1=On)
	#   -> スプライトはまだ使わないので0
	# - Bit 0: BG Display (0=Off, 1=On)
	#   -> 背景は使うので1

	lr35902_set_reg regA 51
	lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

	# タイルデータをVRAMのタイルデータ領域へロード
	lr35902_set_reg regDE 0150
	lr35902_set_reg regHL 8000
	lr35902_set_reg regB 10
	lr35902_copy_to_from regA ptrDE
	lr35902_copy_to_from ptrHL regA
	lr35902_inc regDE
	lr35902_inc regHL
	lr35902_dec regB
	lr35902_rel_jump_with_cond NZ $(two_comp 07)

	# タイル番号をVRAMの背景用タイルマップ領域へ設定
	lr35902_clear_reg regA
	lr35902_set_reg regHL 9800
	lr35902_set_reg regC 20
	lr35902_copy_to_from regB regC
	lr35902_copyinc_to_ptrHL_from_regA
	lr35902_dec regC
	lr35902_rel_jump_with_cond NZ $(two_comp 04)
	lr35902_dec regB
	lr35902_rel_jump_with_cond Z 04
	lr35902_set_reg regC 20
	lr35902_rel_jump $(two_comp 0b)

	# LCD再開
	lr35902_set_reg regA d1
	lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

	# 無限ループで止める
	gb_infinity_halt
}

print_vector_table() {
	gb_all_nop_vector_table
}

print_cart_header() {
	local offset=$(print_prog_const | wc -c)
	local offset_hex=$(echo "obase=16;${offset}" | bc)
	local bc_form="obase=16;ibase=16;${GB_ROM_START_ADDR}+${offset_hex}"
	local entry_addr=$(echo $bc_form | bc)
	bc_form="obase=16;ibase=16;${entry_addr}+10000"
	local entry_addr_4digits=$(echo $bc_form | bc | cut -c2-5)

	gb_cart_header_no_title $entry_addr_4digits
}

print_cart_rom() {
	print_prog_const
	print_prog_main

	# 32KBのサイズにするために残りをゼロ埋め
	local num_const_bytes=$(print_prog_const | wc -c)
	local num_main_bytes=$(print_prog_main | wc -c)
	local padding=$((GB_CART_ROM_SIZE - num_const_bytes - num_main_bytes))
	dd if=/dev/zero bs=1 count=$padding
}

print_rom() {
	# 0x0000 - 0x00ff: リスタートと割り込みのベクタテーブル (256バイト)
	print_vector_table

	# 0x0100 - 0x014f: カートリッジヘッダ (80バイト)
	print_cart_header

	# 0x0150 - 0x7fff: カートリッジROM (32432バイト)
	print_cart_rom
}

print_rom >sample.gb
