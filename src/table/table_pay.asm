#This function aims to register a partial payment for a table.
#It parses the table id and the payment value from the command string,
#validates the table id, checks if the table exists and has already been started,
#then adds the informed payment value to the TABLE_PAID field.
#
#The expected command format is:
#table_pay-id-value
#
#Input:
#       buffer_space: command string previously read from the user
#
#Output:
#       The informed value is added to the table paid amount if the command is valid
#       An error message is printed if the command format or table id is invalid
#       A not found message is printed if the table is not registered
#       A not started message is printed if the table exists but has not been started

.data
        table_pay_not_found_message: .asciiz "Table not found, try another ID"
        table_pay_not_started_message: .asciiz "The stable has not been started, try another table ID"
        table_pay_invalid_message: .asciiz "Invalid table, try another table ID"
        table_pay_success_message: .asciiz "The partial payment was successful. "

.text
table_pay:
        #Opening stack space to preserve the return address and temporary values
        #Stack layout:
        #       0($sp):  saved $ra
        #       4($sp):  parsed argument 1 address
        #       8($sp):  parsed argument 2 address
        #       12($sp): target table address
        addi $sp, $sp, -16
        sw   $ra, 0($sp)

        #Preparing the arguments for the function parser
        #The parser will receive the command buffer, the command name length,
        #and the number of expected arguments
        la   $a0, buffer_space
        li   $a1, 9
        li   $a2, 2
        jal  function_parser

        #If the parser returns a value different from 0, the command format is invalid
        bne  $v0, $0, table_pay_invalid

        #Loading the parsed argument addresses
        #The first argument represents the table id
        #The second argument represents the partial payment value
        lw   $t0, parsed_arg1
        lw   $t1, parsed_arg2

        #Saving the parsed argument addresses on the stack
        #This is necessary because function calls may overwrite temporary registers
        sw   $t0, 4($sp)
        sw   $t1, 8($sp)

        #Preparing the table id string to be converted from ASCII to integer
        move $a0, $t0
        jal  ascii_to_int

        #Loading the minimum and maximum valid table ids
        li   $t6, 1
        li   $t7, 15

        #If the converted table id is smaller than 1, the table id is out of range
        blt  $v0, $t6, table_pay_not_found

        #If the converted table id is greater than 15, the table id is out of range
        bgt  $v0, $t7, table_pay_not_found

        #Preparing the table id as an argument to get its address in the tables array
        move $a0, $v0
        jal  get_table_addr

        #Saving the target table address in a temporary register and on the stack
        move $t4, $v0
        sw   $t4, 12($sp)

        #Loading the table id field from the target table object
        #If the id is 0, the table is not registered
        lw $t5, 0($t4)
        beq $t5, $0, table_pay_not_found

        #Loading the table status field
        #If the status is 0, the table exists but has not been started
        lw $t5, TABLE_STATUS($t4)
        beq $t5, $0, table_pay_not_started

        #Loading the second parsed argument address from the stack
        #This argument represents the partial payment value
        lw $t1, 8($sp)

        #Preparing the payment value string to be converted from ASCII to integer
        move $a0, $t1
        jal ascii_to_int

        #Checking if the conversion failed
        #ascii_to_int returns -1 when the string contains an invalid character
        li $t5, -1
        beq $v0, $t5, table_pay_invalid

        #Loading the target table address again from the stack
        lw $t4, 12($sp)

        #Loading the amount already paid by the table
        lw $t5, TABLE_PAID($t4)

        #Adding the new partial payment value to the current paid amount
        add $t5, $t5, $v0

        #Storing the updated paid amount back into the table object
        sw $t5, TABLE_PAID($t4)

        #Printing the success message after registering the partial payment
        la   $a0, table_pay_success_message
        jal  print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw $ra, 0($sp)
        addi $sp, $sp, 16
        jr $ra


table_pay_invalid:
        #Printing the message that indicates an invalid table or invalid command format
        la $a0, table_pay_invalid_message
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw $ra, 0($sp)
        addi $sp, $sp, 16
        jr $ra


table_pay_not_found:
        #Printing the message that indicates that the informed table id was not found
        la $a0, table_pay_not_found_message
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw $ra, 0($sp)
        addi $sp, $sp, 16
        jr $ra


table_pay_not_started:
        #Printing the message that indicates that the table exists but has not been started
        la $a0, table_pay_not_started_message
        jal print_str_mmio

        #Restoring the return address and closing the stack before returning
        lw $ra, 0($sp)
        addi $sp, $sp, 16
        jr $ra