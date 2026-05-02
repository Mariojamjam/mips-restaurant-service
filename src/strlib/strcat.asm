#Appends source to the end of destination
#Replaces destination null terminator with first char of source
#$a0 = destination, $a1 = source, $v0 = destination
strcat:
        #Copy destination address to temp pointer
        move $t0, $a0
strcat_find_end:
        #Load current byte from destination
        lb $t1, 0($t0)
        #If '\0' found, start copying here
        beq $t1, $zero, strcat_copy
        #Advance destination pointer
        addi $t0, $t0, 1
        #Continue searching for end
        j strcat_find_end
strcat_copy:
        #Load current byte from source
        lb $t2, 0($a1)
        #Write byte into destination
        sb $t2, 0($t0)
        #If null terminator copied, done
        beq $t2, $zero, strcat_final
        #Advance source pointer
        addi $a1, $a1, 1
        #Advance destination pointer
        addi $t0, $t0, 1
        #Repeat copy loop
        j strcat_copy
strcat_final:
        #Return original destination address
        move $v0, $a0
        #Return to caller
        jr $ra