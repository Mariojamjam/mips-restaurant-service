.data
    save_success_message: .asciiz "Data saved successfully"
    save_error_message:   .asciiz "Error saving data"

.text

save_all_data:
	addi $sp, $sp, -8
        sw   $ra, 0($sp)

        # Open file: restaurant.bin
        li   $v0, 13
        la   $a0, save_file_name
        li   $a1, 1              # write
        li   $a2, 0
        syscall
	
	bltz $v0, save_error
	
	sw   $v0, 4($sp)
	
	li   $v0, 15
        lw   $a0, 4($sp)
        la   $a1, save_header_signature
        li   $a2, 4
        syscall
        
        bltz $v0, save_close_error
        
        # Write header menu size
        li   $v0, 15
        lw   $a0, 4($sp)
        la   $a1, save_header_menu_size
        li   $a2, 4
        syscall
        
        bltz $v0, save_close_error

        # Write header table size
        li   $v0, 15
        lw   $a0, 4($sp)
        la   $a1, save_header_table_size
        li   $a2, 4
        syscall
        
        bltz $v0, save_close_error

        # Write menus block
        li   $v0, 15
        lw   $a0, 4($sp)
        la   $a1, menus
        li   $a2, MENU_TOTAL_BYTES
        syscall
        
        bltz $v0, save_close_error

        # Write tables block
        li   $v0, 15
        lw   $a0, 4($sp)
        la   $a1, tables
        li   $a2, TABLE_TOTAL_BYTES
        syscall
        
        bltz $v0, save_close_error

        # Close file
        li   $v0, 16
        lw   $a0, 4($sp)
        syscall

        # Success message
        la   $a0, save_success_message
        jal  print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 8
        jr   $ra

save_close_error:
        # Try to close file before leaving on write failure
        li   $v0, 16
        lw   $a0, 4($sp)
        syscall
        
save_error:
        la   $a0, save_error_message
        jal  print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 8
        jr   $ra