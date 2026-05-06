#This function aims to find the address of an item inside a specific table order.
#Each table stores 20 menu item slots sequentially in memory.
#The function calculates the exact address of the desired item
#based on the table number and the menu item id.

#Input:
#       $a0: table number
#       $a1: menu item id

#Output:
#       $v0: address of the desired item slot inside the table order array

get_table_item_addr:
        #Moving the table number and item id to temporary registers
        move $t0, $a0
        move $t1, $a1

        #Converting both values to zero-based indexes
        addi $t0, $t0, -1
        addi $t1, $t1, -1

        #Loading the number of items stored per table
        li $t2, 20

        #Calculating the starting logical index of the table
        mul $t3, $t0, $t2

        #Adding the item index inside that table
        add $t3, $t3, $t1

        #Loading the size of each stored table-order item
        li $t4, 4

        #Converting logical index into byte offset
        mul $t5, $t3, $t4

        #Loading the base address of the table orders array
        la $t6, table_orders

        #Adding the calculated offset to the base address
        add $v0, $t6, $t5

        #Returning to caller
        jr $ra