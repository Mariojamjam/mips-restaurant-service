#---- READ/DISPLAY CHAR FUNCTIONS ----
 
 #Function that verifies the keyboard input
read_char_mmio:
	#Loading Keyboard Control Address
	li $t0, KEYBOARD_CONTROL
	#Reading the control register content
	lw $t0, 0($t0)
	#Checking if the least significative number is 1. The leas significative number is used to define if theres is an input in terminal.
        andi $t1, $t0, 1
        #While loop checking if an input has been entered.
        beq $t1, $0, read_char_mmio
        #Loading Keyboard Data Address
        li $t0, KEYBOARD_DATA
        #Load the keybodard data for future use in $v0
        lw $v0, 0($t0)
        #Jump back to main loop
        jr $ra

#Function that prints keyboard input    
print_char_mmio:
        #Loading Display Control Address
        li $t0, DISPLAY_CONTROL
        #Reading the control register content
        lw $t1, 0($t0)
        #Checking if the least significative number is 1. The leas significative number is used to define if theres is an input in terminal.    
        andi $t1, $t1, 1
        #While loop checking if an input has been entered.
	beq $t1, $0, print_char_mmio
	#Loading Display Data Address
	li $t0, DISPLAY_DATA
	#Storing display data to show on the screen.
	sw $a0, 0($t0)
	#Jump back to main loop
	jr $ra 
    
    
#---- READ STRING FUNCTIONS---

#Function that reads strings, waiting for the "\n" char (Enter)
read_str_mmio:
	#Create space in the stack
	addi $sp, $sp, -4
	#Stores the return adress in the stack
	sw $ra, 0($sp)
	#Load thes buffer space labe
	la $t2, buffer_space
	#Loads the BUFFER_SIZE immediate defined in .data
	li $t3, BUFFER_SIZE
	#Loads the char "\n" char, (Identifies ENTER input)
	li  $t4, 0xA # "\n char hardcoded"
	
	#Backspace value. We are using this to avoid string bugs caused by typing fixes in the middle of the command writing.
	li $t7, 0x08 
	
#Main read string loop
read_str_loop:
	#Uses the read_char_mmio to read the char and store it in the $v0 register
	jal read_char_mmio
	
	#Branches if the the user pressed Enter ("\n")
	beq $v0, $t4, read_str_end
	beq $v0, $t7, backspace_check
	#Store the char with store byte function
	sb $v0, 0($t2)
	#Adds 1 to go to ther next space to store the next char in the buffer
	addi $t2, $t2, 1
	#Subtracting the buffer size to check if is an available string length
	addi $t3, $t3, -1
	#Branches if $t3 > 0, restarts the loop
	bgtz $t3, read_str_loop

#Ending the read string function
read_str_end:
	#Stores the $0 byte as the end of the string
	sb $0, 0($t2)
	#Loads the return adress from the stack
	lw    $ra, 0($sp)
	#Closes the stack
    	addi $sp, $sp, 4
    	#Jump back to main loop
    	jr    $ra
 
#This label deals with the backspace problem.
#By subtracting 1 from $t2, the string pointer of the iteration, we can "ignore" the backspace value.
#Alos, we need to add 1 to the buffer space again to maintain the consitency.
backspace_check:
	#Loading the buffer_space addres
    	la $t5, buffer_space
    	#If we are the start of the string, there is no need to subtract one. The loop will overwrite the undesired symbol.
    	beq $t2, $t5, read_str_loop
    	#Subtracting one from the buffer
    	addi $t2, $t2, -1
    	#Restoring the space that the backspace char took
    	addi $t3, $t3, 1
    	#Back to the loop
    	j read_str_loop
    	
#---- PRINT STRING FUNCTIONS---

#Function that prints strings by calling print_char_mmio in a loop
print_str_mmio:
	#Create space in the stack
	addi $sp, $sp, -4
	#Stores the return adress in the stack
	sw $ra, 0($sp)
	#Stores the string address in argument register
	move $t2, $a0
	
#Main print string loop
print_str_loop:
	#Load the current byte from the string
	lb $t3, 0($t2)
	#Branches if the byte is the null terminator ($0)
	beq $t3, $0, prnt_str_end
	#Move the char to $a0 to be printed
	move $a0, $t3
	#Uses the print_char_mmio to display the char
	jal print_char_mmio
	#Adds 1 to go to the next char in the string
	addi $t2, $t2, 1
	#Restart the loop
	j print_str_loop
	
#Ending the print string function
prnt_str_end:
	#Loads the return adress from the stack
	lw    $ra, 0($sp)
	#Closes the stack
    	addi $sp, $sp, 4
    	#Jump back to main loop
    	jr    $ra
