.include "data.asm"
.include "entry.asm"
.include "commands.asm"
.include "commands_table.asm"
.include "mmio_config.asm"
.include "strlib/strcpy.asm"
.include "strlib/memcpy.asm"
.include "strlib/strcmp.asm"
.include "strlib/strncmp.asm"
.include "strlib/strcat.asm"

main:
	#Printing the banner
	la $a0, banner
	jal print_str_mmio
	
	#Reading user input
	jal read_str_mmio
	
	#Jump to the table that stores the references of the commands
	jal commands_table_init
	
	#Jump a line after every command
	li  $a0, 0xA
	jal print_char_mmio
	
	#Restart the loop
	j main
	