# MIPS Restaurant Service

Assembly MIPS project for the MARS simulator. The goal of the project is to build a restaurant terminal capable of managing menu items, tables, orders, and persistent storage through a command-driven shell.

At its current stage, the repository already contains the shell backbone, MMIO support for keyboard and display, a custom string library, and a command dispatch table. It is not yet the full system required by the assignment, but the current architecture is already a good foundation for incremental development.

## Project goal

The final system is expected to:

- manage up to 20 menu items
- manage up to 15 active tables
- register up to 20 orders per table, with quantity tracking for repeated items
- support partial payments
- generate table consumption reports
- close tables only when the remaining balance is zero
- save and reload data from external files
- run as a text command terminal

## Current status

The project currently provides:

- a separate entry point
- the main shell loop
- a terminal banner
- line input through Keyboard MMIO
- character and string output through Display MMIO
- a string library with `strcpy`, `memcpy`, `strcmp`, `strncmp`, and `strcat`
- a command table that matches text input and jumps to a routine
- an initial memory model for menu items, tables, and orders
- test commands (`test_func` and `test_func2`) to validate shell execution flow

What is still missing:

- restaurant business rules
- command option parsing
- the commands required by the assignment
- file persistence

## Repository structure

```text
src/
  entry.asm
  main.asm
  data.asm
  mmio_config.asm
  commands_table.asm
  commands.asm
  strlib/
    strcpy.asm
    memcpy.asm
    strcmp.asm
    strncmp.asm
    strcat.asm
Mars4_5.jar
```

## Implemented architecture

### 1. Program flow

The actual entry point is in `src/entry.asm`, which only transfers control to `main`.

`src/main.asm` contains the shell loop:

1. print the banner
2. read one line into `buffer_space`
3. dispatch the command through the command table
4. print a newline
5. jump back to the start

This is a good shell design because the global control flow stays simple and centralized.

### 2. MMIO layer

`src/mmio_config.asm` concentrates all communication with the simulated MARS peripherals:

- `read_char_mmio`
- `print_char_mmio`
- `read_str_mmio`
- `print_str_mmio`

This separation matters because it prevents MMIO polling logic and hardware addresses from leaking into business code. The rest of the system can think in terms of "read string" and "print string" instead of manually operating the device registers everywhere.

### 3. Data layer

`src/data.asm` defines:

- structure offsets
- record sizes
- allocated memory for menus and tables
- MMIO addresses
- the input buffer
- the terminal banner

The main design idea is to treat records as offset-based objects. In MIPS Assembly, this is much easier to scale than scattering unrelated variables across memory.

Examples:

- `TABLE_ID`
- `TABLE_STATUS`
- `TABLE_RESP`
- `TABLE_PHONE`
- `TABLE_TOTAL`
- `TABLE_PAID`
- `TABLE_PEDIDO`

These offsets let contributors compute any field address from the base address of a table record.

### 4. String library

The files in `src/strlib/` implement a subset of `string.h` in MIPS:

- `strcpy`
- `memcpy`
- `strcmp`
- `strncmp`
- `strcat`

These routines are essential for the shell because command interpretation depends on comparing and manipulating strings.

### 5. Command dispatch

`src/commands_table.asm` is the bridge between typed input and executable code.

Each command entry has three parts:

```asm
.word pt_test_func, test_func, 9
```

Meaning:

- `pt_test_func`: address of the string that stores the command name
- `test_func`: address of the routine that should run
- `9`: number of characters used in the initial comparison

Current dispatch flow:

1. load one table entry
2. compare `buffer_space` against the command string using `strncmp`
3. verify that the next byte actually ends the command name
4. if valid, jump to the routine with `jalr`
5. otherwise continue searching the next entry

This is a solid starting point because command discovery is isolated from command implementation.

### 6. Command implementation

`src/commands.asm` holds the routines called by the dispatch table. Right now it only contains test commands, but the intended architecture is:

- `commands_table.asm` decides which command to call
- `commands.asm` implements that command
- `data.asm` provides the memory layout
- `mmio_config.asm` provides I/O
- `strlib/` provides string support

## How to run

1. Open `Mars4_5.jar`.
2. Open `src/main.asm`.
3. Assemble the program.
4. Open `Tools -> Keyboard and Display MMIO Simulator`.
5. Click `Connect to MIPS`.
6. Run the program.
7. Type commands in the MMIO keyboard input area.

The currently available test commands are:

- `test_func`
- `test_func2`

They exist to validate the shell infrastructure before the real restaurant commands are implemented.

## How to contribute

This is the most important part of the README. The project will scale much better if new contributions follow a consistent structure.

### General rule

Before adding a new command, think in three layers:

1. how the command will be recognized
2. which routine will be called
3. which data that routine will read or modify

In practice:

- command recognition belongs in `commands_table.asm`
- command implementation belongs in `commands.asm` or a future service module
- data definitions belong in `data.asm`

### How to add a new command

Suppose you want to add `cardapio_list`.

Step 1. Create the command name string in `src/commands_table.asm`

```asm
pt_cardapio_list: .asciiz "cardapio_list"
```

Step 2. Add a new table entry

```asm
.word pt_cardapio_list, cardapio_list, 13
```

Step 3. Implement the routine in `src/commands.asm`

```asm
cardapio_list:
        addi $sp, $sp, -4
        sw   $ra, 0($sp)

        # implement listing logic here

        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
```

Step 4. If the routine needs menu access, use the offsets and sizes defined in `src/data.asm`.

Step 5. If the routine needs output, use `print_str_mmio` and `print_char_mmio` instead of duplicating I/O logic.

### How to add a new utility function

If the function is generic string or memory support, place it under `src/strlib/`.

Good future candidates:

- decimal string to integer conversion
- a routine to locate the `-` separator
- a routine to iterate through command options
- formatting for money in cents

If the function is not generic, consider placing it in a future domain module such as:

- `menu_service.asm`
- `table_service.asm`
- `order_service.asm`
- `parser.asm`
- `storage.asm`

### How to think about future modules

`commands.asm` is still small today, but it will grow quickly once the assignment commands are implemented. The natural evolution is to split responsibilities:

- `commands.asm`: command entry routines only
- `parser.asm`: option parsing and format validation
- `menu_service.asm`: menu operations
- `table_service.asm`: table operations
- `order_service.asm`: order operations
- `storage.asm`: save and reload logic through file syscalls

That would let a command such as `mesa_ad_item-09-10` follow a clean flow:

1. `commands_table` recognizes the command
2. `commands.asm` enters `mesa_ad_item`
3. `mesa_ad_item` uses the parser to extract options
4. `order_service` validates table and menu item
5. `order_service` updates memory
6. `mmio_config` prints the result

### Recommended register convention

To contribute safely without introducing hard-to-debug side effects, follow this register discipline:

- use `$t0-$t9` only for temporary values
- never assume `$t*` survives a `jal`
- use `$a0-$a3` only for function arguments
- use `$v0-$v1` only for return values
- if a routine performs `jal`, preserve `$ra`
- if a routine uses `$s0-$s7`, preserve them on the stack

Practical rule:

- if a value must survive a function call, store it on the stack or in `$s*`
- if a value is disposable, use `$t*`

### Minimum standard for new routines

Every new routine should clearly answer:

- what arguments it receives
- which registers hold those arguments
- what it returns
- which registers it preserves
- which `data.asm` structures it accesses

A short header comment helps a lot:

```asm
# Adds one menu item to a table order
# $a0 = table code
# $a1 = item code
# $v0 = 0 on success, negative on error
```

### Things to watch when editing `commands_table.asm`

This file is sensitive because it mixes:

- string addresses
- code addresses
- command lengths
- search control flow

Whenever you edit it, review:

- whether the command length is correct
- whether the command name matches the routine
- whether the routine actually exists
- whether the command creates a prefix conflict with another one
- whether any value needed after `jal` is still stored in `$t*`

### Things to watch when editing `data.asm`

This file defines the memory layout. A change here affects the whole project.

Whenever you change offsets or sizes:

- recalculate the total structure size
- update the comments
- review related `.space` allocations
- confirm that loops still use the correct stride

## Example of a safe contribution

Example: adding the `mesa_format` command.

1. Create the string `pt_mesa_format` in the command table data area.
2. Add the entry `.word pt_mesa_format, mesa_format, 11`.
3. Implement the `mesa_format` routine in `commands.asm`.
4. Create or reuse a routine that iterates through all 15 tables.
5. Clear status, responsible name, phone, paid values, and order records.
6. Print the success message using MMIO.

The key idea is to avoid stuffing all logic directly into the shell loop. The shell should remain small; business behavior should live in command routines and future service modules.

## Suggested next steps

A good implementation order from here is:

1. stabilize the register convention
2. build a simple parser for commands that use `-`
3. implement basic menu commands
4. implement table initialization and table reset
5. implement order management and partial reports
6. implement file persistence

## Final notes

This project already has a good base for growth because:

- the main shell is isolated
- MMIO is separated from business logic
- the string library already exists
- the memory layout is offset-based
- the command table supports incremental expansion

The main architectural priority going forward is to keep responsibilities separated, instead of mixing parsing, business logic, and I/O inside the same routine.
