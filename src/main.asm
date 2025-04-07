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
	mv s6, a0 		# s6 = pointer to list
		 	 	 	  	 	 	  	 	 	 
	# Asks for the 1st input
	li a7, 4 		# Syscall code 4: print a string
	la a0, read_int_msg 	# Load 1st byte adress
	ecall 			# Syscall to print string
	
	# Read 1st input
	li a7, 5 		# Syscall code 5: read int
	ecall 			# Syscall to read int (store in a0)
	
	# Insert first number into list to avoid repeated code
	mv a1, a0 		# Move input to a1
	mv a0, s6 		# Move list adress a0
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
	mv a0, s6		# a0 = list address
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
	mv a0, s6		# a0 = s6(list address)
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
	mv a0, s6		# a0 = list address
	jal list_top		# a0 = top node number
	# Do the current operation
	sub s9, a0, s8 		# s9 = top node number(a0) - inputted number(s8)
	
	# Overflow occurs when:
	# 1. Subtracting a negative from a positivea and result is negative
	# 2. Subtracting a positive from a negative and result is positive
	# Check overflow
	slti t0, a0, 0		# t0 = (a0 < 0) - is a0 neg? 1:0
	slt t1, s8, s9        	# t1 = (s8 < a0 - s8) - number lower than subtraciton result? 1:0
	
	bne t0, t1, error_overflow # overflow if (a0 < 0) && (s8 + a0 < s8)
				#		|| (a0 >= 0) && (s8 + a0 >= s8)
	
	# Creates new node with current list address and the result of the sum
	mv a0, s6		# a0 = s6(list address)
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
	mv a0, s6		# a0 = list address
	jal list_top		# a0 = top node number
	# Do the current operation
	mul s9, s8, a0 		# s9 = top node number(s8) * inputted number(a0)
	
	# TODO: check overflow
	
	# Creates new node with current list address and the result of the sum
	mv a0, s6		# a0 = s6(list address)
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
	mv a0, s6		# a0 = list address
	jal list_top		# a0 = top node number
	# Do the current operation
	div s9, a0, s8 		# s9 = top node number(a0) / inputted number(s8)
	
	# TODO: jal overflow
	
	# Creates new node with current list address and the result of the sum
	mv a0, s6		# a0 = s6(list address)
	mv a1, s9		# a1 = s9(result of current operation)
	jal list_push		# Insert s9 on the top of the list
	
	# Print result of current operation
	mv a0, s9		# a0 = s9(result of current operation)
	jal print_result	# Call function format output result
	
	j calculator_on		# Continue for more operations



# Case that goes back to the last result
# poping the current top node
case_undo:
	mv a0, s6      		# a0 = s6(list address)
	jal list_pop     	# Call the function to remove the last element
    
    	# Check if pop succeeded
   	beqz a0, undo_failed	# If a0 == 0, pop failed
    
    	# Check if list is empty
    	mv a0, s6		# a0 = s6(list address)
    	jal list_empty		# Check if list is empty (returns 1 in a0 if empty)
    	bnez a0, undo_empty_list
    
   	# List not empty, print new top
    	mv a0, s6		# a0 = s6(list address)
    	jal list_top		# a0 = top node value
    
   	jal print_result	# Call the function format output result
    	j calculator_on		# Continue for more operations

undo_failed:
	# Case pop was failed 
    	li a7, 4		# Syscall code 4: print a string		
    	la a0, msg_no_previous_op # Load 1st byte of msg in a0
    	ecall			# Call the system
    	j calculator_on		# Continue for more operations

undo_empty_list:
    	# All operations undid (the last operation was undid)
    	li a7, 4		# Syscall code 4: print a string		
    	la a0, msg_no_previous_op # Load 1st byte of msg in a0
    	ecall			# Call the system
    	j calculator_on		# Continue for more operations
	
	
	
# Print history of results 
# and ends calculator run
case_finish:
	# Prepare output to print history of results
	li a7, 4		# Syscall 4: print string
	la a0, history_of_res	# Output message
	ecall			# Syscall
	
	# Print results
	mv a0, s6		# a0 = address of list
	jal list_print		# Print list elements (numbers)
	
	# Finish loop
	j calculator_off	# Jump to calculator_off

invalid_input:
	# TODO
	# print "Invalid input" and continue loop
	j calculator_on

calculator_off:
	# TODO
	# maybe free memory
	# OBS: i dont know if it is necessary

	# End programn
	li a7, 10 		# Syscall code 10: end programn
	ecall 			# Syscall to end programn

# Function that creates a list
# a0: returns address of list
list:
	# Control structure consists of a pointer to the first node
	li a7, 9 		# Syscall code 9: allocate memory on heap
	li a0, 4 		# Size to be allocated = 4 bytes
	ecall 			# Syscall to allocate memory on the heap

	# Ends function
	sw zero, 0(a0) 		# Set pointer to NULL(0)
	jr ra 			# Jump to return address

# Function that inserts an element into the list
# argument
# a0: list address
# a1: value to be saved in node (int)
list_push:
	# Copying the list address to t0 
	mv t0, a0 		# t0 now holds the first byte of the list address
	
	# Catch possible error(dont try to acess null pointer)
	beqz t0, error_null_list# t0 = 0, list dont exist(null pointer)

	# Allocates memory in heap 
	# (8 bytes = 4 bytes for next node address + 4 bytes for result of operation (int))
	li a7, 9 		# Syscall code 9: allocate memory on heap
	li a0, 8 		# Size to be allocated: 8 bytes
	ecall 			# Syscall to allocate memory on the heap
				# OBS: a0 now holds the address to the new allocated space in the heap

	# Create new node, and save data(adress of next node and number)
	lw t1, 0(t0) 		# Loading to t1 the address of the first/top node on the list
	sw t1, 0(a0) 		# Storing the address of the first/top node on the list into the new node
	sw a1, 4(a0) 		# Storing the value into the new node
	sw a0, 0(t0) 		# Making the new node the first/top node of the list

	jr ra # jump to return address
	
	
#Function that removes an element out the list
# arguments
# a0: list address
# return 
# a0: status (1 = success, 0 = failure)
# a1: value of the element removed  
list_pop:
   	# Catch possible error(dont try to acess null pointer)
	beqz a0, error_null_list# a0 = 0, list dont exist(null pointer)
    
    	# Get list address
    	lw t0, 0(a0)        	# t0 = address of top node
	beqz t0, pop_empty  	# if null, list is empty
    
    	# Successful pop
    	# Get the value (store in a1 for return)
    	lw a1, 4(t0)        	# a1 = value from node
    	
    	# Update list head next node
    	lw t1, 0(t0)        	# t1 = next node address
	sw t1, 0(a0)        	# update list head
    
	# Return success    
    	li a0, 1      		# a0 = 1      
    	jr ra			# jump to return address

pop_empty:
	# Return failure and value 0
	li a0, 0		# a0 = 0
    	li a1, 0		# a1 = 0
    	jr ra			# jump to return address	
	
	
# Function to get number on top
# of the list
# argument: 
# a0 ,address of list
# return: 
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
# argument
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
# argument: 
# a0 ,address of list
# return: 
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
	

# Function to print results
# after an operation
# argument
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
