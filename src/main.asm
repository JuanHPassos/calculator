# Registers summary and their contents
# s0 = "+"
# s1 = "-"
# s2 = "*"
# s3 = "/"
# s4 = "u"
# s5 = "f"
# s6 = first byte list address in heap

	.data # stores data in RAM
	.align 0 # aligns data by byte
	# defines character of each functionality
functionalities:
	# sum, sub, mul, div, undo, finish 
	.ascii "+", "-", "*", "/", "u", "f"

	.text # code
	.align 2 # instructions aligned by word
	.globl main # sets main as program start
main:
	# defines registers to store functionalities (s0 - s5)
	la t0, features # loads 1st byte address 
	lb s0, 0(t0) # s0 = '+'
	lb s1, 1(t0) # s1 = '-'
	lb s2, 2(t0) # s2 = '*'
	lb s3, 3(t0) # s3 = '/'
	lb s4, 4(t0) # s4 = 'u'
	lb s5, 4(t0) # s5 = 'f'
	
	# create list (returns the address of the list in a0)
	jal list
	add s6, zero, a0 # s6 = pointer to list
	
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
	# allocates memory in heap (8 bytes = 4 bytes for next node address + 4 bytes for result of operation (int))
	li a7, 9 # instruction 9: allocate memory on heap
	li a0, 8 # size to be allocated: 8 bytes
	ecall # syscall to allocate memory on the heap

	lw t2, 0(s6) # loading to t2 the address of the first/top node on the list
	sw t2, 0(a0) # storing the address of the first/top node on the list into the new node
	sw a1, 4(a0) # storing the value into the new node
	sw a0, 0(s6) # making the new node the first/top node of the list

	jr ra # jump to return address

# TODO
# Function to test list
# print -1 if list dont exist
# print elements in the list
# a0: list adress
test: