#Compares two strings character by character
#Returns 0 if equal, negative or positive if different
#$a0 = str1, $a1 = str2, $v0 = result
strcmp:
strcmp_loop:
        #Load current byte from str1
        lb $t0, 0($a0)
        #Load current byte from str2
        lb $t1, 0($a1)
        #If characters differ, go to diff
        bne $t0, $t1, strcmp_diff
        #If both are '\0', strings are equal
        beq $t0, $zero, strcmp_equal
        #Advance str1 pointer
        addi $a0, $a0, 1
        #Advance str2 pointer
        addi $a1, $a1, 1
        #Repeat loop
        j strcmp_loop
strcmp_diff:
        #Return difference between characters
        sub $v0, $t0, $t1
        #Return to caller
        jr $ra
strcmp_equal:
        #Return 0 (strings are equal)
        li $v0, 0
        #Return to caller
        jr $ra