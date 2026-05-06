#This function aims to list all registered items in the menu array.
#It iterates over every menu item position, checks if the item is registered,
#and prints the item id, price, and description.
#
#The menu array has 20 positions.
#Each position is checked by reading the MENU_ITEM_ID field.
#If the id is 0, the item is considered empty and is skipped.
#
#Input:
#       menus: menu items array stored in memory
#
#Output:
#       Prints all registered menu items through MMIO

.data
        menu_list_message: .asciiz "================ Menu List ================"

.text
menu_list:
        #Opening stack space to preserve the return address and loop values
        #Stack layout:
        #       0($sp):  saved $ra
        #       4($sp):  current menu item pointer
        #       8($sp):  current loop counter
        #       12($sp): total number of menu positions
        addi $sp, $sp, -16

        #Saving the return address because this function calls other functions
        sw $ra, 0($sp)

        #Loading the base address of the menu array
        la $t0, menus

        #Initializing the loop counter
        li $t1, 0

        #Loading the total number of menu positions that will be checked
        li $t2, 20

        #Saving the initial loop values on the stack
        #This is necessary because function calls may overwrite temporary registers
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)

        #Printing a line break before the menu list header
        li  $a0, 0xA
        jal print_char_mmio

        #Printing the menu list header message
        la $a0, menu_list_message
        jal print_str_mmio

        #Printing a line break after the menu list header
        li  $a0, 0xA
        jal print_char_mmio


menu_list_loop:
        #Restoring the current menu item pointer, loop counter, and loop limit
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)

        #Loading the id of the current menu item
        #If the id is 0, this menu position is empty and should not be printed
        lw $t7, MENU_ITEM_ID($t0)
        beq $t7, $0, add_and_restart

        #Printing the id label
        la $a0, msg_id
        jal print_str_mmio

        #Loading the current menu item id
        lw $t0, 4($sp)
        lw $t4, MENU_ITEM_ID($t0)

        #Converting the integer id into a string before printing through MMIO
        move $a0, $t4
        jal int_to_string

        #Printing the converted menu item id
        move $a0, $v0
        jal print_str_mmio

        #Printing the price label
        la $a0, msg_price
        jal print_str_mmio

        #Loading the current menu item price
        lw $t0, 4($sp)
        lw $t4, MENU_ITEM_PRICE($t0)

        #Converting the integer price into a string before printing through MMIO
        move $a0, $t4
        jal int_to_string

        #Printing the converted menu item price
        move $a0, $v0
        jal print_str_mmio

        #Printing the description label
        la $a0, msg_description
        jal print_str_mmio

        #Loading the current menu item address again
        #Then moving the argument to the description field address
        lw $t0, 4($sp)
        addi $a0, $t0, MENU_ITEM_DESCRIPTION

        #Printing the menu item description
        jal print_str_mmio

        #Printing a line break after the current menu item
        li  $a0, 0xA
        jal print_char_mmio


add_and_restart:
        #Restoring the current menu item pointer, loop counter, and loop limit
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)

        #Incrementing the loop counter to indicate that one position was checked
        addi $t1, $t1, 1

        #Moving the menu item pointer to the next object in the menu array
        addi $t0, $t0, MENU_ITEM_SIZE

        #Saving the updated menu item pointer and loop counter on the stack
        sw $t0, 4($sp)
        sw $t1, 8($sp)

        #If the loop counter has not reached the limit, continue checking menu items
        bne $t2, $t1, menu_list_loop


end_of_loop_menu_list:
        #Restoring the return address from the stack
        lw   $ra, 0($sp)

        #Closing the stack space used by this function
        addi $sp, $sp, 16

        #Returning to the caller
        jr   $ra