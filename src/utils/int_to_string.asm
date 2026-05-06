#This function aims to transform an integer into a string.
#The conversion is done by repeatedly dividing the integer by 10,
#extracting the remainder as the current digit, converting it to ASCII,
#and storing the digits from right to left inside int_buffer.
#
#Since the digits are found from the least significant to the most significant,
#the buffer pointer starts at the end of int_buffer and moves backwards.
#
#Input:
#       $a0: integer value to be converted
#
#Output:
#       $v0: address of the converted string inside int_buffer
int_to_string:
        #Opening stack space to preserve the return address
        addi $sp, $sp, -4

        #Saving the return address because this function may return after branching
        sw $ra, 0($sp)

        #Moving the integer value to a temporary register
        move $t0, $a0

        #Loading the ASCII value of '0'
        #Adding this value to a digit from 0 to 9 transforms it into its ASCII character
        li $t6, 48

        #Loading the base address of the integer conversion buffer
        la $t5, int_buffer

        #Moving the pointer to the last position of the buffer
        #This allows the function to write digits from right to left
        addi $t5, $t5, 15

        #Adding the string terminator at the end of the generated string
        sb $0, 0($t5)

        #If the integer value is 0, handle it as a special case
        beq $t0, $0, print_zero


int_to_string_loop:
        #Loading 10 as the divisor used to extract decimal digits
        li $t1, 10

        #Moving the buffer pointer one position backwards
        #The next digit will be stored in this position
        addi $t5, $t5, -1

        #Dividing the current number by 10
        #The remainder is the current digit
        #The quotient is the remaining number to be processed
        div  $t0, $t1
        mfhi $t2
        mflo $t0

        #Converting the current digit into its ASCII character
        add  $t2, $t2, $t6

        #Storing the converted digit in the current buffer position
        sb $t2, 0($t5)

        #If there are still remaining digits, continue the conversion loop
        bne $t0, $0, int_to_string_loop

        #Returning the address of the first character of the generated string
        move $v0, $t5

        #Restoring the return address from the stack
        lw    $ra, 0($sp)

        #Closing the stack space used by this function
        addi $sp, $sp, 4

        #Returning to the caller
        jr    $ra


print_zero:
        #Moving the buffer pointer one position backwards to store the '0' character
        addi $t5, $t5, -1

        #Storing the ASCII character '0' in the buffer
        sb $t6, 0($t5)

        #Returning the address of the generated string
        move $v0, $t5

        #Restoring the return address from the stack
        lw    $ra, 0($sp)

        #Closing the stack space used by this function
        addi $sp, $sp, 4

        #Returning to the caller
        jr    $ra