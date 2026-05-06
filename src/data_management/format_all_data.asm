#This function aims to clear all current restaurant data from memory.
#It resets both the menu array and the tables array by storing zero
#in every word of each block.
#
#Input:
#       menus:  menu items array stored in memory
#       tables: tables array stored in memory
#
#Output:
#       All current menu and table data are cleared from RAM
#       A success message is printed through MMIO

.data
        format_success_message: .asciiz "All current data cleared successfully"

.text
format_all_data:
        #Opening stack space to preserve the return address
        addi $sp, $sp, -4
        sw   $ra, 0($sp)

        #Loading the base address of the menus block
        la   $t0, menus
        #Initializing the cleared words counter for the menus block
        li   $t1, 0
        #Loading the total number of words used by the menus block
        li   $t2, MENU_TOTAL_WORDS

format_menus_loop:
        #Clearing the current word from the menus block
        sw   $zero, 0($t0)
        #Moving the pointer to the next word
        addi $t0, $t0, 4
        #Incrementing the number of cleared words
        addi $t1, $t1, 1
        
        #Continuing until the whole menus block is cleared
        bne  $t1, $t2, format_menus_loop
        
        #Loading the base address of the tables block
        la   $t0, tables
        #Resetting the cleared words counter for the tables block
        li   $t1, 0
        #Loading the total number of words used by the tables block
        li   $t2, TABLE_TOTAL_WORDS

format_tables_loop:
        #Clearing the current word from the tables block
        sw   $zero, 0($t0)
        #Moving the pointer to the next word
        addi $t0, $t0, 4
        #Incrementing the number of cleared words
        addi $t1, $t1, 1

        #Continuing until the whole tables block is cleared
        bne  $t1, $t2, format_tables_loop

        #Printing the success message after clearing all current data
        la   $a0, format_success_message
        jal  print_str_mmio
        
        #Restoring the return address from the stack
        lw   $ra, 0($sp)
        #Closing the stack space used by this function
        addi $sp, $sp, 4
        #Returning to the caller
        jr   $ra
