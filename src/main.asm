# Registers summary and their contents
# s0 = "+"
# s1 = "-"
# s2 = "*"
# s3 = "/"
# s4 = "u"
# s5 = "f"
# s6 = first byte of list address in heap
# s7 = operation selected
# s8 = number inputted

	.data # stores data in RAM
	.align 0 # aligns data by byte
	# Error messages
msg_null_list:
	.asciz "Error: null list"
	
	# strings to format output
space:
	.asciz " "

	.text # code
	.align 2 # instructions aligned by word
	.globl main # sets main as program start
main:
	# defines registers to store operations (s0 - s5)
	li s0, '+'    # s0 = ASCII of '+'
    	li s1, '-'    # s1 = ASCII of '-'
    	li s2, '*'    # s2 = ASCII of '*'
    	li s3, '/'    # s3 = ASCII of '/'
    	li s4, 'u'    # s4 = ASCII of 'u'
    	li s5, 'f'    # s5 = ASCII of 'f'
	
	# create list 
	jal list # returns the address of the list in a0
	mv s6, a0 # s6 = pointer to list
		 	 	 	 
	# read 1st input
	li a7, 5 # syscall code 5: read int
	ecall # syscall to read int (store in a0)
	
	# insert first number into list 
	# to avoid repeated code
	mv a1, a0 # move input to a1
	mv a0, s6 # move list adress a0
	jal list_push # add number (int) to the list
	
calculator_on:
	# read code operation
	li a7, 12 # syscall code 12: read char
	ecall # syscall to read  (stored in a0)
	mv s7, a0 # s7 = a0 (operation)
	
	# clean buffer
	# input: char\n, obs: \n comes after the enter
	# so it is necessary to do 2 reads:
	# one to store char
	# and another to remove \n from buffer
	ecall

	mv a0, s6 # a0 = list address

	# switch case for undo or finish operations
	beq s7, s4, case_undo # s7 = 'u'
	beq s7, s5, case_finish # s7 = 'f'
	
	# read number to be operated
	li a7, 5 # syscall code 5: read int
	ecall # syscall to read(store in a0)
	mv s8, a0 # s8 = a0(save data input)

	mv a0, s6 # a0 = list address
	mv a1, s8 # a1 = inputted number
	
	# switch case for operations with number inputted
	beq s7, s0, case_sum # s7 = '+'
	beq s7, s1, case_sub  # s7 = '-'
	beq s7, s2, case_mul  # s7 = '*'
	beq s7, s3, case_div  # s7 = '/'

	# default case
	j invalid_input

# Function that sums the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
# a0: list address
# a1: inputted number
case_sum:
	lw t0, 0(a0) # t0 = address to top node
	lw t0, 4(t0) # t0 = top node number
	add a1, a1, t0 # a1 = top node number + inputted number
	
	# TODO: jal overflow

	jal list_push # creates new node with current list address
				  # and the result of the sum
	
	j calculator_on

# Function that subtracts the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
# a0: list address
# a1: inputted number
case_sub:
	lw t0, 0(a0) # t0 = address to top node
	lw t0, 4(t0) # t0 = top node number
	sub a1, t0, a1 # a1 = top node number + inputted number
	
	# TODO: jal overflow

	jal list_push # creates new node with current list address
				  # and the result of the sum

	j calculator_on

# Function that multiplies the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
# a0: list address
# a1: inputted number
case_mul:
	lw t0, 0(a0) # t0 = address to top node
	lw t0, 4(t0) # t0 = top node number
	mul a1, a1, t0 # a1 = top node number + inputted number
	
	# TODO: jal overflow

	jal list_push # creates new node with current list address
				  # and the result of the sum

	j calculator_on

# Function that divides the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
# a0: list address
# a1: inputted number
case_div:
	lw t0, 0(a0) # t0 = address to top node
	lw t0, 4(t0) # t0 = top node number
	div a1, t0, a1 # a1 = top node number + inputted number
	
	# TODO: jal overflow

	jal list_push # creates new node with current list address
				  # and the result of the sum

	j calculator_on
case_undo:
	# TODO
	# check if list is empty, if necessary
	# throw error, "There is no last operation"
	# and continue loop
	# otherwise, remove top of the list

	j calculator_on
case_finish:	
	# ends calculator run
	j calculator_off
invalid_input:
	# TODO
	# print "Invalid input" and continue loop
	j calculator_on

calculator_off:
	# TODO
	# maybe free memory
	# OBS: i dont know if it is necessary

	# end programn
	li a7, 10 # syscall code 10: end programn
	ecall # syscall to end programn

# Function that creates a list
# a0: returns address of list
list:
	# control structure consists of
	# a pointer to the first node
	li a7, 9 # syscall code 9: allocate memory on heap
	li a0, 4 # size to be allocated = 4 bytes
	ecall # syscall to allocate memory on the heap

	sw zero, 0(a0) # set pointer to NULL(0)
	jr ra # jump to return address

# Function that inserts an element into the list
# a0: list address
# a1: value to be saved in node (int)
list_push:
	# copying the list address to t0 
	mv t0, a0 # t0 now holds the first byte of the list address
	
	# catch possible error(dont try to acess null pointer)
	beqz t0, error_null_list # t0 = 0, list dont exist(null pointer)

	# allocates memory in heap 
	# (8 bytes = 4 bytes for next node address + 4 bytes for result of operation (int))
	li a7, 9 # syscall code 9: allocate memory on heap
	li a0, 8 # size to be allocated: 8 bytes
	ecall # syscall to allocate memory on the heap
	# OBS: a0 now holds the address to the new allocated space in the heap

	lw t1, 0(t0) # loading to t1 the address of the first/top node on the list
	sw t1, 0(a0) # storing the address of the first/top node on the list into the new node
	sw a1, 4(a0) # storing the value into the new node
	sw a0, 0(t0) # making the new node the first/top node of the list

	jr ra # jump to return address

# Function to print list
# print -1 if list dont exist
# print elements in the list
# a0: list adress
list_print:
	# copying the list address to t0 
	mv t0, a0 # t0 now holds the first byte of the list address

	# catch possible error(dont try to acess null pointer)
	beqz t0, error_null_list # t0 = 0, list dont exist(null pointer)
	
	# get top to iterate through the list
	lw t1, 0(t0) # loading to t1 the address of the first/top node on the list

loop_list_print:
	# if current node dont exist(t1 == 0), break
	beqz t1, loop_list_print_exit 

	# read data of the current node
	lw a0, 4(t1) # load value
	lw t1, 0(t1) # load adress to next node
	# OBS: t1 is saving the adress of the nodes
	
	# print current value
	li a7, 1 # syscall code 1: print int
	ecall # syscall to print value in a0
	
	# separate numbers by space
	li a7, 4 # syscall code 4: print a string
	la a0, space # load 1st byte adress
	ecall # syscall to print string
	
	# continue to print values
	j loop_list_print
	
loop_list_print_exit:
	# end function
	jr ra # jump to return address

# Function to print error message
# in case of a list_null
error_null_list:
	# print error message
	li a7, 4 # syscall code 4: print a string
	la a0, msg_null_list # load 1st byte of msg in a0
	ecall # syscall to print message
	
	# end programn
	li a7, 10 # syscall code 10: end programn
	ecall # syscall to end programn
