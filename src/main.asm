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
# s9 = result of current operation

	.data 			# Stores data in RAM
	.align 2		# Aligns data by word
list_pointer:
	.word 0			# Create space(4 bytes) in RAM with NULL(0) value
	
	.align 0 		# Aligns data by byte		
# Error messages
msg_null_list:			
	.asciz "Error: null list.\n"
msg_div_by_zero:
	.asciz "Error: division by zero is not allowed.\n"
msg_overflow:
	.asciz "Error: overflow has occurred.\n"
msg_no_previous_op:
	.asciz "No previous operation.\n"
msg_invalid_op:
	.asciz "Invalid operation, try again.\n"
	
# Strings to format output
space:				
	.asciz " "
	
breakline:
	.asciz "\n"
	
result:
	.asciz "Result = "
	
history_of_res:
	.asciz "History of results = "
	
operation_msg:
	.asciz "Type the operation: '+' for sum, '-' for sub, '*' for mul, '/' for div, 'u' for undo, 'f' to finish: "

read_int_msg:
	.asciz "Type the number: "
	
	.text 			# Code
	.align 2 		# Instructions aligned by word (32 bits)
	.globl main 		# Sets main as program start
main:
	# Defines registers to store operations (s0 - s5)
	li s0, '+'    		# s0 = ASCII of '+'
    	li s1, '-'    		# s1 = ASCII of '-'
    	li s2, '*'    		# s2 = ASCII of '*'
    	li s3, '/'    		# s3 = ASCII of '/'
    	li s4, 'u'    		# s4 = ASCII of 'u'
    	li s5, 'f'    		# s5 = ASCII of 'f'
	
	# Create list 
	jal list 		# Returns the address of the list in a0
	la s6, list_pointer	# s6 = adress that have the adress of the list
	sw a0, 0(s6)		# save the list adress in RAM
		 	 	 	  	 	 	  	 	 	 
	# Asks for the 1st input
	li a7, 4 		# Syscall code 4: print a string
	la a0, read_int_msg 	# Load 1st byte adress
	ecall 			# Syscall to print string
	
	# Read 1st input
	li a7, 5 		# Syscall code 5: read int
	ecall 			# Syscall to read int (store in a0)
	
	# Insert first number into list to avoid repeated code
	mv a1, a0 		# Move input to a1
	lw a0, 0(s6) 		# Move list adress a0
	jal list_push 		# Add number (int) to the list
	
calculator_on:
	# Asks for the code operation
	li a7, 4 		# Syscall code 4: print a string
	la a0, operation_msg 	# Load 1st byte adress
	ecall 			# Syscall to print string

	# Read code operation
	li a7, 12 		# Syscall code 12: read char
	ecall 			# Syscall to read  (stored in a0)
	mv s7, a0 		# s7 = a0 (operation)
	
	# Clean buffer
	# Input: char\n, obs: \n comes after the enter
	# So it is necessary to do 2 reads:
	# One to store char
	# And another to remove \n from buffer
	ecall

	# Switch case for undo or finish operations
	beq s7, s4, case_undo 	# s7 = 'u'
	beq s7, s5, case_finish # s7 = 'f'
	
	# Asks for the number to be operated
	li a7, 4 		# Syscall code 4: print a string
	la a0, read_int_msg 	# Load 1st byte adress
	ecall 			# Syscall to print string
	
	# Read number to be operated
	li a7, 5 		# Syscall code 5: read int
	ecall 			# Syscall to read(store in a0)
	mv s8, a0 		# s8 = a0(save data input)
	
	# Switch case for operations with number inputted
	beq s7, s0, case_sum 	# s7 = '+'
	beq s7, s1, case_sub  	# s7 = '-'
	beq s7, s2, case_mul  	# s7 = '*'
	beq s7, s3, case_div  	# s7 = '/'
				
	j invalid_input		# Default case

