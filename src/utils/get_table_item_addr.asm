#This function aims to find the address of a specific ordered item
#inside the order area of a given table.

#Input:
#       $a0: table number
#       $a1: menu item id

#Output:
#       $v0: address of the ORDER_ITEM object inside TABLE_PEDIDO

.include "../data.asm"

get_table_order_item_addr:
        #Moving inputs to temporary registers
        move $t0, $a0
        move $t1, $a1

        #Converting table and item ids to zero-based indexes
        addi $t0, $t0, -1
        addi $t1, $t1, -1

        #Loading the full size of a table object
        li $t2, TABLE_SIZE

        #Calculating the byte offset of the desired table
        mul $t3, $t0, $t2

        #Loading the base address of the tables array
        la $t4, tables

        #Obtaining the base address of the selected table
        add $t4, $t4, $t3

        #Jumping to the pedido area inside the selected table
        addi $t4, $t4, TABLE_PEDIDO

        #Loading the size of one ORDER_ITEM object
        li $t5, ORDER_ITEM_SIZE

        #Calculating the byte offset of the desired item inside pedido
        mul $t6, $t1, $t5

        #Final address = selected table pedido + item offset
        add $v0, $t4, $t6

        jr $ra