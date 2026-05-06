#This function aims to clear all items from the menu array.
#It iterates over every word used by the menu array and stores 0 in each position.
#
#Since the menu array is composed of multiple menu item objects,
#clearing all words from the array also clears every item id, price, and description field.
#
#Input:
#       menus: menu items array stored in memory
#
#Output:
#       All menu items are cleared from memory
#       A success message is printed through MMIO
.data
        menu_clear_message: .asciiz "All items from menu were sucessfuly cleared!"

.text
menu_format:
        #Opening stack space to preserve the return address
        addi $sp, $sp, -4

        #Saving the return address because this function calls another function
        sw $ra, 0($sp)

        #Loading the base address of the menu array
        la $t0, menus

        #Initializing the loop counter
        li $t1, 0

        #Loading the total number of words that compose the menu array
        li $t7, MENU_TOTAL_WORDS


menu_format_loop:
        #Clearing the current word of the menu array
        sw $0, 0($t0)

        #Moving the pointer to the next word in the menu array
        addi $t0, $t0, 4

        #Incrementing the number of cleared words
        addi $t1, $t1, 1

        #If all menu words were cleared, finish the formatting process
        beq $t1, $t7, menu_format_end

        #Continuing the loop until the whole menu array is cleared
        j menu_format_loop


menu_format_end:
        #Printing the success message after clearing all menu items
        la $a0, menu_clear_message
        jal print_str_mmio

        #Restoring the return address from the stack
        lw   $ra, 0($sp)

        #Closing the stack space used by this function
        addi $sp, $sp, 4

        #Returning to the caller
        jr   $ra