# This function aims to start a service at a specific table.
# It parses the command arguments, validates the table number,
# checks if the table is already occupied, validates the phone length,
# clears residual data from the table structure, stores the table ID,
# and copies the customer phone and name into the table structure.
#
# The expected command format is:
# mesa_iniciar-table-phone-name
#
# Input:
#       buffer_space: command string previously read from the user
#
# Output:
#       The table is marked as occupied, its ID is stored, residual data
#       is cleared, and customer data is written into the table structure.
#       An error message is printed if the command is invalid.
#
# Stack layout:
#       0($sp):  saved $ra
#       4($sp):  parsed table number (integer)
#       8($sp):  parsed argument 2 address (phone string)
#       12($sp): parsed argument 3 address (name string)
#       16($sp): target table base address

.data
        table_start_success_message:  .asciiz "Service started successfully"
        table_start_not_found_message: .asciiz "Failed: table does not exist"
        table_start_occupied_message: .asciiz "Failed: table is occupied"
        table_start_invalid_command_message: .asciiz "Invalid command"

.text
table_start:
        # Opening stack space to preserve return address and temporary values
        addi $sp, $sp, -20
        sw   $ra, 0($sp)

        # Preparing arguments for the parser
        # $a0 = buffer address, $a1 = command name length, $a2 = expected args
        la $a0, buffer_space
        li $a1, 11             # length of "table_start"
        li $a2, 3               # expected number of arguments: table, phone, name

        # Parsing the command string into separate arguments
        jal function_parser

        # If parsing fails, the command format is invalid
        bne $v0, $0, table_start_invalid_cmd

        # Loading the addresses of the parsed arguments
        lw $t0, parsed_arg1     # address of table number string
        lw $t1, parsed_arg2     # address of phone string
        lw $t2, parsed_arg3     # address of name string

        # Saving argument addresses on the stack before any function calls
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)

        # Converting the table number string from ASCII to integer
        move $a0, $t0
        jal ascii_to_int

        # If ascii_to_int returns -1, the string contains invalid characters
        li $t5, -1
        beq $v0, $t5, table_start_not_found

        # Valid table range is 1 to 15
        li $t6, 1
        li $t7, 15

        # If the table number is out of range, report error
        blt $v0, $t6, table_start_not_found
        bgt $v0, $t7, table_start_not_found

        # Saving the valid table number (integer) on the stack
        move $t0, $v0
        sw   $t0, 4($sp)

        move $a0, $t0           # pass table number as argument
	jal  get_table_addr     # calculate base address of the target table
	move $t3, $v0           # store resulting table address in $t3

        # Saving the table base address on the stack
        move $t4, $t3
        sw   $t4, 16($sp)

        # Checking if the table is already occupied (TABLE_STATUS != 0 means occupied)
        lw $t5, TABLE_STATUS($t4)
        bne $t5, $0, table_start_occupied

        # --- Validating phone string length (max 15 chars to fit TABLE_PHONE = 16 bytes) ---
        lw   $a0, 8($sp)        # load phone string address
        li   $t6, 0             # character counter

ts_count_phone_loop:
        lb   $t7, 0($a0)        # load current character
        beq  $t7, $0, ts_phone_ok  # null terminator reached, length is valid
        addi $a0, $a0, 1        # advance pointer
        addi $t6, $t6, 1        # increment counter
        li   $t8, 15
        bgt  $t6, $t8, table_start_not_found  # phone too long, treat as invalid

        j ts_count_phone_loop

ts_phone_ok:
        # Reloading table address from stack after phone validation loop
        lw $t4, 16($sp)

        # --- Marking table as occupied ---
        li $t5, 1
        sw $t5, TABLE_STATUS($t4)

        # --- Storing the table ID in the table structure ---
        lw $t0, 4($sp)          # reload table number
        sw $t0, TABLE_ID($t4)   # write table ID into the structure

        # --- Clearing residual financial data ---
        sw $0, TABLE_TOTAL($t4) # zero out total amount
        sw $0, TABLE_PAID($t4)  # zero out amount already paid

        # --- Zeroing TABLE_PEDIDO area (160 bytes = 40 words) ---
        # This prevents residual order data from a previous session
        addi $t0, $t4, TABLE_PEDIDO  # pointer to start of order area
        li   $t1, 40                 # 160 bytes / 4 bytes per word = 40 iterations
        
ts_name_ok:

ts_zero_pedido_loop:
        sw   $0, 0($t0)         # clear current word
        addi $t0, $t0, 4        # advance to next word
        addi $t1, $t1, -1       # decrement counter
        bgt  $t1, $0, ts_zero_pedido_loop  # repeat until all words are cleared

        # --- Copying phone string into TABLE_PHONE ---
        lw   $t1, 8($sp)        # reload phone string address
        addi $a0, $t4, TABLE_PHONE
        move $a1, $t1
        jal  strcpy

        # --- Copying name string into TABLE_RESP ---
        lw   $t2, 12($sp)       # reload name string address
        addi $a0, $t4, TABLE_RESP
        move $a1, $t2
        jal  strcpy

        # Printing success message
        la $a0, table_start_success_message
        jal print_str_mmio

        # Restoring stack and returning
        lw   $ra, 0($sp)
        addi $sp, $sp, 20
        jr   $ra


# -----------------------------
# ERROR HANDLING
# -----------------------------

table_start_invalid_cmd:
        # Parser failed: command format does not match expected structure
        la $a0, table_start_invalid_command_message
        jal print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 20
        jr   $ra


table_start_not_found:
        # Table number is out of range, non-numeric, or phone string is too long
        la $a0, table_start_not_found_message
        jal print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 20
        jr   $ra


table_start_occupied:
        # Table is already in service
        la $a0, table_start_occupied_message
        jal print_str_mmio

        lw   $ra, 0($sp)
        addi $sp, $sp, 20
        jr   $ra
