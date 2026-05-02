memcpy:
        #Copy destination address to temp pointer
        move $t0, $a0
        #Copy source address to temp pointer
        move $t1, $a1
        #Copy num to temp counter limit
        move $t2, $a2
        #Initialize byte counter to 0
        move $t3, $zero
        #Store initial destination address for return
        move $v0, $a0
memcpy_loop:
        #If counter == num, copy is done
        beq $t3, $t2, memcpy_final
        #Load current byte from source
        lb $t4, 0($t1)
        #Store current byte into destination
        sb $t4, 0($t0)
        #Advance destination pointer
        addi $t0, $t0, 1
        #Advance source pointer
        addi $t1, $t1, 1
        #Increment byte counter
        addi $t3, $t3, 1
        #Repeat loop
        j memcpy_loop
memcpy_final:
        #Return to caller
        jr $ra