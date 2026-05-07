#receives $a0 as the target address of the table
#receives $a1 as the ID of the item to be added
#returns 0 after creating a new order in a vacant slot
#returns 1 if the table has no vacant order slot
#Repeated items are handled by check_order_rep before this helper is called
search_order:
	addi $sp, $sp, -4 #opening the stack to save $ra
	sw   $ra, 0($sp) #saving $ra
	
	move $t0, $a0 #$t0 with the address of the table we have to find the order
	addi $t0, $t0, TABLE_PEDIDO #point exactly to the start of TABLE_PEDIDO
	addi $t1, $t0, 160 #used to prevent invading memory (8 bytes x 20 orders = 160)
	
	move $t3, $a1 #putting the item ID (as an int) in $t3 to use it
	
check_order:
	lw $t2, ORDER_ITEM_QUANTITY($t0) #quantity <= 0 means this slot can be reused
	bgtz $t2, increment_order
	j found_order #if they are vacant, this one is executed
	
increment_order:
	addi $t0, $t0, ORDER_ITEM_SIZE #add 8 bytes to get to the next order slot
	blt $t0, $t1, check_order
	j not_found
	
found_order:
	sw $t3, ORDER_ITEM_ID($t0) #$t0 having the address, we store the ID in the ORDER_ITEM_ID
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
