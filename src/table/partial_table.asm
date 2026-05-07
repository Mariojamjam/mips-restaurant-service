.data
        mp_invalid_cmd_msg:    .asciiz "Invalid command"
        mp_table_not_found_msg: .asciiz "Failed: table does not exist"
        mp_table_empty_msg:    .asciiz "Failed: table did not start service"
        mp_item_label:         .asciiz "Item "
        mp_qty_label:          .asciiz " x"
        mp_total_label:        .asciiz "Total: R$ "
        mp_paid_label:         .asciiz "Paid:  R$ "
        mp_debt_label:         .asciiz "Outstanding balance: R$ "
        mp_comma:              .asciiz ","
        mp_newline:            .asciiz "\n"
        mp_zero:               .asciiz "0"

.text
# This function aims to print a consumption report for a specific table.
# It parses the command argument, validates the table number,
# checks if the table is occupied, and prints each ordered item
# with its quantity, the total amount, the amount already paid,
# and the current outstanding balance.
#
# The expected command format is:
# mesa_parcial-<table>
#
# Input:
#       buffer_space: command string previously read from the user
#
# Output:
#       A report is printed listing all orders, total, paid, and balance
#       An error message is printed if the command is invalid
#
# Stack layout:
#       0($sp):  saved $ra
#       4($sp):  table number (integer)
#       8($sp):  table base address

partial_table:
        # Opening stack space
        addi $sp, $sp, -12
        sw   $ra, 0($sp)

        # Preparing arguments for the parser
        la $a0, buffer_space
        li $a1, 13             # length of "partial_table" 
        li $a2, 1               # expected number of arguments: table number

        # Parsing the command string
        jal function_parser

        # If parsing fails, the command format is invalid
        bne $v0, $0, mp_invalid_cmd

        # Loading the parsed table number string address
        lw $t0, parsed_arg1

        # Converting table number from ASCII to integer
        move $a0, $t0
        jal ascii_to_int

        # If ascii_to_int returns -1, the string is invalid
        li $t5, -1
        beq $v0, $t5, mp_table_not_found

        # Valid table range: 1 to 15
        li $t6, 1
        li $t7, 15
        blt $v0, $t6, mp_table_not_found
        bgt $v0, $t7, mp_table_not_found

        # Saving valid table number on the stack
        sw $v0, 4($sp)

        move $a0, $v0           # pass table number as argument
	jal  get_table_addr     # calculate base address of the target table
	move $t3, $v0           # store resulting table address in $t3

        # Saving table base address on the stack
        sw $t3, 8($sp)

        # Checking if the table exists
        lw $t4, TABLE_ID($t3)
        beq $t4, $0, mp_table_not_found

        # Checking if the table is occupied
        lw $t4, TABLE_STATUS($t3)
        beq $t4, $0, mp_table_empty

        # --- Printing order list ---
        # Iterating over the 20 order slots in TABLE_PEDIDO
        lw   $t3, 8($sp)               # reload table base address
        addi $t4, $t3, TABLE_PEDIDO    # pointer to first order slot
        li   $t5, 20                   # 20 possible order slots

mp_order_loop:
        # Loading the item ID from the current order slot
        lw $t6, ORDER_ITEM_ID($t4)

        # If item ID is 0, this slot is empty — skip it
        beq $t6, $0, mp_order_next

        # Save slot pointer and counter before any jal calls
        addi $sp, $sp, -8
        sw   $t4, 0($sp)
        sw   $t5, 4($sp)

        # Printing "Item " label
        la $a0, mp_item_label
        jal print_str_mmio

        # Printing the item ID
        move $a0, $t6
        jal mp_print_int

        # Printing " x" label
        la $a0, mp_qty_label
        jal print_str_mmio

        # Reload slot pointer to safely read quantity
        lw   $t4, 0($sp)
        lw   $a0, ORDER_ITEM_QUANTITY($t4)
        jal mp_print_int

        # Printing newline
        la $a0, mp_newline
        jal print_str_mmio

        # Restore slot pointer and counter after all jal calls
        lw   $t4, 0($sp)
        lw   $t5, 4($sp)
        addi $sp, $sp, 8

mp_order_next:
        # Advancing to the next order slot
        addi $t4, $t4, ORDER_ITEM_SIZE
        addi $t5, $t5, -1
        bgt  $t5, $0, mp_order_loop

        # --- Printing total ---
        la $a0, mp_total_label
        jal print_str_mmio

        lw   $t3, 8($sp)
        lw   $a0, TABLE_TOTAL($t3)
        jal  mp_print_centavos

        la $a0, mp_newline
        jal print_str_mmio

        # --- Printing paid ---
        la $a0, mp_paid_label
        jal print_str_mmio

        lw   $t3, 8($sp)
        lw   $a0, TABLE_PAID($t3)
        jal  mp_print_centavos

        la $a0, mp_newline
        jal print_str_mmio

        # --- Printing outstanding balance (total - paid) ---
        la $a0, mp_debt_label
        jal print_str_mmio

        lw   $t3, 8($sp)
        lw   $t0, TABLE_TOTAL($t3)
        lw   $t1, TABLE_PAID($t3)
        sub  $a0, $t0, $t1
        jal  mp_print_centavos

        la $a0, mp_newline
        jal print_str_mmio

        # Restoring stack and returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 12
        jr   $ra


# -----------------------------
# mp_print_int
# Prints a non-negative integer via MMIO using int_buffer.
# Input: $a0 = integer to print
# Clobbers: $t0-$t4
# -----------------------------
mp_print_int:
        addi $sp, $sp, -4
        sw   $ra, 0($sp)

        # Handle zero as a special case
        bne $a0, $0, mp_print_int_nonzero
        la  $a0, mp_zero
        jal print_str_mmio
        lw  $ra, 0($sp)
        addi $sp, $sp, 4
        jr  $ra

mp_print_int_nonzero:
        # Write digits into int_buffer in reverse, then reverse them
        la   $t0, int_buffer    # pointer to buffer
        move $t1, $a0           # number to convert
        li   $t2, 10            # divisor
        li   $t3, 0             # digit count

mp_int_extract_loop:
        beq  $t1, $0, mp_int_reverse
        div  $t1, $t2
        mflo $t1                # quotient
        mfhi $t4                # remainder (current digit)
        addi $t4, $t4, 48       # convert to ASCII
        sb   $t4, 0($t0)        # store digit
        addi $t0, $t0, 1        # advance buffer pointer
        addi $t3, $t3, 1        # increment digit count
        j    mp_int_extract_loop

mp_int_reverse:
        # Null-terminate the buffer
        sb $0, 0($t0)

        # Reverse the digits in int_buffer
        la   $t0, int_buffer    # start pointer
        addi $t1, $t0, -1
        add  $t1, $t1, $t3     # end pointer (last digit)

mp_reverse_loop:
        bge  $t0, $t1, mp_int_print_buf
        lb   $t4, 0($t0)        # load char from start
        lb   $t2, 0($t1)        # load char from end
        sb   $t2, 0($t0)        # store end char at start
        sb   $t4, 0($t1)        # store start char at end
        addi $t0, $t0, 1
        addi $t1, $t1, -1
        j    mp_reverse_loop

mp_int_print_buf:
        la  $a0, int_buffer
        jal print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra


# -----------------------------
# mp_print_centavos
# Prints an integer value stored in centavos as "XXXX,XX" format.
# Example: 490 -> "4,90"
# Input: $a0 = value in centavos
# -----------------------------
mp_print_centavos:
        addi $sp, $sp, -8
        sw   $ra, 0($sp)

        move $t0, $a0           # save original value

        # Print integer part (centavos / 100)
        li   $t1, 100
        div  $t0, $t1
        mflo $a0                # integer part
        mfhi $t2                # remainder (cents) must be saved before jal calls
        sw   $t2, 4($sp)
        jal  mp_print_int

        # Print comma separator
        la   $a0, mp_comma
        jal  print_str_mmio

        # If cents < 10, print a leading zero
        lw   $t2, 4($sp)
        li   $t3, 10
        bge  $t2, $t3, mp_print_cents_normal
        la   $a0, mp_zero
        jal  print_str_mmio

mp_print_cents_normal:
        lw   $t2, 4($sp)
        move $a0, $t2
        jal  mp_print_int

        lw   $ra, 0($sp)
        addi $sp, $sp, 8
        jr   $ra


# -----------------------------
# ERROR HANDLING
# -----------------------------

mp_invalid_cmd:
        la $a0, mp_invalid_cmd_msg
        jal print_str_mmio
        lw   $ra, 0($sp)
        addi $sp, $sp, 12
        jr   $ra

mp_table_not_found:
        la $a0, mp_table_not_found_msg
        jal print_str_mmio
        lw   $ra, 0($sp)
        addi $sp, $sp, 12
        jr   $ra

mp_table_empty:
        la $a0, mp_table_empty_msg
        jal print_str_mmio
        lw   $ra, 0($sp)
        addi $sp, $sp, 12
        jr   $ra
