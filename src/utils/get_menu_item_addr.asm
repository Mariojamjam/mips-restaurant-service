#This function aims to find the address of a menu item based on its id.
#Since the menu items are stored sequentially in memory, the address can be found
#by calculating the offset of the desired item inside the menu array.

#Input:
#       $a0: menu item id

#Output:
#       $v0: address of the desired menu item
get_menu_item_addr:
        #Moving the current menu id to a temporary register
        move $t0, $a0

        #Loading the size of a single menu item object
        li $t1, MENU_ITEM_SIZE

        #Subtracting 1 from the id to convert it into a zero-based array index
        addi $t0, $t0, -1

        #Multiplying the zero-based index by the size of a single menu item
        #This gives the byte offset of the desired item inside the menu array
        mul $t2, $t1, $t0

        #Loading the base address of the menu items array
        la $t3, menus

        #Adding the calculated offset to the base address
        #This gives the final address of the desired menu item
        add $v0, $t3, $t2

        #Returning to the caller with the item address stored in $v0
        jr $ra