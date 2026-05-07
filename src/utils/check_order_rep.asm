#receives $a0 as the target address of the table
#receives $a1 as the ID (as an int) to be checked against the order
#returns 0 if the ORDER is occupied with the same ID & adds a counter to the quantity
#if it's not occupied, then it returns 1
check_order_rep:
	addi $sp, $sp, -4 #opening the stack to save $ra
	sw   $ra, 0($sp) #saving $ra
	
	move $t0, $a0 #$t0 with the address of the table we have to find the order
	addi $t0, $t0, 64 #adding bytes in the table to point exactly to the start of the table_pedido
	addi $t1, $t0, 160 #used to prevent invading memory (8 bytes (each order) x 20 (total possible orders) = 160)
	
	move $t3, $a1 #putting the item ID in $t3 to use it
	
check_order:
	lw $t2, TABLE_PEDIDO($t0) #loads $t2 with the correct VALUE IN THE ADDRESS that we want to verify
	beq $t2, $zero, increment_order #if they're 0, then it's not being used
	j verify_order_id #if they are occupied, this one is executed
	
increment_order:
	addi $t0, $t0, 8 #add 8 bytes to get to the next table_pedido (jumps a whole order)
	blt $t0, $t1, check_order #if less than the limit, continue checking
	j not_found
	
verify_order_id:	
	lw $t4, ORDER_ITEM_ID($t0) #loading the ID into $t4 so we can compare it to the ID in the order we found
	bne $t3, $t4, increment_order #if it's not equal to the ID, we'll continue the loop
	addi $t0, $t0, 4 #adding 4 bytes to the address to access the quantity
	lw $t5, ORDER_ITEM_QUANTITY($t0) #get the value in the desired address to modify it (it's going to be 1 or more)
	addi $t5, $t5, 1 #add a counter to the quantity
	sw $t5, ORDER_ITEM_QUANTITY($t0) #add the new value to the quantity
	#closing things to return
	move $v0, $zero
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
	
not_found:
	li   $v0, 1
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
