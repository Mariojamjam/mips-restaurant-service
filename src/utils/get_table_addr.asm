#function to find the address of a table based on its ID (code)
#Since the tables IDs are stored sequentially in memory, the address can be found
#by calculating the offset of the desired item inside the table array.

#Input:
#       $a0: table id (code)

#Output:
#       $v0: address of the desired table
get_table_addr:
        #Moving the current table id to a temporary register
        move $t0, $a0

        #Loading the size of a single table object
        li $t1, TABLE_SIZE

        #Subtracting 1 from the id to convert it into a zero-based array index
        addi $t0, $t0, -1

        #Multiplying the zero-based index by the size of a single table
        #This gives the byte offset of the desired table inside the table array
        mul $t2, $t1, $t0

        #Loading the base address of the table array
        la $t3, tables

        #Adding the calculated offset to the base address
        #This gives the final address of the desired table
        add $v0, $t3, $t2

        #Returning to the caller with the table address stored in $v0
        jr $ra