# Sums the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
case_sum:
	# Get number of the last operation
	lw a0, 0(s6)		# a0 = list address
	jal list_top		# a0 = top node number
	# Do the current operation
	add s9, s8, a0 		# s9 = top node number(a0) + inputted number(s8)
	
	# Overflow occurs when:
	# 1. Two positive numbers are added together and the result is negative
	# 2. Two negative numbers are added together and the result is positive
	# Check overflow
	slti t0, a0, 0		# t0 = (a0 < 0) - is a0 neg? 1:0
	slt t1, s9, s8		# t1 = (s8 + a0 < s8) - sum result lower number? 1:0
	bne t0, t1, error_overflow # overflow if (a0 < 0) && (s8 + a0 >= s8)
				#		|| (a0 >= 0) && (s8 + a0 < s8)
	
			
	# Creates new node with current list address and the result of the sum
	lw a0, 0(s6)		# a0 = s6(list address)
	mv a1, s9		# a1 = s9(result of current operation)
	jal list_push		# Insert s9 on the top of the list
	
	# Print result of current operation
	mv a0, s9		# a0 = s9(result of current operation)
	jal print_result	# Call function format output result
	
	j calculator_on		# Continue for more operations

# Case that subtracts the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
case_sub:
	# Get number of the last operation
	lw a0, 0(s6)		# a0 = list address
	jal list_top		# a0 = top node number
	# Do the current operation
	sub s9, a0, s8 		# s9 = top node number(a0) - inputted number(s8)
	
	# Overflow occurs when:
	# 1. Subtracting a negative from a positivea and result is negative
	# 2. Subtracting a positive from a negative and result is positive
	# Check overflow
	slti t0, a0, 0		# t0 = (a0 < 0) - is a0 neg? 1:0
	slti t1, s8, 0        	# t1 = (s8 < 0) - is s8 neg? 1:0
	# t1 = number have opposite signs
	xor t0, t1, t0		# if the numbers have opposite signs, possible overflow
	# t2 = result(s9) has the same sign s8
	slti t2, s9, 0		# s9 = (s9 < 0) - is s9 neg? 1:0
	# xnor t2, t2, t1
	xor t2, t2, t1
	xori t2, t2, 1
	# overflow if t1 = 1 and t2 = 1
	and t0, t0, t2
	li t2, 1
	beq t0, t2, error_overflow 
	
	# Creates new node with current list address and the result of the sum
	lw a0, 0(s6)		# a0 = s6(list address)
	mv a1, s9		# a1 = s9(result of current operation)
	jal list_push		# Insert s9 on the top of the list
	
	# Print result of current operation
	mv a0, s9		# a0 = s9(result of current operation)
	jal print_result	# Call function format output result

	j calculator_on		# Continue for more operations

# Case that multiplies the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
case_mul:
	# Get number of the last operation
	lw a0, 0(s6)		# a0 = list address
	jal list_top		# a0 = top node number
	# Do the current operation
	mul s9, s8, a0 		# s9 = top node number(s8) * inputted number(a0)
	
	# TODO: check overflow
	
	# Creates new node with current list address and the result of the sum
	lw a0, 0(s6)		# a0 = s6(list address)
	mv a1, s9		# a1 = s9(result of current operation)
	jal list_push		# Insert s9 on the top of the list
	
	# Print result of current operation
	mv a0, s9		# a0 = s9(result of current operation)
	jal print_result	# Call function format output result
	
	j calculator_on		# Continue for more operations

# Case that divides the inputted number 
# and the number stored on top of the list,
# and stores the result as the new top
case_div:
	# Check if the divider is zero
	beqz s8, error_div_by_zero # Cant div by zero
	
	# Get number of the last operation
	lw a0, 0(s6)		# a0 = list address
	jal list_top		# a0 = top node number
	# Do the current operation
	div s9, a0, s8 		# s9 = top node number(a0) / inputted number(s8)
	
	# TODO: jal overflow
	
	# Creates new node with current list address and the result of the sum
	lw a0, 0(s6)		# a0 = s6(list address)
	mv a1, s9		# a1 = s9(result of current operation)
	jal list_push		# Insert s9 on the top of the list
	
	# Print result of current operation
	mv a0, s9		# a0 = s9(result of current operation)
	jal print_result	# Call function format output result
	
	j calculator_on		# Continue for more operations



