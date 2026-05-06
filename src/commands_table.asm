#This file aims to link the input to the command defined in commands.asm
#The approach implemented here iters trough the cmd_table using the length to compare strings with the strncmp function

#------- FUNCTION DEFINITION -------

.data
	#Pointer (pt)    | Function name
	pt_test_func: .asciiz "test_func"
	pt_test_func2: .asciiz "test_func2"
	pt_menu_add: .asciiz  "menu_add"
	pt_menu_rm: .asciiz "menu_rm"
	pt_menu_list: .asciiz "menu_list"
	pt_menu_format: .asciiz "menu_format"
	pt_save_all_data: .asciiz "save_all_data"
	
	#==== MESSAGE FOR INVALID COMMNADS ====#
	msg_invalid: .asciiz "Invalid Command"

#This is the commands table, evey command used in the project must be defined here
#Format: POINTER, FUNCTION_NAME, NAME_LENGTH
#The length is used to compare with the strncmp
#The use of strncmp allows to use functions with arguments, but we need to store the length of the function names
commands_table:
	.word pt_test_func, test_func, 9
	.word pt_test_func2, test_func2, 10
	.word pt_menu_add, menu_add, 8
	.word pt_menu_rm, menu_rm, 7
	.word pt_menu_list, menu_list, 9
	.word pt_menu_format, menu_format, 11
	.word pt_save_all_data, save_all_data, 13
	
	#Used for comparison, defining the end of the table.
	.word 0, 0, 0                


#------- COMMANDS TABLE CHECKS TO REDIRECT TO CORRECT FUNCTION -------

.text
#Initial functions, opening the stack
commands_table_init:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	#Using $S0 to store coomands_table adress AS CONSTANT
	#Do NOT change this register in other files
	la $s0, commands_table

commands_table_loop:
	#Using to $s0 as reference to load every part of current row of the tamble
	#pointer
	lw $t1, 0($s0)
	#Label name
	lw $t2, 4($s0)
	#length
	lw $t3, 8($s0)
	
	#Invalid command check
	beq $t2, $0, invalid_command
	
	
	#Loading arguments to the strncmp use
	
	#Loading the current word from the read_string_mmio
	la $a0, buffer_space 
	#Using Label name as argument
	move $a1, $t1
	#Using word length as argument
	move $a3, $t3
	
	#Comparing the string in the buffer with the current label from the commands table
	jal strncmp
	
	#Branch if both strings are equal for the first N (N = Length) chars
	beq $v0, $0, commands_table_jump
	
	#Otherwise, sum 12 to the $s0 register to go to the next label of the table
	addi $s0, $s0, 12
	#Restart loop
	j commands_table_loop

#Before jumping to the function, we must check if the string has a null terminator in the end
#This is a fallback for cases that we have instructions with the same N chars equal
#Example: func and func2, both functions have the first four chars equal. Without this fallback, func2 would be read as func.
commands_table_jump:
	#Loads buffer space
	la $t5, buffer_space
	#Sums buffer space with the length of the label that is candidate to jump
	add $t5, $t5, $t3
	#Loading the byte in the last position of the string.
	lb $t6, 0($t5)
	
	#Branch if $t6, the last char of the string is equal to the null terminator.
	#This means that this was not a false positive
	beq $t6, $0, do_jump
	
	#Loading '-' in the $t7
	li $t7, 45
	#Branch if $t6 is '-'
	beq $t6, $t7, do_jump
	
	#Otherwise, sums 12 to $s0 and jump to the start of the loop. False positive.
	addi $s0, $s0, 12
	#Restarts the loop
	j commands_table_loop

do_jump:
	#Jumps to register $t2, the one that stores the function selected by the user
	jalr $t2
	
	#Restores the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
invalid_command:
	#Load invalid message variable defined in .data
	la $a0, msg_invalid
	#Calls print_str_mmio function
	jal print_str_mmio
	
	#Restores the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
