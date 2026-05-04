#This function aims to transforma a string of digits in an int
#This can be achieved by iterating over the list, ordering the orders of magnitude with a counter, and adding the current byte to the counter.

#Valid String: returns the string translated to int in $v0
#Invalid String: returns -1 in #v0
ascii_to_int:
	#Storing the string that will be transformed in int in a temporary register
	move $t0, $a0
	#Temporary register used as a counter
	li $t1, 0
	#Loads 10 in the $t5 register for future multiplications
	li $t5, 10
	
	#We are using hardcoded numbers equivalents in ASCII
	#By subtracting 48 (the int that represents '0' in ascii), we can transform every digit in the range of 0-9 to it's int form.
	
	# '0' in Ascii
	li $t6, 48
	# '9' in Ascii
	li  $t7, 57

ascii_to_int_loop:
	#Loading the byte in $t2 from te pointer loaded in $t0
	lb $t2, 0($t0)
	#If the string endend, branch to the result
	beq $t2, $0, result
	
	#Checking if the  0 < $t2 < 9 
	blt $t2, $t6, invalid_byte 
	bgt $t2, $t7, invalid_byte
	
	#Subtracting 48 to find the real int value
	addi $t3, $t2, -48
	
	#Multiplying the current value in the counter by 10, adding one order of magnitude
	mul $t1, $t1, $t5
	#Adding the current int value to the counter
	add $t1, $t1, $t3
	
	#Going to the next byte by adding 1 to the pointer
	addi $t0, $t0, 1
	
	#Restart loop
	j ascii_to_int_loop
	
#Returns #-1 if the string has an invalid char
invalid_byte:
	li $v0, -1
	jr $ra
#Returns the value if the iteration has ended without erros
result:
	move $v0, $t1
	jr $ra
	
