.include "data.asm"
.include "entry.asm"
.include "utils/ascii_to_int.asm"
.include "utils/get_menu_item_addr.asm"
.include "utils/get_table_item_addr.asm"
.include "utils/function_parser.asm"
.include "utils/int_to_string.asm"
.include "menu/menu_add.asm"
.include "menu/menu_rm.asm"
.include "menu/menu_list.asm"
.include "menu/menu_format.asm"
.include "table/table_rm_item.asm"
.include "data_management/save_all_data.asm"
.include "data_management/load_all_data.asm"
.include "data_management/format_all_data.asm"
.include "commands.asm"
.include "commands_table.asm"
.include "mmio_config.asm"
.include "strlib/strcpy.asm"
.include "strlib/memcpy.asm"
.include "strlib/strcmp.asm"
.include "strlib/strncmp.asm"
.include "strlib/strcat.asm"
.include "table/table_format.asm"

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
	
