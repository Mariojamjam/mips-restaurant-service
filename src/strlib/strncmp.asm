strncmp:
        #If num == 0, return 0 immediately
        beq $a3, $zero, strncmp_equal
strncmp_loop:
        #Load current byte from str1
        lb $t0, 0($a0)
        #Load current byte from str2
        lb $t1, 0($a1)
        #If characters differ, go to diff
        bne $t0, $t1, strncmp_diff
        #If both are '\0', strings are equal
        beq $t0, $zero, strncmp_equal
        #Advance str1 pointer
        addi $a0, $a0, 1
        #Advance str2 pointer
        addi $a1, $a1, 1
        #Decrement remaining character count
        addi $a3, $a3, -1
        #If limit reached, return 0
        beq $a3, $zero, strncmp_equal
        #Repeat loop
        j strncmp_loop
strncmp_diff:
        #Return difference between characters
        sub $v0, $t0, $t1
        #Return to caller
        jr $ra
strncmp_equal:
        #Return 0 (equal up to num chars)
        li $v0, 0
        #Return to caller
        jr $ra