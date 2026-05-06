#Data definition file
#This is a offset based approach aiming to mimetize the concept of "object".

#Item from menu definiton
.eqv MENU_ITEM_ID 0 #4 bytes for the id
.eqv MENU_ITEM_PRICE 4 #4 bytes for the price
.eqv MENU_ITEM_DESCRIPTION 8 # 32 Bytes for the description
.eqv MENU_ITEM_SIZE 40 # 40 Bytes for the whole object

#Number of words for menu
.eqv MENU_TOTAL_WORDS 200

#Order definiton
.eqv ORDER_ITEM_ID 0 #4 Bytes for the id
.eqv ORDER_ITEM_QUANTITY 4 #4 Bytes for the quantity
.eqv ORDER_ITEM_SIZE 8 # 8 Bytes for the whole object

#Table definition 
.eqv TABLE_ID 0 #4 Bytes for the id
.eqv TABLE_STATUS 4 #4 Bytes for the status
.eqv TABLE_RESP 8 #32 Bytes for the resp
.eqv TABLE_PHONE 40 #16 Bytes for the phone
.eqv TABLE_TOTAL 56 #4 Bytes for the total
.eqv TABLE_PAID 60 #4 Bytes for the paid
.eqv TABLE_PEDIDO 64 #160 Bytes for the pedido
.eqv TABLE_SIZE 224 # 224 Bytes for the whole object

# MMIO Addresses
.eqv KEYBOARD_CONTROL 0xffff0000  # Status: bit 0 is "1" when a new key is available
.eqv KEYBOARD_DATA    0xffff0004  # Data: contains the ASCII code of the pressed key
.eqv DISPLAY_CONTROL  0xffff0008  # Status: bit 0 is "1" when ready to display
.eqv DISPLAY_DATA     0xffff000c  # Data: where you write the character to be displayed

#define buffers size
.eqv BUFFER_SIZE 256


.data
   	menus: .space 800      # 20 items * 40 bytes
    	tables:    .space 3360     # 15 tables * 224 bytes

    	buffer_space: .space BUFFER_SIZE
    	banner:   .asciiz "restaurant-shell>> "
    
    	parsed_arg1: .word 0
	parsed_arg2: .word 0
	parsed_arg3: .word 0
    	
    	enter_menu_add_msg: .asciiz "entered menu_add"
   	parser_ok_msg: .asciiz "parser ok"
        parser_error_msg: .asciiz "parser error"

    
