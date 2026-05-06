.data
	load_success_message: "Loaded data sucessfully"
	load_error_message: "Error loading data"

.text
load_all_data:
        addi $sp, $sp, -8
        sw   $ra, 0($sp)

        # Open file: restaurant.bin
        li   $v0, 13
        la   $a0, save_file_name
        li   $a1, 0              # read
        li   $a2, 0
        syscall

        bltz $v0, load_error
        sw   $v0, 4($sp)

        # Read header signature
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, load_header_signature
        li   $a2, 4
        syscall
        bltz $v0, load_close_error

        lw   $t0, load_header_signature
        lw   $t1, save_header_signature
        bne  $t0, $t1, load_close_error

        # Read header menu size
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, load_header_menu_size
        li   $a2, 4
        syscall
        bltz $v0, load_close_error

        lw   $t0, load_header_menu_size
        lw   $t1, save_header_menu_size
        bne  $t0, $t1, load_close_error

        # Read header table size
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, load_header_table_size
        li   $a2, 4
        syscall
        bltz $v0, load_close_error

        lw   $t0, load_header_table_size
        lw   $t1, save_header_table_size
        bne  $t0, $t1, load_close_error

        # Read menus block
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, menus
        li   $a2, MENU_TOTAL_BYTES
        syscall
        bltz $v0, load_close_error

        # Read tables block
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, tables
        li   $a2, TABLE_TOTAL_BYTES
        syscall
        bltz $v0, load_close_error

        # Close file
        li   $v0, 16
        lw   $a0, 4($sp)
        syscall

        # Success message
        la   $a0, load_success_message
        jal  print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 8
        jr   $ra

load_close_error:
        li   $v0, 16
        lw   $a0, 4($sp)
        syscall

load_error:
        la   $a0, load_error_message
        jal  print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 8
        jr   $ra
