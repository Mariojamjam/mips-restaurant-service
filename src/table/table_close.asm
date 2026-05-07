.data
	table_closed_successfully: .asciiz "Table closed successfully"
	invalid_table_code: .asciiz "Non-existent table"
	outstanding_balance: .asciiz "Payment not yet settled. Remaining value: R$ "
	invalid_command_format: .asciiz "The parser detected an invalid format"
	table_not_occupied: .asciiz "The selected table is unoccupied"
	comma: .asciiz ","
	zero_string: .asciiz "0"
.macro print_message %reg
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

        #Restoring preserved registers and closing the stack before returning
	lw   $s0, 4($sp)
	lw   $ra, 0($sp)
	addi $sp, $sp, 8
	jr   $ra
.end_macro 

.text

table_close:
	#Opening stack space to preserve the return address across multiple function calls
        addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)

	#Preparing the arguments for the function parser
        #The parser will receive the command buffer, the command name length,
        #and the number of expected arguments
        la $a0, buffer_space
        li $a1, 11
        li $a2, 1

	#Parsing the command string to separate the table id argument
        jal function_parser

        #If the parser returns a value different from 0, the command format is invalid
        bne $v0, $0, invalid_format

        #Loading the address of the analyzed arguments
	#The argument represents the table you want to close
        lw $t0, parsed_arg1

	#Preparing the table string to be converted from ASCII to integer
	move $a0, $t0
	jal ascii_to_int
	
	#Saving the table number in a temporary record.
	move $t1, $v0        

	#Loading the minimum and maximum valid tables number
        li $t6, 1
        li $t7, 15

        #If the converted id is smaller than 1, the id is invalid
        blt $t1, $t6, invalid_table

        #If the converted id is greater than 15, the id is invalid
        bgt $t1, $t7, invalid_table
        
        #preparing the table ID (code) as an argument to get its address on the table array
        move $a0, $t1
	jal get_table_addr

	#Saving the table address in a temporary record
	move $t2, $v0
	
	#Loading the current table status
	lw $t3, TABLE_STATUS($t2)
	beq $t3, $0, empty_table

	#Loading the accumulated table total
	lw $t4, TABLE_TOTAL($t2)
	
	#Loading the amount already paid by the customer
	lw $t5, TABLE_PAID($t2)

	#Calculating the remaining outstanding balance
	sub $t6, $t4, $t5

	#If the remaining balance is greater than zero,
	#the table cannot be closed yet
	bgtz $t6, incomplete_payment
	
	#Resetting the table status to indicate that it is now unoccupied
	sw $0, TABLE_STATUS($t2)
	
	#Clearing the accumulated table total
	sw $0, TABLE_TOTAL($t2)
	
	#Clearing the accumulated paid amount
	sw $0, TABLE_PAID($t2)
	
	#Initializing the loop counter used to iterate through all order item slots
	li $s0, 0

close_loop:
	#If all 20 order item slots were processed, the cleanup is complete
    	beq $s0, 20, close_done
	
	#Preparing the table id and current menu item id
        #to retrieve the corresponding ORDER_ITEM address
    	move $a0, $t1
    	addi $a1, $s0, 1
    	jal get_table_item_addr

	#Clearing the quantity stored in the current ORDER_ITEM slot
    	sw $0, ORDER_ITEM_QUANTITY($v0)
    	
    	#Clearing the accumulated total value stored in the current ORDER_ITEM slot
    	sw $0, ORDER_ITEM_TOTAL($v0)

	#Advancing to the next ORDER_ITEM slot
    	addi $s0, $s0, 1
   	j close_loop
   	
incomplete_payment:
	#Printing the outstanding balance message
    	la $a0, outstanding_balance
    	jal print_str_mmio

	#Loading the constant value 100 to separate
	#the integer and decimal currency portions
	li $t9, 100

	#Dividing the outstanding balance by 100
	#LO = integer portion
	#HI = decimal portion
	div $t6, $t9

    	#Moving the integer currency portion from LO
	mflo $t7

	#Moving the decimal currency portion from HI
	mfhi $t8

	#Converting the integer portion to string
	move $a0, $t7
	jal int_to_string

	#Printing the integer portion
	move $a0, $v0
	jal print_str_mmio

	#Printing the decimal separator
	la $a0, comma
	jal print_str_mmio

	#If the cents value is smaller than 10,
	#a leading zero must be printed
	blt $t8, 10, print_zeros
	
	j continue_cents
	
print_zeros:
	#Printing a leading zero to preserve the currency decimal format
    	la $a0, zero_string
    	jal print_str_mmio
    	j continue_cents
    	
continue_cents:
	#Converting the cents portion to string
    	move $a0, $t8
    	jal int_to_string

    	#Printing the cents portion
	move $a0, $v0
	jal print_str_mmio
	
	#Restoring the return address and closing the stack before returning
	lw $s0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
	
#Intermediate labels responsible for printing command result messages
close_done:
	print_message table_closed_successfully
invalid_format:
	print_message invalid_command_format
invalid_table:
	print_message invalid_table_code
empty_table:
	print_message table_not_occupied