# Case that goes back to the last result
# poping the current top node
case_undo:
	# Check if have last operations
	lw a0, 0(s6) 		# Load adress of the list
	jal list_size		# Return size of the list in a0
	# Because the logic of implementation if a0(size) = 1,
	# there is no last operation, 
	# because this one element is the 1st input.
	li t0, 1		# Case occurs when 'u' is the first operation
	beq t0, a0, error_no_previous_op 
	
	# Remove last operation
	lw a0, 0(s6) 		# Load adress of the list
	jal list_pop		
	
	# Check if have last operations
	lw a0, 0(s6) 		# Load adress of the list
	jal list_size		# Return size of the list in a0
	# Because the logic of implementation if a0(size) = 1,
	# there is no last operation, 
	# because this one element is the 1st input.
	li t0, 1		# Case occurs when all the operations is removed
	beq t0, a0, error_no_previous_op # and only remains the 1st input
	# TODO: this error is not fatal, so do a jump to case finish to print history of results
	
	# Print the prev last result
	lw a0, 0(s6) 		# Load adress of the list
	jal list_top		# Get the value of the top of the list
	jal print_result	# Function to format output of result
	
	j calculator_on		# Return to calculator_on loop
	
# Print history of results 
# and ends calculator run
case_finish:
	# Prepare output to print history of results
	li a7, 4		# Syscall 4: print string
	la a0, history_of_res	# Output message
	ecall			# Syscall
	
	# Print results
	lw a0, 0(s6)		# a0 = address of list
	jal list_print		# Print list elements (numbers)
	
	# Finish loop
	j calculator_off	# Jump to calculator_off

invalid_input:
	# Prints error message and goes back to calculator_on
	li a7, 4		# Syscall 4: print string
	la a0, msg_invalid_op	# Output message
	ecall			# Syscall
	
	j calculator_on		# Return to calculator_on loop

calculator_off:
	# End programn
	li a7, 10 		# Syscall code 10: end programn
	ecall 			# Syscall to end programn

# Function that creates a list
# Argument:
# a0: returns address of list
list:
	# Control structure consists of a pointer to the first node
	li a7, 9 		# Syscall code 9: allocate memory on heap
	li a0, 8		# Size to be allocated = 4 bytes(adress) + 4 bytes(list size)
	ecall 			# Syscall to allocate memory on the heap

	# Ends function
	sw zero, 0(a0) 		# Set pointer to NULL(0)
	sw zero, 4(a0)		# Size of a empty list is zero
	jr ra 			# Jump to return address

# Function that inserts an element into the list
# Argument:
# a0: list address
# a1: value to be saved in node (int)
list_push:
	# Copying the list address to t0 
	mv t0, a0 		# t0 now holds the first byte of the list address
	
	# Catch possible error(dont try to acess null pointer)
	beqz t0, error_null_list# t0 = 0, list dont exist(null pointer)

	# Allocates memory in heap 
	# struct node { int adressNextNode; int value; } -> 8 bytes
	li a7, 9 		# Syscall code 9: allocate memory on heap
	li a0, 12 		# Size to be allocated: 8 bytes
	ecall 			# Syscall to allocate memory on the heap
				# OBS: a0 now holds the address to the new allocated space in the heap

	# Create new node, and save data(adress of next node and number)
	lw t1, 0(t0) 		# Loading to t1 the address of the first/top node on the list
	sw t1, 0(a0) 		# Storing the address of the first/top node on the list into the new node
	sw a1, 4(a0) 		# Storing the value into the new node
	sw a0, 0(t0) 		# Making the new node the first/top node of the list
	
	# Update size of list
	lw t1, 4(t0)		# Read the current size of list
	addi t1, t1, 1		# Increment one to size of list
	sw t1, 4(t0)		# Save new size

	jr ra # Jump to return address
	
	
#Function that removes an element out the list
# Argument:
# a0: list address
list_pop:
   	# Catch possible error(dont try to acess null pointer)
	beqz a0, error_null_list# a0 = 0, list dont exist(null pointer)
    
    	# Get list address
    	lw t0, 0(a0)        	# t0 = address of top node
    	beqz t0, end_list_pop
    	
    	# Update list head next node
    	lw t1, 0(t0)        	# t1 = next node address
	sw t1, 0(a0)        	# update list head
	
	# Update size of list
	lw t1, 4(a0)		# Read the current size of list
	addi t1, t1, -1		# Decrement one to size of list
	sw t1, 4(a0)		# Save new size
	
end_list_pop: 
    	jr ra			# Jump to return address	
	
# Function to get number on top of the list
# Argument: 
# a0 ,address of list
# Return: 
# a0, number on top node of the list
list_top:
	# Catch possible error(dont try to acess null pointer)
	beqz a0, error_null_list# a0 = 0, list dont exist(null pointer)

	# Get the first element(number) in the list
	lw t0, 0(a0) 		# t0 = address to top node
	lw t1, 4(t0) 		# t1 = top node number
	mv a0, t1		# a0 = top node number
	
	jr ra			# Jump to return address
	
