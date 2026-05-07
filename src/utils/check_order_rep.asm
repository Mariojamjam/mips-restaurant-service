#receives $a0 as the target address of the table
#receives $a1 as the ID (as an int) to be checked against the order
#returns 0 if the ORDER is occupied with the same ID & adds a counter to the quantity
#if it's not occupied, then it returns 1
check_order_rep:
	addi $sp, $sp, -4 #opening the stack to save $ra
	sw   $ra, 0($sp) #saving $ra
	
	move $t0, $a0 #$t0 with the address of the table we have to find the order
	addi $t0, $t0, TABLE_PEDIDO #point exactly to the start of TABLE_PEDIDO
	addi $t1, $t0, 160 #8 bytes * 20 orders = 160
	
	move $t3, $a1 #putting the item ID in $t3 to use it
	
check_order_emp:
	lw $t2, ORDER_ITEM_QUANTITY($t0) #if quantity <= 0, slot is not being used
	blez $t2, increment_order_rep
	j verify_order_id
	
increment_order_rep:
	addi $t0, $t0, ORDER_ITEM_SIZE #jumps a whole order
	blt $t0, $t1, check_order_emp
	j not_found_rep
	
verify_order_id:	
	lw $t4, ORDER_ITEM_ID($t0) #loading the ID into $t4 so we can compare it
	bne $t3, $t4, increment_order_rep
	lw $t5, ORDER_ITEM_QUANTITY($t0) #current quantity
	addi $t5, $t5, 1 #add a counter to the quantity
	sw $t5, ORDER_ITEM_QUANTITY($t0) #store updated quantity

	move $v0, $zero
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
	
not_found_rep:
	li   $v0, 1
	lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
