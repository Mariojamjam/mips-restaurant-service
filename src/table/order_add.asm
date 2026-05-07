#O sistema deve ser capaz de registrar pedidos associados a cada mesa. Cada mesa pode ter até 20 pedidos. 
#Pedidos repetidos não devem introduzir uma nova entrada no registro de pedidos. 
#Um contador para pedidos repetidos deve ser considerado. 

.data
	success_msg: .asciiz "Order placed successfully"
	invalid_order: .asciiz "Invalid code"
	invalid_item: .asciiz "Invalid ID"
	invalid_table: .asciiz "Failed: Table does not exist"
	full_table: .asciiz "Failed: table can't take more orders"
	unavailable_table: .asciiz "Failed: table is not available"
	
	
.text
#This function aims to add a new order to the table array.
#the expected command input is:
#order_add-code-id (code being table code, id being item id)
order_add:
	#Opening stack space to preserve the return address and temporary values
        #Stack layout:
        #       0($sp):  saved $ra
        #       4($sp):  parsed argument 1 address (table code/ID)
        #       8($sp):  parsed argument 2 address (item ID)
        #       12($sp): target table address
        #	20($sp): target menu item address
        #	24($sp): target vacant TABLE_PEDIDO address
        addi $sp, $sp, -24
        sw   $ra, 0($sp)
        
        #Preparing the arguments for the function parser
        #The parser will receive the command buffer, the command name length,
        #and the number of expected arguments
        la $a0, buffer_space
        li $a1, 9 #order_add = 9
        li $a2, 2 #2 arguments: the table code and the order ID. 
        
        #Parsing the command string to separate the menu id, price, and description
        jal function_parser

        #If the parser returns a value different from 0, the command format is invalid
        bne $v0, $zero, error_order
        
        #Loading the parsed argument addresses
        lw $t0, parsed_arg1 #table code
        lw $t1, parsed_arg2 #item id
        
        #Saving the parsed argument addresses on the stack
        #This is necessary because function calls may overwrite temporary registers
        sw $t0, 4($sp) #table code (not translated, pure ascii)
        sw $t1, 8($sp) #item id (not translated, pure ascii)
        
        
#SECTION TO CHECK THE TABLE CODE
        #Preparing the first parsed argument to be converted from ASCII to integer
        #This argument represents the table id (code)
        move $a0, $t0
        jal ascii_to_int
        
        #Loading the minimum and maximum valid table codes
        li $t6, 01
        li $t7, 15
        
        #If the converted code is smaller than 1, the code is invalid
        blt $v0, $t6, error_not_table #error for when the table does not exist

        #If the converted code is greater than 15, the code is invalid
        bgt $v0, $t7, error_not_table
        
        #Saving the valid table code in a temporary register
        move $t0, $v0
        sw   $t0, 4($sp) #now with the table ID in int
        
        #preparing the table ID (code) as an argument to get its address on the table array
        move $a0, $v0
        jal get_table_addr #RETURNS $V0 with the address of the desired table
        
        #Saving the target table address in a temporary register and on the stack
        move $t4, $v0
        sw $t4, 12($sp) #table address
        
        lw $t0, 4($sp) #because $t0 was used to move addresses, we're now reloading it with the table ID
        
        #now I want to check if the table EXISTS, so I need to check if the value on the address is NOT 0
        #if it is 0, this means that this table does not exist
        lw $t5, TABLE_ID($t4) #loads the address of the table that we got from the input and transformed into an address
        beq $t5, $0, error_not_table #if = 0, the ID is 0 which means the table was not initialized.
        
#END OF SECTION

#SECTION TO CHECK THE ITEM ID
	#Preparing the second parsed argument to be converted from ASCII to integer
        #This argument represents the menu item id
        lw $t1, 8($sp) #reload item id string address after previous jal calls
        move $a0, $t1
        jal ascii_to_int #$v0 now has the menu item ID in the int form
        
        #Loading the minimum and maximum valid menu item ids
        li $t8, 1
        li $t9, 20

        #If the converted id is smaller than 1, the id is invalid
        blt $v0, $t8, error_item

        #If the converted id is greater than 20, the id is invalid
        bgt $v0, $t9, error_item

        #Saving the valid menu item id in a temporary register
        move $t1, $v0
        sw   $t1, 8($sp) #item id, now in int, saved on the stack

        #Preparing the menu item id as an argument to get its address in the menu array
        move $a0, $v0
        jal get_menu_item_addr
        
        #Saving the target menu item address in a temporary register and on the stack
        move $t5, $v0
        sw $t5, 20($sp) #target menu item address got
        
        lw $t1, 8($sp) #reloading the item ID on the stack into $t1 

	#Loading the current id stored in the target menu object
        #If the id is 0, the position is NOT being used, which we don't want
        lw $t6, MENU_ITEM_ID($t5) #it overwrites the previous $t6 which had the minimum table code
        beq $t6, $0, error_item
        
#END OF SECTION
#Now we have verified that both the table code and the item exist, while properly adding them to the stack.

######CHECK IF TABLE HAS STATUS AVAILABLE
	lw $a0, 12($sp) #loading $a0 with the desired table address, preparing for check status function
	jal check_table_status
	move $t9, $v0
	beq $t9, $zero, error_table_unavailable

#verify if the table has any item with the same ID as the one passed

	lw $a0, 12($sp) #loading $a0 with the desired table address
	lw $a1, 8($sp) #loading with the ID to be verified
	jal check_order_rep
	move $t7, $v0 #to make operations with the return of the function
	beq $t7, $zero, update_table_total #if it's 0, then it saved the item in a currently existing order
	#if it's not 0, then it can either mean it's a full table, or that it has vacant spots

#VERIFY IF THE TABLE CAN HAVE MORE ORDERS

	lw $a0, 12($sp) #loading $a0 with the desired table address, preparing for search function (redundant)
	lw $a1, 8($sp) #loading with the ID to be verified (redundant)
	jal search_order #return either with the correct address that is vacant or 0
	beq $v0, $zero, update_table_total
	j error_full


update_table_total:
	# Add the selected menu item price to the table total after a successful order
	lw $t4, 12($sp) #table address
	lw $t5, 20($sp) #menu item address
	lw $t6, TABLE_TOTAL($t4)
	lw $t7, MENU_ITEM_PRICE($t5)
	add $t6, $t6, $t7
	sw $t6, TABLE_TOTAL($t4)
	j end_success
	

#generic error when placing the order                
error_order:
        #Printing the generic invalid command message
        la $a0, invalid_order
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 24
        jr   $ra
        

#error for when the table on the input does not exist:      
error_not_table:
        #Printing the invalid command message
        la $a0, invalid_table
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 24
        jr   $ra
        
error_item:
        #Printing the invalid command message
        la $a0, invalid_item
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 24
        jr   $ra
        
error_full:
        #Printing the invalid command message
        la $a0, full_table
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 24
        jr   $ra
        
error_table_unavailable:
        #Printing the invalid command message
        la $a0, unavailable_table
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 24
        jr   $ra
        
end_success:
	#Printing the valid command message
        la $a0, success_msg
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 24
        jr   $ra
