#receives $a0 as the target address of the table
#returns the address of the TABLE_PEDIDO that is vacant to add an order to it
#if it's not, then it returns 0
#lacks checking if the position is occupied but the id is the same
search_order:
	addi $sp, $sp, -4 #opening the stack to save $ra
	sw   $ra, 0($sp) #saving $ra
	
	move $t0, $a0 #$t0 with the address of the table we have to find the order
	addi $t1, $t0, 160 #used to prevent invading memory (8 bytes (each order) x 20 (total possible orders) = 160)
	
check_order:
	lw $t2, TABLE_PEDIDO($t0) #loads $t2 with the correct VALUE IN THE ADDRESS that we want to verify
	bne $t2, $zero, increment_order #if they're not 0, then it's being used by another order
	j found_order #if they are vacant, this one is executed
	
increment_order:
	addi $t0, $t0, 8 #add 8 bytes to get to the next table_pedido
	blt $t0, $t1, check_order
	j not_found
	
found_order:
	move $v0, $t0
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
	
not_found:
	move $v0, $zero
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra