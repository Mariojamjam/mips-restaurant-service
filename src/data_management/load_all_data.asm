load_all_data:
	addi $sp, $sp, -8
        sw   $ra, 0($sp)

        # Open file: restaurant.bin
        li   $v0, 13
        la   $a0, save_file_name
        li   $a1, 0              # write
        li   $a2, 0
        syscall
        
        sw $v0, 4($sp)
        
        bltz $v0, load_error
        
        li   $v0, 14
	lw   $a0, 4($sp)
	la   $a1, load_header_signature
	li   $a2, 4
	syscall
	
	bltz $v0, load_error
	
	li   $v0, 14
	lw   $a0, 4($sp)
	la   $a1, load_header_menu_size
	li   $a2, 4
	syscall
	
	bltz $v0, load_error
	
	li   $v0, 14
	lw   $a0, 4($sp)
	la   $a1, load_header_table_size
	li   $a2, 4
	syscall
	
        bltz $v0, load_error