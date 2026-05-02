#THS FILE WILL BE USED TO IMPLEMENT THE MAIN FUNCTIONS
#to be able to implement functions that do not break the entire architecture, use the the stack correctly
#Store the $ra in the stack, being careful to not break the functions calling.
#Always save the $ra in the stack. Not doing this may cause the crash of core functions.

.data
        test_1: .asciiz "Teste 1"
        test_2: .asciiz "Teste 2"

.text
test_func:
        #Open stack
        addi $sp, $sp, -4
        sw   $ra, 0($sp)
        #Print test string
        la   $a0, test_1
        jal  print_str_mmio
        #Restore and return
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra

test_func2:
        #Open stack
        addi $sp, $sp, -4
        sw   $ra, 0($sp)
        #Print test string
        la   $a0, test_2
        jal  print_str_mmio
        #Restore and return
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra