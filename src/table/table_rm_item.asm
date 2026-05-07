.data 
	table_remove_sucess_message: .asciiz "Item removed sucessfuly"
	table_not_found_message: .asciiz "Error: the specified table does not exist"
	empty_table_message: .asciiz "Error: table did not start service"
	table_item_not_found_message: .asciiz "Error: This item is not listed on the table order"
        table_invalid_item_code_message: .asciiz "Error: Invalid item code"
        
.macro print_error_message %reg
#This macro is a code-saving mechanism used to reuse the same error printing routine
#with different message labels throughout the program.
#It receives as parameter the label of the message that must be printed,
#calls the MMIO string output function,
#restores the return address from the stack,
#and returns control to the caller.
#
#Expected format:
#       print_error_message message_label

        #Printing the message that indicates a specific reaction to a command
        la   $a0, %reg
        jal  print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 16
        jr   $ra
.end_macro 

.text
#This function aims to remove one unit of a menu item from the order of a specified table.
#It parses the command arguments, validates the informed table number and menu item id,
#checks whether the table exists and has started service,
#finds the corresponding ordered item address inside the table order area,
#verifies whether the item is listed in the table order,
#and decrements its quantity from memory.
#
#The expected command format is:
#mesa_rm_item-table_id-item_id
#
#Input:
#       buffer_space: command string previously read from the user
#
#Output:
#       One unit of the selected item is removed from the specified table order if it exists
#       An error message is printed if the command format is invalid
#       An error message is printed if the specified table does not exist
#       An error message is printed if the specified table has not started service
#       An error message is printed if the informed menu item id is invalid
#       An error message is printed if the informed item is not listed in the table order
#       A success message is printed if the remove operation is completed

table_rm_item:
	#Opening stack space to preserve the return address across multiple function calls
        #Stack layout:
        #       0($sp): saved $ra
        #       4($sp): table id (int)
        #       8($sp): item id (int)
        #       12($sp): table address
        addi $sp, $sp, -16
        sw   $ra, 0($sp)

        #Preparing the arguments for the function parser
        #The parser will receive the command buffer, the command name length,
        #and the number of expected arguments
        la $a0, buffer_space
        li $a1, 13
        li $a2, 2

        #Parsing the command string to separate the item id argument
        jal function_parser

        #If the parser returns a value different from 0, the command format is invalid
        bne $v0, $0, invalid_item_code

        #Loading the address of the analyzed arguments
	#The first argument represents the table and the second the ID of the menu item you want to delete.
        lw $t0, parsed_arg1
	lw $t9, parsed_arg2

	#Preparing the table string to be converted from ASCII to integer
	move $a0, $t0
	jal ascii_to_int
	
	#Saving the table number in a temporary record.
	move $t1, $v0     
	sw $t1, 4($sp)

	#Preparing the table ID string to be converted from ASCII to integer
	move $a0, $t9
	jal ascii_to_int
	
	#Saving the desired menu item number from the table in a temporary record
	move $t2, $v0
	sw   $t2, 8($sp)
	lw $t1, 4($sp)
	
	#Loading the minimum and maximum valid menu item ids 
        li $t6, 1
        li $t7, 15

        #If the converted table number is less than 1, the table is invalid
        blt $t1, $t6, table_not_found

        #If the converted table number is greater than 15, the table is invalid
        bgt $t1, $t7, table_not_found

	#Getting selected table base address
	move $a0, $t1
	jal  get_table_addr
	move $t6, $v0
	sw   $t6, 12($sp)

	#If the current table id is 0, the table does not exist
	lw   $t5, TABLE_ID($t6)
	beq  $t5, $0, table_not_found

	#If the check returns 0, the table is not occupied
	lw   $t5, TABLE_STATUS($t6)
	beq  $t5, $0, empty_table

        #Loading the minimum and maximum valid menu item ids 
        li $t6, 1
        li $t7, 20

        #If the converted id is smaller than 1, the id is invalid
        blt $t2, $t6, invalid_item_code

        #If the converted id is greater than 20, the id is invalid
        bgt $t2, $t7, invalid_item_code

	#Searching linearly through TABLE_PEDIDO to match the storage model used by order_add
	lw   $t6, 12($sp)
	addi $t3, $t6, TABLE_PEDIDO
	addi $t7, $t3, 160

find_order_item:
	lw   $t4, ORDER_ITEM_QUANTITY($t3)
	blez $t4, next_order_item

	lw   $t5, ORDER_ITEM_ID($t3)
	lw   $t2, 8($sp)
	beq  $t5, $t2, remove_found_item

next_order_item:
	addi $t3, $t3, ORDER_ITEM_SIZE
	blt  $t3, $t7, find_order_item
	j    table_item_not_found

remove_found_item:
	#Remove one unit from the order item and update the memory slot
	addi $t4, $t4, -1
	sw   $t4, ORDER_ITEM_QUANTITY($t3)

	#If the quantity reaches 0, clear the stored item id as well
	bgtz $t4, subtract_removed_item_price
	sw   $0, ORDER_ITEM_ID($t3)

subtract_removed_item_price:
	#Decrease the table total by the removed menu item price
	lw   $a0, 8($sp)
	jal  get_menu_item_addr

	move $t8, $v0
	lw   $t6, 12($sp)
	lw   $t5, TABLE_TOTAL($t6)
	lw   $t7, MENU_ITEM_PRICE($t8)
	sub  $t5, $t5, $t7
	sw   $t5, TABLE_TOTAL($t6)

#Macros for printing strings using intermediate labels 

        #Printing the success message after the item is removed
	print_error_message table_remove_sucess_message
	
invalid_item_code:
	print_error_message table_invalid_item_code_message
table_item_not_found:
	print_error_message table_item_not_found_message
empty_table:
	print_error_message empty_table_message
table_not_found:
	print_error_message table_not_found_message
