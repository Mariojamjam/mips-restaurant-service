#This function aims to load all restaurant data from a binary file.
#It opens the save file in read mode, reads and validates the file header,
#then loads the menus block and the tables block back into memory.
#
#The file structure expected by this function is:
#       4 bytes: save header signature
#       4 bytes: menu block size
#       4 bytes: table block size
#       N bytes: menus block
#       N bytes: tables block
#
#The header is validated before loading the main data blocks.
#This avoids loading data from an invalid or incompatible save file.
#
#Input:
#       save_file_name: file name used to read the binary data
#       save_header_signature: expected identifier of a valid save file
#       save_header_menu_size: expected size of the menus block
#       save_header_table_size: expected size of the tables block
#
#Output:
#       The menus and tables arrays are restored from the save file
#       A success message is printed if the data was loaded correctly
#       An error message is printed if the file could not be opened, read, or validated
.data
        load_success_message: .asciiz "Loaded data sucessfully"
        load_error_message:   .asciiz "Error loading data"

.text
load_all_data:
        #Opening stack space to preserve the return address and the file descriptor
        #Stack layout:
        #       0($sp): saved $ra
        #       4($sp): file descriptor
        addi $sp, $sp, -12
        sw   $ra, 0($sp)
        sw $a2, 8($sp)

        #Opening the save file in read mode
        #Syscall 13 receives:
        #       $a0: file name address
        #       $a1: file open flag
        #       $a2: file mode
        li   $v0, 13
        la   $a0, save_file_name
        li   $a1, 0
        li   $a2, 0
        syscall

        #If the returned file descriptor is negative, the file could not be opened
        bltz $v0, load_error

        #Saving the file descriptor on the stack because it will be reused in multiple syscalls
        sw   $v0, 4($sp)

        #Reading the save file signature into the load header signature variable
        #This value will be compared against the expected signature
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, load_header_signature
        li   $a2, 4
        syscall

        #If the read syscall returns a negative value, close the file and report an error
        bltz $v0, load_close_error

        #Loading the signature read from the file and the expected signature
        lw   $t0, load_header_signature
        lw   $t1, save_header_signature

        #If the signatures are different, the file is not considered valid
        bne  $t0, $t1, load_close_error

        #Reading the menu block size stored in the save file header
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, load_header_menu_size
        li   $a2, 4
        syscall

        #If the read syscall returns a negative value, close the file and report an error
        bltz $v0, load_close_error

        #Loading the menu size read from the file and the expected menu size
        lw   $t0, load_header_menu_size
        lw   $t1, save_header_menu_size

        #If the menu sizes are different, the save file is incompatible
        bne  $t0, $t1, load_close_error

        #Reading the table block size stored in the save file header
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, load_header_table_size
        li   $a2, 4
        syscall

        #If the read syscall returns a negative value, close the file and report an error
        bltz $v0, load_close_error

        #Loading the table size read from the file and the expected table size
        lw   $t0, load_header_table_size
        lw   $t1, save_header_table_size

        #If the table sizes are different, the save file is incompatible
        bne  $t0, $t1, load_close_error

        #Reading the full menus block from the save file
        #The block is loaded directly into the menu array memory area
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, menus
        li   $a2, MENU_TOTAL_BYTES
        syscall

        #If the read syscall returns a negative value, close the file and report an error
        bltz $v0, load_close_error

        #Reading the full tables block from the save file
        #The block is loaded directly into the tables array memory area
        li   $v0, 14
        lw   $a0, 4($sp)
        la   $a1, tables
        li   $a2, TABLE_TOTAL_BYTES
        syscall

        #If the read syscall returns a negative value, close the file and report an error
        bltz $v0, load_close_error

        #Closing the save file after all data was loaded
        li   $v0, 16
        lw   $a0, 4($sp)
        syscall

	li $t8, 1
	lw $a2, 8($sp)
	beq $a2, $t8, restore_stack
	
        #Printing the success message after loading all data
        la   $a0, load_success_message
        jal  print_str_mmio

restore_stack:
        #Restoring the return address from the stack
        lw   $ra, 0($sp)

        #Closing the stack space used by this function
        addi $sp, $sp, 12

        #Returning to the caller
        jr   $ra


load_close_error:
        #Closing the save file before leaving after a read or validation error
        #This avoids leaving the file descriptor open
        li   $v0, 16
        lw   $a0, 4($sp)
        syscall


load_error:
	#If boot mode requested silent loading, return without printing messages
	li $t8, 1
	lw $a2, 8($sp)
	beq $a2, $t8, restore_stack

        #Printing the generic load error message
        la   $a0, load_error_message
        jal  print_str_mmio

        j restore_stack
