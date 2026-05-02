#Copies a string from source to destination
#Includes the null terminator ('\0')
#$a0 = destination, $a1 = source, $v0 = destination
strcpy:
        #Copy destination address to temp pointer
        move $t0, $a0
        #Copy source address to temp pointer
        move $t1, $a1
        #Store initial destination address for return
        move $v0, $a0
strcpy_loop:
        #Load current byte from source
        lb $t2, 0($t1)
        #Store current byte into destination
        sb $t2, 0($t0)
        #If null terminator, copy is done
        beq $t2, $zero, strcpy_final
        #Advance destination pointer
        addi $t0, $t0, 1
        #Advance source pointer
        addi $t1, $t1, 1
        #Repeat loop
        j strcpy_loop
strcpy_final:
        #Return to caller
        jr $ra