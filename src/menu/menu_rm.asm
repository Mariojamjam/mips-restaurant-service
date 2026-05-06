.data
        remove_success_message: .asciiz "Item removed successfully"
        remove_error_message: .asciiz "Error removing menu item"
        item_not_found_message: .asciiz "The informed item code is not registered in the menu"
        invalid_item_code_message: .asciiz "Invalid item code"

.text
#This function aims to remove an item from the menu array.
#It parses the command argument, validates the informed item id,
#finds the corresponding menu item address, checks if the item exists,
#and clears its fields from memory.
#
#The expected command format is:
#menu_rm-id
#
#Input:
#       buffer_space: command string previously read from the user
#
#Output:
#       The selected menu item is cleared from the menu array if it exists
#       An error message is printed if the command format or item id is invalid
#       A not found message is printed if the item is not registered
menu_rm:
        #Opening stack space to preserve the return address across multiple function calls
        addi $sp, $sp, -4
        sw   $ra, 0($sp)

        #Preparing the arguments for the function parser
        #The parser will receive the command buffer, the command name length,
        #and the number of expected arguments
        la $a0, buffer_space
        li $a1, 7
        li $a2, 1

        #Parsing the command string to separate the item id argument
        jal function_parser

        #If the parser returns a value different from 0, the command format is invalid
        bne $v0, $0, error_removing_menu_item

        #Loading the first parsed argument address
        #This argument represents the menu item id
        lw $t0, parsed_arg1

        #Preparing the item id string to be converted from ASCII to integer
        move $a0, $t0
        jal ascii_to_int

        #Loading the minimum and maximum valid menu item ids
        li $t6, 1
        li $t7, 20

        #If the converted id is smaller than 1, the id is invalid
        blt $v0, $t6, error_removing_menu_item

        #If the converted id is greater than 20, the id is invalid
        bgt $v0, $t7, error_removing_menu_item

        #Preparing the menu item id as an argument to get its address in the menu array
        move $a0, $v0
        jal get_menu_item_addr

        #Saving the target menu item address in a temporary register
        move $t1, $v0

        #Loading the current id stored in the target menu object
        #If the id is 0, the item is not registered in the menu
        lw $t2, MENU_ITEM_ID($t1)
        beq $t2, $0, item_not_found

        #Clearing the menu item id field
        sw $0, MENU_ITEM_ID($t1)

        #Clearing the menu item price field
        sw $0, MENU_ITEM_PRICE($t1)
        
        #Loading the address of the description field inside the target menu object
        addi $t3, $t1, MENU_ITEM_DESCRIPTION
        
        #Initializing the loop counter used to clear the description field
        li $t4, 0
        #Loading the number of words that must be cleared from the description field
        #The description has 32 bytes, so it can be cleared using 8 words of 4 bytes
        li $t5, 8


clear_description:
        #Clearing the current word of the description field
        sw $0, 0($t3)

        #Moving the description pointer to the next word
        addi $t3, $t3, 4

        #Incrementing the number of cleared words
        addi $t4, $t4, 1

        #If all 8 words were cleared, finish the remove operation
        beq $t4, $t5, menu_rm_end

        #Continuing the loop until the whole description field is cleared
        j clear_description


menu_rm_end:
        #Printing the success message after the item is removed
        la   $a0, remove_success_message
        jal  print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra


error_removing_menu_item:
        #Printing the message that indicates an invalid item code or command format
        la   $a0, invalid_item_code_message
        jal  print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra


item_not_found:
        #Printing the message that indicates that the item is not registered in the menu
        la   $a0, item_not_found_message
        jal  print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra