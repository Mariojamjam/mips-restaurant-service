.data
        table_format_success_message: .asciiz "Todas as mesas foram formatadas com sucesso"
        table_format_invalid_msg: .asciiz "Comando invalido"

.text
# This function aims to reset all tables in the system.
# It iterates over all 15 table slots and clears every field,
# including status, responsible name, phone, total, paid, and orders.
#
# The expected command format is:
# mesa_format
#
# Input:
#       buffer_space: command string previously read from the user
#
# Output:
#       All 15 tables are cleared and set to unoccupied status
#       A success message is printed after the operation
#
# Stack layout:
#       0($sp): saved $ra

table_format:
        # Opening stack space to preserve return address
        addi $sp, $sp, -4
        sw   $ra, 0($sp)

        # Preparing arguments for the parser
        # $a0 = buffer address, $a1 = command name length, $a2 = expected args
        la $a0, buffer_space
        li $a1, 12              # length of "table_format"
        li $a2, 0               # no arguments expected

        # Parsing the command string
        jal function_parser

        # If parsing fails, the command format is invalid
        bne $v0, $0, table_format_invalid_cmd

        # Loading the base address of the tables array
        la  $t0, tables

        # Initializing the table counter (15 tables total)
        li  $t1, 15

# Outer loop — iterates over each of the 15 tables
table_format_table_loop:
        # --- Clearing fixed-size word fields ---

        # Clear TABLE_ID (4 bytes)
        sw $0, TABLE_ID($t0)

        # Clear TABLE_STATUS (4 bytes)
        sw $0, TABLE_STATUS($t0)

        # Clear TABLE_TOTAL (4 bytes)
        sw $0, TABLE_TOTAL($t0)

        # Clear TABLE_PAID (4 bytes)
        sw $0, TABLE_PAID($t0)

        # --- Clearing TABLE_RESP (32 bytes = 8 words) ---
        addi $t2, $t0, TABLE_RESP
        li   $t3, 8

table_format_clear_resp:
        sw   $0, 0($t2)
        addi $t2, $t2, 4
        addi $t3, $t3, -1
        bgt  $t3, $0, table_format_clear_resp

        # --- Clearing TABLE_PHONE (16 bytes = 4 words) ---
        addi $t2, $t0, TABLE_PHONE
        li   $t3, 4

table_format_clear_phone:
        sw   $0, 0($t2)
        addi $t2, $t2, 4
        addi $t3, $t3, -1
        bgt  $t3, $0, table_format_clear_phone

        # --- Clearing TABLE_PEDIDO (160 bytes = 40 words) ---
        addi $t2, $t0, TABLE_PEDIDO
        li   $t3, 40

table_format_clear_pedido:
        sw   $0, 0($t2)
        addi $t2, $t2, 4
        addi $t3, $t3, -1
        bgt  $t3, $0, table_format_clear_pedido

        # Advancing the table pointer to the next table
        addi $t0, $t0, TABLE_SIZE

        # Decrementing the table counter
        addi $t1, $t1, -1

        # If there are still tables to clear, repeat
        bgt  $t1, $0, table_format_table_loop

        # Printing success message after all tables are cleared
        la  $a0, table_format_success_message
        jal print_str_mmio

        # Restoring stack and returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra


# -----------------------------
# ERROR HANDLING
# -----------------------------

table_format_invalid_cmd:
        la  $a0, table_format_invalid_msg  
        jal print_str_mmio
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
