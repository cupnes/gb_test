/* 指定されたGB ROMファイルのグローバルチェックサムを出力する
 * コンパイル：
 * gcc -Wall -Wextra -o gen_global_chksum gen_global_chksum.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

void usage(const char *progname) {
	fprintf(stderr, "Usage:\n");
	fprintf(stderr, "\t%s GB_ROM_FILE_NAME\n", progname);
	fprintf(stderr, "\t%s -h\n", progname);
}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		usage(argv[0]);
		return 1;
	}

	if (strcmp(argv[1], "-h") == 0) {
		usage(argv[0]);
		return 0;
	}

	const char *GB_ROM_FILE_NAME = argv[1];
	FILE *file = fopen(GB_ROM_FILE_NAME, "rb");
	if (file == NULL) {
		perror("Failed to open file");
		return 1;
	}

	/* const int HEADER_CHKSUM_IDX = 0x014D; */
	const int GLOBAL_CHKSUM_IDX_1 = 0x014E;
	const int GLOBAL_CHKSUM_IDX_2 = GLOBAL_CHKSUM_IDX_1 + 1;

	uint8_t byte;
	unsigned int sum_hex = 0;

	for (int i = 0; fread(&byte, 1, 1, file) == 1; i++) {
		/* if (i == HEADER_CHKSUM_IDX) { */
		/* 	printf("header_chksum=%02X\n", byte); */
		/* 	continue; */
		/* } */
		if (i == GLOBAL_CHKSUM_IDX_1) {
			printf("global_chksum_1=%02X\n", byte);
			continue;
		}
		if (i == GLOBAL_CHKSUM_IDX_2) {
			printf("global_chksum_2=%02X\n", byte);
			continue;
		}

		sum_hex += byte;
	}

	printf("sum_hex=%X\n", sum_hex);

	fclose(file);
	return 0;
}
