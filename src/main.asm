.include "data.asm"
.include "entry.asm"
.include "mmio_config.asm" 


main:
	jal read_char_mmio
	move $a0, $v0
	jal print_char_mmio
	j main