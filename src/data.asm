#Data definition file
#This is a offset based approach aiming to mimetize the concept of "object".

#Item from menu definiton
.eqv MENU_ITEM_ID 0 #4 bytes for the id
.eqv MENU_ITEM_PRICE 4 #4 bytes for the price
.eqv MENU_ITEM_DESCRIPTION 8 # 32 Bytes for the description
.eqv MENU_ITEM_SIZE 40 # 40 Bytes for the whole object

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

