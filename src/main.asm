# Registers summary and their contents
# s0 = "+"
# s1 = "-"
# s2 = "*"
# s3 = "/"
# s4 = "u"
# s5 = "f"
# s6 = first byte of list address in heap

	.data # stores data in RAM
	.align 0 # aligns data by byte
	# defines character of each functionality
functionalities:
	# sum, sub, mul, div, undo, finish 
	.ascii "+", "-", "*", "/", "u", "f"
	
	# Error messages
msg_null_list:
	.asciz "Error: null list"

	.text # code
	.align 2 # instructions aligned by word
	.globl main # sets main as program start
main:
	# defines registers to store functionalities (s0 - s5)
	la t0, functionalities # loads 1st byte address 
	lb s0, 0(t0) # s0 = '+'
	lb s1, 1(t0) # s1 = '-'
	lb s2, 2(t0) # s2 = '*'
	lb s3, 3(t0) # s3 = '/'
	lb s4, 4(t0) # s4 = 'u'
	lb s5, 4(t0) # s5 = 'f'
	
	# create list 
	jal list # returns the address of the list in a0
	mv s6, a0 # s6 = pointer to list
	 
	# TODO: read 1st input

# Function that creates a list
# a0: returns address from list
list:
	# control structure consists of
	# a pointer to the first node
	li a7, 9 # instruction 9: allocate memory on heap
	li a0, 4 # size to be allocated - 1 pointer = 4 bytes
	ecall # syscall to allocate memory on the heap

	sw zero, 0(a0) # set pointer to NULL(0)
	jr ra # jump to return address

# Function that inserts an element into the list
# a0: list address
# a1: value to be saved in node (int)
list_push:
	# copying the list address to t0 
	mv t0, a0 # t0 now holds the first byte of the list address

	# allocates memory in heap 
	# (8 bytes = 4 bytes for next node address + 4 bytes for result of operation (int))
	li a7, 9 # instruction 9: allocate memory on heap
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
	beqz t0, error_null_list
	
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
	li a7, 1 # instruction 1: print int
	ecall # syscall to print value in a0
	
	# continue to print values
	j loop_list_print
	
loop_list_print_exit:
	# end function
	jr ra # jump to return address
	

# Function to print error message
# in case of a list_null
error_null_list:
	# print error message
	li a7, 4 # instruction 4: print a string
	la a0, msg_null_list # load 1º byte of msg in a0
	ecall # syscall to print message
	
	# end programn
	li a7, 10 # instruction 10: end programn
	ecall # syscall to end programn