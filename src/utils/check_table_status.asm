#verify if table is available or not
#$a0 = address of the table that we want to check
#$v0 returns 1 if the table has started service and 0 otherwise
check_table_status:
	lw   $t0, TABLE_STATUS($a0)
	beq  $t0, $zero, table_unavailable
	li   $v0, 1
	jr   $ra

table_unavailable:
	move $v0, $zero
	jr   $ra
