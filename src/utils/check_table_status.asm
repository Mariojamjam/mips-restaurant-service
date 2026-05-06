#verify if table is available or not
#$a0 = address of the table that we want to check
#$v0 returns 0 if it's unavailable and 1 if it is available

check_table_status:
	addi $sp, $sp, -4 #opening the stack to save $ra
	sw   $ra, 0($sp) #saving $ra
	
	move $t0, $a0 #$t0 with the address of the table we have to find the status
	lw $t1, TABLE_STATUS($t0) #reads the address of the specific table and stores the contents in $t1
	beq $t1, $zero, table_available
	j table_unavailable
	
table_available:
	li $v0, 1
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
        
table_unavailable:
	move $v0, $zero
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra