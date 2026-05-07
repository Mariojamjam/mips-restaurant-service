# MIPS Restaurant Service

Assembly MIPS project for the MARS simulator. The system implements a restaurant shell capable of managing menu items, tables, orders, partial payments, table reports, table closing, and binary persistence.

This README explains:
- how to run the project
- how the codebase is organized
- how the modular architecture is structured

## Overview

The program is built as a single MIPS application, but its logic is split across multiple specialized `.asm` files.

The shell:
- prints a banner
- reads one full input line
- identifies the typed command
- jumps to the corresponding routine
- returns to the prompt

The project uses:
- MMIO for shell input and output
- offset-based in-memory structures for menu items, tables, and orders
- utility routines for parsing, string handling, and numeric conversion
- binary file persistence for save and reload operations

## How to run

Assemble and run only [src/main.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/main.asm).

### MARS setup

1. Open `Mars4_5.jar`.
2. Open [src/main.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/main.asm).
3. Assemble the program.
4. Open `Tools -> Keyboard and Display MMIO Simulator`.
5. Click `Connect to MIPS`.
6. Run the program.
7. Type commands through the MMIO keyboard input.

### Automatic reload

During startup, `main.asm` attempts to restore previously saved data before entering the shell loop.

This means:
- if a valid save file exists, the previous restaurant state is restored
- if no save file exists, the shell starts with empty runtime data

## Project structure

```text
src/
  entry.asm
  main.asm
  data.asm
  mmio_config.asm
  commands.asm
  commands_table.asm
  strlib/
    strcpy.asm
    memcpy.asm
    strcmp.asm
    strncmp.asm
    strcat.asm
  utils/
    ascii_to_int.asm
    int_to_string.asm
    function_parser.asm
    get_menu_item_addr.asm
    get_table_addr.asm
    get_table_item_addr.asm
    check_table_status.asm
    check_order_rep.asm
    search_order.asm
  menu/
    menu_add.asm
    menu_rm.asm
    menu_list.asm
    menu_format.asm
  table/
    table_start.asm
    order_add.asm
    table_rm_item.asm
    partial_table.asm
    table_pay.asm
    table_close.asm
    table_format.asm
  data_management/
    save_all_data.asm
    load_all_data.asm
    format_all_data.asm
Mars4_5.jar
README.md
restaurant.bin
```

## Modular architecture

### 1. Root program file

[src/main.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/main.asm) is the central file of the project.

It is responsible for:
- including the required modules
- performing startup initialization
- attempting automatic save restoration
- running the main shell loop

In practice, `main.asm` is the file that ties the whole system together.

### 2. Entry point

[src/entry.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/entry.asm) exists only to organize load order and forward execution to `main`.

It should not contain business logic. Real startup behavior belongs in `main.asm`.

### 3. Data layer

[src/data.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/data.asm) defines:
- structure offsets
- record sizes
- global buffers
- reserved memory areas for `menus` and `tables`
- persistence constants
- MMIO addresses

The project models records as offset-based objects.

Examples:
- `MENU_ITEM_ID`
- `MENU_ITEM_PRICE`
- `TABLE_STATUS`
- `TABLE_TOTAL`
- `TABLE_PAID`
- `TABLE_PEDIDO`

This makes memory navigation predictable and consistent across the codebase.

### 4. MMIO layer

[src/mmio_config.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/mmio_config.asm) centralizes all communication with the keyboard and display MMIO devices.

This keeps polling and raw device access away from business routines. The rest of the system can use higher-level helpers for reading strings and printing output.

### 5. String library

The folder [src/strlib](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/strlib) contains MIPS implementations inspired by `string.h`:
- `strcpy`
- `memcpy`
- `strcmp`
- `strncmp`
- `strcat`

These functions support shell parsing and general string manipulation across the project.

### 6. Utility layer

The folder [src/utils](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/utils) contains reusable support functions.

The most important ones are:
- `ascii_to_int.asm`: converts numeric strings to integers
- `int_to_string.asm`: converts integers to strings
- `function_parser.asm`: splits command arguments
- `get_menu_item_addr.asm`: locates menu items by code
- `get_table_addr.asm`: locates tables by code
- `get_table_item_addr.asm`: computes a table order slot address
- `check_table_status.asm`: checks whether service is active on a table
- `check_order_rep.asm`: handles repeated order detection
- `search_order.asm`: finds a free order slot inside `TABLE_PEDIDO`

This layer exists to prevent business logic from duplicating low-level operations.

### 7. Domain modules

The project separates business routines by area.

#### Menu

The folder [src/menu](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/menu) contains menu-related commands:
- add item
- remove item
- list items
- clear the menu

#### Tables and orders

The folder [src/table](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/table) contains:
- start table service
- add item to a table
- remove item from a table
- print a partial table report
- register partial payment
- close a table
- clear all tables

#### Persistence

The folder [src/data_management](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/data_management) contains:
- save current data
- reload persisted data
- clear current in-memory runtime data

### 8. Command dispatch

[src/commands_table.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/commands_table.asm) is the bridge between typed text and executable routines.

Each table entry contains:
- a pointer to the command string
- the label of the target routine
- the command name length

Simplified flow:
1. the shell reads a line into `buffer_space`
2. `commands_table` scans the command entries
3. it compares the input using `strncmp`
4. it validates the real end of the command name
5. it jumps to the correct routine with `jalr`

This design allows new commands to be added without modifying the shell loop itself.

## Execution flow

The program can be summarized as:

```text
main.asm
  -> startup initialization
  -> load_all_data (silent during boot)
  -> main_loop
       -> print banner
       -> read input through MMIO
       -> dispatch command through commands_table
       -> execute business routine
       -> return to prompt
```

## Architectural layers

A good way to reason about the system is to split it into four layers.

### Shell
- `main.asm`
- `commands_table.asm`

Responsibility:
- receive user input
- determine which routine should run

### Utilities
- `strlib/`
- `utils/`

Responsibility:
- provide reusable low-level helpers

### Business logic
- `menu/`
- `table/`
- `data_management/`

Responsibility:
- implement restaurant rules and command behavior

### Data
- `data.asm`

Responsibility:
- define the memory layout and shared state

## Working with commands

To add or modify a command, the usual flow is:

1. create or update the routine in the appropriate module
2. include the file in [src/main.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/main.asm), if it is not already included
3. register the command string and dispatch entry in [src/commands_table.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/commands_table.asm)
4. reuse existing offsets and utility routines instead of recalculating everything manually

## Important conventions

### 1. Compile only `main.asm`

This is the most important rule for anyone continuing the project.

Individual modules depend on shared includes, constants, and labels that are only guaranteed when assembled through `main.asm`.

### 2. Do not assume `$t0-$t9` survive `jal`

The project relies heavily on helper functions. Therefore:
- if a value must survive a function call, save it on the stack
- or move it into a properly preserved `$s*` register

### 3. Prefer existing utilities

Before computing a table or menu address manually, check whether a utility already exists in `utils/`.

This keeps the codebase more consistent.

### 4. Use command-specific labels

Because many files are included into the same final program, generic labels such as:
- `invalid_command`
- `table_not_found`

can easily collide.

Prefer more specific labels such as:
- `table_start_not_found`
- `table_close_invalid_format`

## About `restaurant.bin`

`restaurant.bin` is the persistence file used by the system.

It:
- can be recreated by the program
- stores the saved state of menus and tables
- is not a source file

In practice:
- it is useful for testing save and load behavior
- it should not be treated as part of the codebase architecture

## Quick summary

If you are working on this project, keep these points in mind:

1. open and assemble only [src/main.asm](C:/Users/Pichau/Documents/PastaJam/Codigo/mips-restaurant-service/src/main.asm)
2. connect the MMIO simulator before running
3. understand modules by responsibility, not as isolated files
4. reuse existing helper functions whenever possible
5. preserve the separation between shell, utilities, business logic, and data

This structure was designed to let the project grow without turning into one large monolithic assembly file.
