# get_table_addr
# Calculates the base address of a table given its number.
# Input:  $a0 = table number (1 to 15)
# Output: $v0 = base address of the table structure
# Clobbers: $t0, $t1

get_table_addr:
        addi $t0, $a0, -1       # convert to zero-based index
        li   $t1, TABLE_SIZE    # size of each table structure
        mul  $t0, $t0, $t1      # byte offset
        la   $v0, tables        # base address of tables array
        add  $v0, $v0, $t0      # final address
        jr   $ra
