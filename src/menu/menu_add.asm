.data
        item_already_exists_message: .asciiz "Item already exists!"
        sucess_message: .asciiz "item added successfully"

        msg_id: .asciiz "ID: "
        msg_price: .asciiz " | Price: "
        msg_description: .asciiz " | Description: "
        newline: .asciiz "\n"

.text
#This function aims to add a new item to the menu array.
#It parses the command arguments, validates the item id, checks if the item already exists,
#converts the id and price from ASCII strings to integers, and stores the new item data
#inside the correct menu object position.
#
#The expected command format is:
#menu_add-id-price-description
#
#Input:
#       buffer_space: command string previously read from the user
#
#Output:
#       A new menu item is stored in the menu array if the command is valid
#       An error message is printed if the command format or data is invalid
menu_add:
        #Opening stack space to preserve the return address and temporary values
        #Stack layout:
        #       0($sp):  saved $ra
        #       4($sp):  parsed argument 1 address
        #       8($sp):  parsed argument 2 address
        #       12($sp): parsed argument 3 address
        #       16($sp): target menu item address
        addi $sp, $sp, -20
        sw   $ra, 0($sp)

        #Preparing the arguments for the function parser
        #The parser will receive the command buffer, the command name length,
        #and the number of expected arguments
        la $a0, buffer_space
        li $a1, 8
        li $a2, 3

        #Parsing the command string to separate the menu id, price, and description
        jal function_parser

        #If the parser returns a value different from 0, the command format is invalid
        bne $v0, $0, error_menu

        #Loading the parsed argument addresses
        lw $t0, parsed_arg1
        lw $t1, parsed_arg2
        lw $t2, parsed_arg3

        #Saving the parsed argument addresses on the stack
        #This is necessary because function calls may overwrite temporary registers
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)

        #Preparing the first parsed argument to be converted from ASCII to integer
        #This argument represents the menu item id
        move $a0, $t0
        jal ascii_to_int

        #Loading the minimum and maximum valid menu item ids
        li $t6, 1
        li $t7, 20

        #If the converted id is smaller than 1, the id is invalid
        blt $v0, $t6, error_menu

        #If the converted id is greater than 20, the id is invalid
        bgt $v0, $t7, error_menu

        #Saving the valid menu item id in a temporary register
        move $t0, $v0

        #Preparing the menu item id as an argument to get its address in the menu array
        move $a0, $v0
        jal get_menu_item_addr

        #Saving the target menu item address in a temporary register and on the stack
        move $t4, $v0
        sw $t4, 16($sp)

        #Loading the current id stored in the target menu object
        #If the id is different from 0, the position is already being used
        lw $t5, MENU_ITEM_ID($t4)
        bne $t5, $0, item_already_exists

        #Storing the new item id in the target menu object
        sw $t0, MENU_ITEM_ID($t4)

        #Loading the second parsed argument address from the stack
        #This argument represents the menu item price
        lw $t1, 8($sp)

        #Preparing the price string to be converted from ASCII to integer
        move $a0, $t1
        jal ascii_to_int

        #Checking if the conversion failed
        #ascii_to_int returns -1 when the string contains an invalid character
        li $t5, -1
        beq $v0, $t5, error_menu

        #Saving the converted menu item price in a temporary register
        move $t0, $v0

        #Loading the target menu item address again from the stack
        lw $t4, 16($sp)

        #Storing the converted price in the target menu object
        sw $t0, MENU_ITEM_PRICE($t4)

        #Loading the third parsed argument address from the stack
        #This argument represents the menu item description
        lw $t2, 12($sp)

        #Preparing the destination and source addresses for strcpy
        #The destination is the description field inside the target menu object
        #The source is the third parsed argument string
        addi $a0, $t4, MENU_ITEM_DESCRIPTION
        move $a1, $t2
        jal strcpy

        #Printing the success message after the item is stored
        la $a0, sucess_message
        jal print_str_mmio

        #Loading the target menu item address again to print its fields for debugging
        lw $t4, 16($sp)

        #=======================================================================
        #=============== DEBUG TEST, SYSCALL USED TO OBSERVE THE MENU OBJECTS ==

        #Printing the id label
        la   $a0, msg_id
        li   $v0, 4
        syscall

        #Printing the stored menu item id
        lw   $a0, MENU_ITEM_ID($t4)
        li   $v0, 1
        syscall

        #Printing the price label
        la   $a0, msg_price
        li   $v0, 4
        syscall

        #Printing the stored menu item price
        lw   $a0, MENU_ITEM_PRICE($t4)
        li   $v0, 1
        syscall

        #Printing the description label
        la   $a0, msg_description
        li   $v0, 4
        syscall

        #Printing the stored menu item description
        addi $a0, $t4, MENU_ITEM_DESCRIPTION
        li   $v0, 4
        syscall

        #Printing a line break after the debug output
        la   $a0, newline
        li   $v0, 4
        syscall

        #=============== DEBUG TEST, SYSCALL USED TO OBSERVE THE MENU OBJECTS ==
        #=====================================================================

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 20
        jr   $ra


error_menu:
        #Printing the generic invalid command message
        la $a0, msg_invalid
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 20
        jr   $ra


item_already_exists:
        #Printing the message that indicates that the target menu position is already being used
        la $a0, item_already_exists_message
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 20
        jr   $ra