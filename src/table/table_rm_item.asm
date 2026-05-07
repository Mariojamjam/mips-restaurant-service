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
        addi $sp, $sp, 4
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
        addi $sp, $sp, -4
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

	#Preparing the table ID string to be converted from ASCII to integer
	move $a0, $t9
	jal ascii_to_int
	
	#Saving the desired menu item number from the table in a temporary record
	move $t2, $v0      

	#Loading the minimum and maximum valid menu item ids 
        li $t6, 1
        li $t7, 15

        #If the converted table number is less than 1, the table is invalid
        blt $t1, $t6, table_not_found

        #If the converted table number is greater than 15, the table is invalid
        bgt $t1, $t7, table_not_found

	#Getting selected table base address
	addi $t8, $t1, -1
	li   $t7, TABLE_SIZE
	mul  $t8, $t8, $t7
	la   $t6, tables
	add  $t6, $t6, $t8

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

        #Preparing the menu item id as an argument to get its address in the menu array
        move $a0, $t6
        move $a1, $t2
        jal get_table_item_addr 
        
        #Saving the target menu item address in a temporary register
        move $t3, $v0
        
        #Loading the current id stored in the target menu object
        #If the id is 0, the item is not registered in the menu
        beq $t3, $0, table_item_not_found
        lw $t4, ORDER_ITEM_QUANTITY($t3)
        
        #If quantity <= 0, item is not listed
	blez $t4, table_item_not_found
        
        #Remove one unit from the order item and update the memory slot
        addi $t4, $t4, -1
	sw $t4, ORDER_ITEM_QUANTITY($t3)

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