# Function to print list (-1 if list dont exist)
# Argument:
# a0: list adress
list_print:
	# Copying the list address to t0 
	mv t0, a0 		# t0 now holds the first byte of the list address

	# Catch possible error(dont try to acess null pointer)
	beqz t0, error_null_list# t0 = 0, list dont exist(null pointer)
	
	# Get top to iterate through the list
	lw t1, 0(t0) 		# Loading to t1 the address of the first/top node on the list

loop_list_print:
	# If current node dont exist(t1 == 0), break
	beqz t1, loop_list_print_exit 

	# Read data of the current node
	lw a0, 4(t1) 		# Load value
	lw t1, 0(t1)		# Load adress to next node
				# OBS: t1 is saving the adress of the nodes
	
	# Print current value
	li a7, 1		# Syscall code 1: print int
	ecall 			# Syscall to print value in a0
	
	# Separate numbers by space
	li a7, 4 		# Syscall code 4: print a string
	la a0, space 		# Load 1st byte adress
	ecall 			# Syscall to print string
	
	j loop_list_print	# Continue to print values
	
loop_list_print_exit:		
	# End function
	jr ra 			# Jump to return address
	
# Function to verify if the list is empty
# Argument: 
# a0 ,address of list
# Return: 
# a0, 1 if list if empty, otherwise 0
list_empty:
	# Copying the list address to t0 
	mv t0, a0 		# t0 now holds the first byte of the list address
	
	# Catch possible error(dont try to acess null pointer)
	beqz t0, error_null_list# t0 = 0, list dont exist(null pointer)
	
	# Get the first byte from the address of the first node
	lw t0, 0(a0)        	# t0 = address of top node
	
	# if t0(adress of 1st node) = 0, list is empty
	seqz a0, t0		# t0 == 0 ? 1:0
	
	jr ra               	# Return with value in a1
	
# Function to return the size of list
# Argument: 
# a0: adress of list
# Return:
# a0: size of list
list_size:
	# Catch possible error(dont try to acess null pointer)
	beqz a0, error_null_list	# a0 = 0, list dont exist(null pointer)
	# Return size of list
	lw a0, 4(a0)			# a0 [adress of first node, size of list]
	jr ra				# Return size in a0				
	
	

# Function to print error message
# in case of overflow
error_overflow:
	# Print error message
	li a7, 4 		# Syscall code 4: print a string
	la a0, msg_overflow	# Load 1st byte of msg in a0
	ecall 			# Syscall to print message
	
	# End programn
	li a7, 10 		# Syscall code 10: end programn
	ecall 			# Syscall to end program

# Function to print error message
# in case of divide by zero
error_div_by_zero:
	# Print error message
	li a7, 4 		# Syscall code 4: print a string
	la a0, msg_div_by_zero # Load 1st byte of msg in a0
	ecall 			# Syscall to print message
	
	# End programn
	li a7, 10 		# Syscall code 10: end programn
	ecall 			# Syscall to end program

# Function to print error message
# in case of a list_null
error_null_list:
	# Print error message
	li a7, 4 		# Syscall code 4: print a string
	la a0, msg_null_list 	# Load 1st byte of msg in a0
	ecall 			# Syscall to print message
	
	# End programn
	li a7, 10 		# Syscall code 10: end programn
	ecall 			# Syscall to end program

# Function to print error message
# in case of no previous operation
error_no_previous_op:
	# Print error message
	li a7, 4 		# Syscall code 4: print a string
	la a0, msg_no_previous_op# Load 1st byte of msg in a0
	ecall 			# Syscall to print message
	
	# End programn
	li a7, 10 		# Syscall code 10: end programn
	ecall 			# Syscall to end program	

# Function to print results
# after an operation
# Argument
# a0: result of operation
print_result:
	mv t0, a0		# t0 = result of operation
	
	# Output message
	li a7, 4 		# Syscall code 4: print a string
	la a0, result		# Load 1st byte adress
	ecall 			# Syscall to print string
	
	# Print result( int )
	li a7, 1		# Syscall 10: print int
	mv a0, t0		# Parameter: t0 (result of operation)
	ecall			# Syscall
	
	# Separate numbers by \n
	li a7, 4 		# Syscall code 4: print a string
	la a0, breakline	# Load 1st byte adress
	ecall 			# Syscall to print string
	# End function
	jr ra
