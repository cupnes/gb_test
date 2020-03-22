GB_CART_ROM_SIZE=32432
GB_ROM_START_ADDR=0150

# I/O Ports
GB_IO_LCDC=40
GB_IO_SCY=42
GB_IO_SCX=43
GB_IO_LY=44
GB_IO_BGP=47

GB_GBP_DEFAULT=e4		# %11100100

# Nintendoロゴデータ
gb_nintendo_logo() {
	echo -en '\xce\xed\x66\x66\xcc\x0d\x00\x0b'
	echo -en '\x03\x73\x00\x83\x00\x0c\x00\x0d'
	echo -en '\x00\x08\x11\x1f\x88\x89\x00\x0e'
	echo -en '\xdc\xcc\x6e\xe6\xdd\xdd\xd9\x99'
	echo -en '\xbb\xbb\x67\x63\x6e\x0e\xec\xcc'
	echo -en '\xdd\xdc\x99\x9f\xbb\xb9\x33\x3e'
}

# タイトル文字列無しのヘッダ
gb_cart_header_no_title() {
	local entry_addr=$1

	# エントリアドレスへジャンプ
	echo -en '\x00\xc3'
	echo_2bytes $entry_addr

	# Nintendoロゴデータ
	gb_nintendo_logo

	# アドレス0x0134-0x014c(25バイト)のヘッダ情報はすべて0にする
	dd if=/dev/zero bs=1 count=25

	# ヘッダのチェックサム
	echo -en '\xe7'

	# グローバルチェックサム
	# (実機では見ない情報だし設定しない)
	echo -en '\x00\x00'
}

gb_all_nop_vector_table() {
	dd if=/dev/zero bs=1 count=256
}

gb_reset_scroll_pos() {
	# スクロールレジスタクリア
	lr35902_clear_reg regA
	lr35902_copy_to_ioport_from_regA $GB_IO_SCY
	lr35902_copy_to_ioport_from_regA $GB_IO_SCX
}

gb_set_palette_to_default() {
	# パレット初期化
	lr35902_set_reg regA $GB_GBP_DEFAULT
	lr35902_copy_to_ioport_from_regA $GB_IO_BGP
}

gb_wait_for_vblank_to_start() {
	# vblankの開始の瞬間(LY=147)を待つ
	lr35902_copy_to_regA_from_ioport $GB_IO_LY
	lr35902_compare_regA_and 93
	lr35902_rel_jump_with_cond NZ $(two_comp 06)
}

gb_infinity_halt() {
	# 無限ループで止める
	lr35902_halt
	lr35902_rel_jump $(two_comp 04)
}
