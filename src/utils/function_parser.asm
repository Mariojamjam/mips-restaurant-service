#This function aims to parse the arguments of a command string.
#The parser receives a full command buffer, the length of the command name,
#and the number of expected arguments.
#
#The command format expected by this parser is:
#command-arg1-arg2-arg3
#
#The parser starts reading the buffer after the command name.
#Each argument must be preceded by the '-' character.
#When an argument separator is found, it is replaced by '\0',
#splitting the original string into independent argument strings.
#
#The initial addresses of the parsed arguments are stored in:
#       parsed_arg1
#       parsed_arg2
#       parsed_arg3
#
#Input:
#       $a0: command string buffer address
#       $a1: command name length
#       $a2: number of expected arguments
#
#Output:
#       $v0:  0 if the command arguments were parsed successfully
#       $v0: -1 if the command format is invalid
function_parser:
        #Moving the command string buffer address to a temporary register
        move $t0, $a0
        #Moving the command name length to a temporary register
        move $t1, $a1
        #Moving the number of expected arguments to a temporary register
        move $t2, $a2

        #Loading the ASCII value of '-' to identify argument separators
        li $t7, 45

        #Adding the command name length to the buffer address
        #This moves the pointer to the position right after the command name
        add $t0, $t0, $t1

        #Initializing the parsed arguments counter
        li $t3, 0

        #If the command expects arguments, start parsing the argument section
        bne $t2, $0, function_parser_loop_start

        #If no arguments are expected, the string must end right after the command name
        lb $t4, 0($t0)
        beq $t4, $0, sucess

        #If there is any extra content after the command name, the command is invalid
        j error


function_parser_loop_start:
        #Loading the current byte after the command name
        lb $t4, 0($t0)
        #The first argument must start after a '-' separator
        #If the current byte is not '-', the command format is invalid
        bne $t4, $t7, error


function_parser_loop:
        #Moving the pointer to the first character of the current argument
        addi $t0, $t0, 1
        #Loading the first byte of the current argument
        lb $t4, 0($t0)
        #If the string ends right after '-', the argument is empty and invalid
        beq $t4, $0, error
        
        #If another '-' appears immediately, the argument is empty and invalid
        beq $t4, $t7, error


store_parsed_arg:
        #If this is the first parsed argument, store its address in parsed_arg1
        beq $t3, $0, save_arg1

        #Checking if this is the second parsed argument
        li $t6, 1
        beq $t3, $t6, save_arg2

        #Checking if this is the third parsed argument
        li  $t6, 2
        beq $t3, $t6, save_arg3

        #If more than three arguments are found, the command format is invalid
        j error


continue_parse:
        #Moving the pointer to the next byte of the current argument
        addi $t0, $t0, 1
        #Loading the current byte from the command buffer
        lb $t4, 0($t0)
        #If the string ended, check whether the expected number of arguments was found
        beq $t4, $0, end_of_string_check
        #If a '-' separator was found, move to the next argument
        beq $t4, $t7, next_argument

        #If the current byte is part of the current argument, keep scanning
        j continue_parse


next_argument:
        #Replacing the '-' separator with '\0'
        #This ends the current argument string inside the original buffer
        sb $0, 0($t0)
        #Incrementing the parsed arguments counter
        addi $t3, $t3, 1
        #Starting the parsing process for the next argument
        j function_parser_loop


end_of_string_check:
        #Incrementing the parsed arguments counter for the last argument found
        addi $t3, $t3, 1
        #Moving the pointer past the string terminator
        addi $t0, $t0, 1

        #If the number of parsed arguments matches the expected number, parsing succeeded
        beq $t3, $t2, sucess
        #If the number of parsed arguments is different from the expected number, parsing failed
        j error

#Returning to the caller
sucess:
        #Returning 0 to indicate that the parsing was successful
        li $v0, 0
        jr $ra


#Returning to the caller
error:
        #Returning -1 to indicate that the command format is invalid
        li $v0, -1
        jr $ra


save_arg1:
        #Loading the address where the first parsed argument pointer will be stored
        la $t5, parsed_arg1
        #Storing the current argument address in parsed_arg1
        sw $t0, 0($t5)

        #Continuing the parsing of the current argument
        j continue_parse


save_arg2:
        #Loading the address where the second parsed argument pointer will be stored
        la $t5, parsed_arg2
        #Storing the current argument address in parsed_arg2
        sw $t0, 0($t5)

        #Continuing the parsing of the current argument
        j continue_parse


save_arg3:
        #Loading the address where the third parsed argument pointer will be stored
        la $t5, parsed_arg3
        #Storing the current argument address in parsed_arg3
        sw $t0, 0($t5)

        #Continuing the parsing of the current argument
        j continue_parse