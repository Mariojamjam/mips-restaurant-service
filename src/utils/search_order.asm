#receives $a0 as the target address of the table
#receives $a1 as the ID of the item to be added
#returns 1 and adds the order + a counter for quantity in the table if it's vacant
#if it's all occupied, then it returns 0
#lacks checking if the position is occupied but the id is the same, check_order_rep does that
search_order:
	addi $sp, $sp, -4 #opening the stack to save $ra
	sw   $ra, 0($sp) #saving $ra
	
	move $t0, $a0 #$t0 with the address of the table we have to find the order
	addi $t0, $t0, 64 #adding bytes in the table to point exactly to the start of the table_pedido
	addi $t1, $t0, 160 #used to prevent invading memory (8 bytes (each order) x 20 (total possible orders) = 160)
	
	move $t3, $a1 #putting the item ID (as an int) in $t3 to use it
	
check_order:
	lw $t2, TABLE_PEDIDO($t0) #loads $t2 with the correct VALUE IN THE ADDRESS that we want to verify
	bne $t2, $zero, increment_order #if they're not 0, then it's being used by another order
	j found_order #if they are vacant, this one is executed
	
increment_order:
	addi $t0, $t0, 8 #add 8 bytes to get to the next table_pedido
	blt $t0, $t1, check_order
	j not_found
	
found_order:
	sw $t3, ORDER_ITEM_ID($t0) #$t0 having the address, we store the ID in the ORDER_ITEM_ID
	addi $t0, $t0, 4 #adding 4 bytes to jump to the order quantity
	addi $t4, $zero, 1 #loading a 1 to add to the quantity
	sw $t4, ORDER_ITEM_QUANTITY($t0)

	#closing the stack and ending
	move $v0, $zero
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
	
not_found:
	li $v0, 1
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
