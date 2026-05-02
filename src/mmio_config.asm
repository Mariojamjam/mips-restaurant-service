 
 #---- READ/DISPLAY CHAR FUNCTIONS ----
 
 #Function that verifies the keyboard input
read_char_mmio:
	#Loading Keyboard Address
        lw $t0, KEYBOARD_CONTROL
        #Checking if the least significative number is 1. The leas significative number is used to define if theres is an input in terminal.
        andi $t1, $t0, 1
        #While loop checking if an input has been entered.
        beq $t1, $0, read_char_mmio

        #Load the keybodard data for future use in $v0
        lw $v0, KEYBOARD_DATA
        #Jump back to main loop
        jr $ra

#Function that prints keyboard input    
print_char_mmio:
        #Loading Display Address
        lw $t0, DISPLAY_CONTROL
        #Checking if the least significative number is 1. The leas significative number is used to define if theres is an input in terminal.    
        andi $t1, $t0, 1
        #While loop checking if an input has been entered.
	beq $t1, $0, print_char_mmio

	#Storing display data to show on the screen.
	sw $a0, DISPLAY_DATA
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

#Main read string loop
read_str_loop:
	#Uses the read_char_mmio to read the char and store it in the $v0 register
	jal read_char_mmio
	
	#Branches if the the user pressed Enter ("\n")
	beq $v0, $t4, read_str_end
	#Store the char with store byte function
	sb $v0, 0($t2)
	#Adds 1 to go to ther next space to store the next char in the buffer
	addi $t2, $t2, 1
	#Subtracting the buffer size to check if is an available string length
	addi $t3, $t3, -1
	#Branches if $t3 > 0, restarts the loop
	bgtz $t3, read_str_loop
	
read_str_end:
	#Stores the $0 byte as the end of the string
	sb $0, 0($t2)
	#Loads the return adress from the stack
	lw    $ra, 0($sp)
	#Closes the stack
    	addi $sp, $sp, 4
    	jr    $ra
    	
    	
#---- PRINT STRING FUNCTIONS---
print_str_mmio:
	#Create space in the stack
	addi $sp, $sp, -4
	#Stores the return adress in the stack
	sw $ra, 0($sp)
	#Stores the string address in argument register
	move $t2, $a0
	
print_str_loop:
	
	lb $t3, 0($t2)
	beq $t3, $0, prnt_str_end
	move $a0, $t3
	jal print_char_mmio
	addi $t2, $t2, 1
	j print_str_loop
	
	
prnt_str_end:
	lw    $ra, 0($sp)
    	addi $sp, $sp, 4
    	jr    $ra



