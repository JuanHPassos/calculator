	.data # stores data in RAM
	.align 0 # aligns data by byte
	# defines character of each feature
features:
	# sum, sub, mul, div, undo, finish 
	.ascii "+", "-", "*", "/", "u", "f"

	.text # code
	.align 2 # instructions aligned by word
	.globl main # sets main as program start
main:
	# defines registers to store functionality
	la t0, features # loads 1st byte address 
	lb s0, 0(t0) # s0 = '+'
	lb s1, 1(t0) # s1 = '-'
	lb s2, 2(t0) # s2 = '*'
	lb s3, 3(t0) # s3 = '/'
	lb s4, 4(t0) # s4 = 'u'
	lb s5, 4(t0) # s5 = 'f'
	
	# create list(returns the address of the list in a0)
	jal list
	add s6, zero, a0 # s6 = list pointer
	
	# read 1st input - number
	li a7, 5 # command 5: read integer
	ecall # syscall to read (a0 = input)
	add t0, zero, a0 # save input 
	
	# push first element to the list
	add a0, zero, s6 # set list as argument
	add a1, zero, t0 # set value to be enter
	jal list_push # function call
	
loop:
	# read char and integer


# Function that creates a list
# a0: returns address from list
list:
	# control structure consists of
	# on a pointer to the first node
	li a7, 9 # command 9: allocate memory on heap
	li a0, 4 # size to be allocated - 1 pointer = 4 bytes
	ecall # syscall to allocate memory on the heap
	sw zero, 0(a0) # set pointer to NULL(= 0)
	jr ra # returns to the calling address
	
# Function that inserts an element into the list
# a0: list address
# a1: value to be entered
list_push:

# Function to test list
# print -1 if list dont exist
# print elements in the list
# a0: list adress
test: