# === A Bad Box Pushing Game by Serif W. ===
#
# (a) The enhancements implemented in this game are:
#		(1) Increased difficulty by increasing the number of boxes and targets.
#		(2) Provided a multi-player (competitive) mode.
#
# (b) The implementation of enhancement (1) can be found at:
#		- label target_generator, where an array of targets is generated.
#		- label boxes_generator, where an array of boxes is generated.
# 	  The implementation of enhancement (2) can be found at:
#		- line 165, where the game prompts the user for number of players.
#		- label _sort_leaderboard, where scores are sorted.
#		- label report_final, where final scores are printed.
# 
# (c) Enhancement (1) is implemented via:
#		- storing boxes and targets to different locations in the heap as arrays.
#		- the number of boxes and targets are bounded by 
#         floor(gridsize_x * gridsize_y * 0.0625).
#	  Enhancement (2) is implemented via:
#		- prompt user for num_player at the beginning of the game (at least 1 player).
#		- using the value of num_player as the stopping index of a for loop over
#		  the main game loop.
#		- write the number of moves the player has into moves array 
#		- reset the game after every end of the main game loop.
#		- sort the moves array along with player # number array in parallel
#		- print the result onto the terminal as a leaderboard at the end of the for 
#		  loop execution.
#
# In addition, a pull toggle is implemented at label pull_box, allowing the player to
# pull boxes if they wish to. It is implemented by 
#		- checking if the character has made a successful move
#		- if a successful move has been made, check if character is on top of a box
#		  (illegal move), reset the character's location if illegal move is detected.
# 		- check how many boxes surrounds character's last move
#		- if only one box surrounds character's last move, get the box by calling 
#         get function.
#		- move the box to where the character's last move is
#		- check for postcondition: box cannot be on top of the character
#		- if post condition fails, reset the box's location.
.data
.align 4
solved:		.byte 0,0
gridsize:   .byte 0,0
character:  .byte 0,0
box:        .byte 0,0
target:     .byte 0,0
last_move:	.byte 0,0
buffer:		.byte 0
pull_toggle:.byte 0		# pull toggle, set to 0 (false) by default

.align 4
seed:       	.word 0  	# seed for the pseudorandom number generator
num_player:		.word 0		# number of players playing the game
num_objects: 	.word 0		# number of objects allowed to be generated
solved_counter:	.word 0		# number of boxes on targets
player_moves:	.word 0		# number of moves the player took to solve the puzzle

toggle_on:			.string "(pull toggle on.): "
toggle_off:			.string "(pull toggle off.): "
wall_str:			.string "# "
character_str:		.string "o "
solved_str:			.string "! "
target_str:			.string "4 "
box_str:			.string "= "
move_str:			.string "moves: "
dot:				.string ". "
comma:				.string ", "
colon:				.string ": "
player:				.string "Player "
invalid_input_msg:	.string "\nInvalid input.\n\n"
invalid_move_msg:	.string "\nInvalid move, no change was made.\n"
complete_msg:		.string " completed the puzzle in "
move_msg:			.string " moves.\n\n"
leaderboard_msg:	.string	"===================================\n           LEADERBOARD\n===================================\n"
prompt1: 			.string "Enter dimension 3 <= x: "
prompt2:			.string "Enter dimension 3 <= y: "
prompt3:			.string "How many players (1 <= n) is playing this game: "
newline: 			.string "\n"
tab:				.string "\t"
line1:				.string "Character is @ \nBox is o \nTarget is 4 \nWall is # \n"
line2:				.string "Push the boxes onto the targets. \nThe player with least moves win.\n"
move_prompt:		.string "Type 1 to move left \nType 2 to move down \nType 3 to move right \nType 5 to move up\nType 6 to reset the game \nType 4 to toggle pull "

.align 4
_heap_start:

.text
.global _start
_start:
	
	li sp, 0x80000000
	
	# make s11 point at heaps
	# starting from the bottom of the heap:
	# boxes: s11
	# targets: s11 + num_objects * 2
	# a copy of initial boxes's states: s11 + num_objects * 4
	# players: s11 + num_objects * 8 + 2
	# moves: s11 + num_objects * 8 + num_player * 4 + 2
	la s11, _heap_start
	
	j WHILE1
	WHILE_1_INVALID_MSG:
	# print invalid input msg
	li a7, 4
	la a0, invalid_input_msg
	ecall
	
    # print propmpts for dimension and make sure x, y >= 3 and <= 255
	WHILE1:
		li a7, 4
		la a0, prompt1
		ecall

		li a7, 5
		ecall

		mv t0, a0	# x: t0

		li a7, 4
		la a0, prompt2
		ecall

		li a7, 5
		ecall

		mv t1, a0	# y: t1

		li t2, 3
		li t3, 255
		blt t0, t2, WHILE_1_INVALID_MSG
		blt t1, t2, WHILE_1_INVALID_MSG
		bgt t0, t3, WHILE_1_INVALID_MSG
		bgt t1, t3, WHILE_1_INVALID_MSG
	
	ENDWHILE1:
	
	# write to gridsize
	la s0, gridsize
	sb t0, 0(s0)
	sb t1, 1(s0)
	
	# calculate the number of objects allowed to be generated
	mul t2, t0, t1
	srli t2, t2, 4
	
	# find max(t2, 1) and write to num_objects
	IF1:
		li t3, 1
		bge t2, t3, ENDIF1
		li t2, 1
		
	ENDIF1:
	
	la s0, num_objects
	sw t2, 0(s0)

	j WHILE2
	WHILE2_INVALID_MSG:
	# print invalid input msg
	li a7, 4
	la a0, invalid_input_msg
	ecall
	
	WHILE2:
		# n = num of player
		li a7, 4
		la a0, prompt3
		ecall

		li a7, 5
		ecall

		mv t2, a0	# n: t2

		li t0, 1

		blt t2, t0, WHILE2_INVALID_MSG
	
	ENDWHILE2:
	
	# write to num_player
	la s1, num_player
	sw t2, 0(s1)
	
	# print
	li a7, 4
	la a0, newline
	ecall
	
	li a7, 4
	la a0, line1
	ecall
	
	li a7, 4
	la a0, newline
	ecall
	
	li a7, 4
	la a0, line2
	ecall
	
	# time syscall, get bottom bits, get rid of whatever 
	# leading 1 it has, and write to seed fr
	li a7, 30
	ecall
	
	slli a0, a0, 1
	srli a0, a0, 1
	
	la t0, seed
	sw a0, 0(t0)
	
	# function calls
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	jal init
	jal play
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44

exit:
	li a7, 10
	ecall

init:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	# store ra
	addi sp, sp, -4
	sw ra, 0(sp)
	
	# generate character
	la s1, gridsize
	la s2, character
	
	lb a0, 0(s1)	# x
	jal rand
	addi a0, a0, 1
	sb a0, 0(s2)	# x: character[0] = rand(1, dim[0])
	
	lb a0, 1(s1)	# y
	jal rand
	addi a0, a0, 1
	sb a0, 1(s2)	# 1: character[1] = rand(1, dim[1])
	
	# generate targets
	jal target_generator

	# generate boxes
	jal boxes_generator
	
	# save initial state of the board
	jal save_initial_state
	
	# fill the players array
	FOR_PLAYERS_ARRAY_INIT:
	la t0, num_objects	
	lw t0, 0(t0)
	slli t0, t0, 3
	addi t0, t0, 4
	add t0, s11, t0		# &players
	la t5, num_player
	lw t5, 0(t5)		# stopping index
	li t6, 0			# i
	FOR_PLAYERS_ARRAY:
		bge t6, t5, END_FOR_PLAYERS_ARRAY
		
		mv t1, t6
		slli t1, t1, 2
		add t1, t0, t1	# offset
		addi t2, t6, 1
		sw t2, 0(t1)
		
		addi t6, t6, 1
		j FOR_PLAYERS_ARRAY
	END_FOR_PLAYERS_ARRAY:
	# pop ra
	lw ra, 0(sp)
	addi sp, sp, 4
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret

play:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	addi sp, sp, -4
	sw ra, 0(sp)
	
	FOR_PLAY_INIT:
	la s5, num_player
	lw s5, 0(s5)	# stopping index
	li s6, 0		# i
	
	FOR_PLAY:
		bge s6, s5, END_FOR_PLAY
		WHILE_PLAY:
			
			jal game_over
			bne a0, zero, END_WHILE_PLAY
			
			li a7, 4
			la a0, newline
			ecall
			
			# print Player i
			li a7, 4
			la a0, player
			ecall
			
			mv t0, s6
			addi t0, t0, 1
			li a7, 1
			mv a0, t0
			ecall
			
			li a7, 4
			la a0, newline
			ecall
			
			# print board
			jal print_board
			
			PLAY_INVALID_INPUT:
			# prompt user input
			li a7, 4
			la a0, move_prompt
			ecall
			
			li a7, 4
			la a0, newline
			
			la t0, pull_toggle
			lb t0, 0(t0)
			beq t0, zero, PRINT_TOGGLE_OFF
		
			li a7, 4
			la a0, toggle_on
			ecall
			j END_PRINT_TOGGLE_OFF
			
			PRINT_TOGGLE_OFF:
			li a7, 4
			la a0, toggle_off
			ecall
			
			END_PRINT_TOGGLE_OFF:
			
			# read user prompt
			li a7, 5
			ecall
			
			mv s0, a0
			
			# input is 1235 for move
			li s1, 1
			beq s0, s1, MOVE_KEY
			li s1, 2
			beq s0, s1, MOVE_KEY
			li s1, 3
			beq s0, s1, MOVE_KEY
			li s1, 5
			beq s0, s1, MOVE_KEY
			
			# input is 6 for reset
			li s1, 6
			beq s0, s1, RESET_KEY
			
			# input is 4 for pull toggle
			li s1, 4
			beq s0, s1, PULL_KEY
			
			# print invalid input msg
			li a7, 4
			la a0, invalid_input_msg
			ecall
			j PLAY_INVALID_INPUT
			
			BACK4:
			
			j WHILE_PLAY
			
			MOVE_KEY:
				mv a0, s0
				jal move_character
				mv s0, a0
				# check pull toggle:
				la t0, pull_toggle
				lb t0, 0(t0)
				
				bne t0, zero, TOGGLED
					jal push_box
					j END_TOGGLED
				TOGGLED:
					mv a0, s0
					jal pull_box
				END_TOGGLED:
				
				jal hits_target
				j BACK4
				
			RESET_KEY:
				jal reset_game
				j BACK4
			
			PULL_KEY:
				la t1, pull_toggle
				lb t0, 0(t1)
				xori t0, t0, 1
				sb t0, 0(t1)
				j BACK4
				
		END_WHILE_PLAY:
		
		jal print_board
		
		# print completion message
		li a7, 4
		la a0, player
		ecall
		
		li a7, 1
		mv a0, s6
		addi a0, a0, 1
		ecall
		
		li a7, 4
		la a0, complete_msg
		ecall
		
		li a7, 1
		la a0, player_moves
		lw a0, 0(a0)
		ecall
		
		li a7, 4
		la a0, move_msg
		ecall
		
		la t0, num_objects
		lw t0, 0(t0)
		slli t0, t0, 3
		addi t0, t0, 4
		la s9, num_player
		lw s9, 0(s9)
		slli s9, s9, 2
		add s9, s9, t0		#&moves
		mv t0, s6
		slli t0, t0, 2		# word offset
		add t1, s9, t0		# moves[i]
		la t2, player_moves
		lw t3, 0(t2)		# get player_moves
		sw t3, 0(t1)		# write to array
		la t2, solved_counter
		sw zero, 0(t2)		# reset solved_counter
		
		sw zero, 0(t2)		# reset player_moves
		
		jal reset_game
		
		addi s6, s6, 1
		j FOR_PLAY
	
	END_FOR_PLAY:
	
	jal report_final
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret

# Return: 1 for game over, 0 for not game over
game_over:
	la t0, num_objects
	la t1, solved_counter
	
	lw t0, 0(t0)
	lw t1, 0(t1)
	
	beq t0, t1, GAME_OVER_TRUE
	
	li a0, 0
	ret
	
	GAME_OVER_TRUE:
	li a0, 1
	ret

# writes to last_move
# Returns: 1 for moved successfully
#		   0 for moved unsuccessfully
move_character:
	
	addi sp, sp, -4
	sw s0, 0(sp)
	
	mv t6, a0
	# writes to last_move
	la t0, last_move
	la t3, character
	la t4, gridsize
	lb t1, 0(t3)
	lb t2, 1(t3)
	sb t1, 0(t0)
	sb t2, 1(t0)
	
	li t1, 5
	beq t6, t1, MOVE_W
	li t1, 1
	beq t6, t1, MOVE_A
	li t1, 2
	beq t6, t1, MOVE_S
	li t1, 3
	beq t6, t1, MOVE_D
	
	MOVE_W:
		lb t1, 0(t3)	# character[0]
		li t2, 1
		bgt t1, t2, VALID_W
		# print invalid move message
		li a7, 4
		la a0, invalid_move_msg
		ecall
		j END_MOVE
		
	MOVE_A:
		lb t1, 1(t3)	# character[1]
		li t2, 1
		bgt t1, t2, VALID_A
		# print invalid move message
		li a7, 4
		la a0, invalid_move_msg
		ecall
		j END_MOVE
		
	MOVE_S:
		lb t1, 0(t3)	# character[0]
		lb t2, 0(t4)	# dim[0]
		blt t1, t2, VALID_S
		# print invalid move message
		li a7, 4
		la a0, invalid_move_msg
		ecall
		j END_MOVE
		
	MOVE_D:
		lb t1, 1(t3)	# character[1]
		lb t2, 1(t4)	# dim[1]
		blt t1, t2, VALID_D
		# print invalid move message
		li a7, 4
		la a0, invalid_move_msg
		ecall
		j END_MOVE
	
	
	VALID_W:
		addi t1, t1, -1
		sb t1, 0(t3)
		j END_MOVE
		
	VALID_A:
		addi t1, t1, -1
		sb t1, 1(t3)
		j END_MOVE
		
	VALID_S:
		addi t1, t1, 1
		sb t1, 0(t3)
		j END_MOVE
		
	VALID_D:
		addi t1, t1, 1
		sb t1, 1(t3)
		j END_MOVE
	
	END_MOVE:
	li s0, 1
	la t2, player_moves
	lw t1, 0(t2)
	addi t1, t1, 1
	sw t1, 0(t2)
	
	# sleep for delay
	li a0, 400
	li a7, 32
	ecall
	
	mv a0, s0

	lw s0, 0(sp)
	addi sp, sp, 4
	
	ret

push_box:
	addi sp, sp, -4
	sw ra, 0(sp)
	
	addi sp, sp, -24
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	
	# if character in boxes
	la t1, character
	lb t0, 0(t1)
	lb t1, 1(t1)
	mv a0, t0
	mv a1, t1
	mv a2, s11	# &boxes
	
	jal in
	
	beq a0, zero, MOVE_BOX_RET
	
	# get the box
	mv a0, t0
	mv a1, t1
	mv a2, s11
	
	jal get
	add s0, s11, a0		# s0 = &box
	lb t5, 0(s0)		# t5 = box[0]
	lb t6, 1(s0)		# t6 = box[1]
	
	# copy original state of box
	lb s4, 0(s0)
	lb s5, 1(s0)
	
	# get last move
	la s1, last_move
	lb t1, 0(s1)	# t1 = last_move[0]
	lb t2, 1(s1)	# t2 = last_move[1]
	
	# get gridsize
	la s3, gridsize
	
	beq t2, t6, LAST_MOVE_1_EQ_BOX_1
	beq t1, t5, LAST_MOVE_0_EQ_BOX_0
	
	LAST_MOVE_1_EQ_BOX_1:
		bgt t1, t5, BOX_WAS_ON_TOP
		blt t1, t5, BOX_WAS_AT_BOTTOM
		j INVALID_MOVE_BOX
		
		BOX_WAS_ON_TOP:
			# box[0] += 1
			lb t5, 0(s0)
			addi t5, t5, -1
			beq t5, zero, INVALID_MOVE_BOX
			mv a0, t5
			lb a1, 1(s1)
			mv a2, s11
			jal in
			bne a0, zero, INVALID_MOVE_BOX
			sb t5, 0(s0)
			
			j MOVE_BOX_RET
			
		BOX_WAS_AT_BOTTOM:
		
			# box[0] -= 1
			lb t5, 0(s0)
			addi t5, t5, 1
			lb t0, 0(s3)
			addi t0, t0, 1
			beq t5, t0, INVALID_MOVE_BOX
			mv a0, t5
			lb a1, 1(s1)
			mv a2, s11
			jal in
			bne a0, zero, INVALID_MOVE_BOX
			sb t5, 0(s0)
			
			j MOVE_BOX_RET
		
	LAST_MOVE_0_EQ_BOX_0:
		lb t2, 1(s1)
		lb t6, 1(s0)
		
		bgt t2, t6, BOX_WAS_TO_LEFT
		blt t2, t6, BOX_WAS_TO_RIGHT
		j INVALID_MOVE_BOX
		
		BOX_WAS_TO_LEFT:

			# box[1] -= 1
			lb t5, 1(s0)
			addi t5, t5, -1
			beq t5, zero, INVALID_MOVE_BOX
			lb a0, 0(s1)
			mv a1, t5
			mv a2, s11
			jal in
			bne a0, zero, INVALID_MOVE_BOX
			sb t5, 1(s0)
			
			j MOVE_BOX_RET
			
		BOX_WAS_TO_RIGHT:
			
			# box[1] += 1
			lb t5, 1(s0)
			addi t5, t5, 1
			lb t0, 1(s3)
			addi t0, t0, 1
			beq t5, t0, INVALID_MOVE_BOX
			lb a0, 0(s1)
			mv a1, t5
			mv a2, s11
			jal in
			bne a0, zero, INVALID_MOVE_BOX
			sb t5, 1(s0)
			
			j MOVE_BOX_RET
	
	
	INVALID_MOVE_BOX:
		sb s4, 0(s0)
		sb s5, 1(s0)
		# character = last_move
		la t2, last_move
		lb t1, 0(t2)	# t1 = last_move[0]
		lb t2, 1(t2)	# t1 = last_move[1]
		la t4, character
		sb t1, 0(t4)
		sb t2, 1(t4)
		# print invalid move message
		li a7, 4
		la a0, invalid_move_msg
		ecall
	MOVE_BOX_RET:
	li a0, 0
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	addi sp, sp, 24
	
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

# can only pull one box
# Argument: a0 character moved
pull_box:
	addi sp, sp, -4
	sw ra, 0(sp)
	
	addi sp, sp, -20
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	
	# character did not move
	beq a0, zero, PULL_BOX_RET
	
	# character is on top of a box (character has to have moved away)
	la s0, character
	lb a0, 0(s0)
	lb a1, 1(s0)
	mv a2, s11
	jal in
	
	bne a0, zero, CHARACTER_ON_BOX
	j END_CHARACTER_ON_BOX
	
	CHARACTER_ON_BOX:
	la s1, last_move
	lb t1, 0(s1)
	lb t2, 1(s1)
	sb t1, 0(s0)
	sb t2, 1(s0)
	j PULL_BOX_RET
	
	END_CHARACTER_ON_BOX:
	# if character's last move is beside one and only one box
	la s0, last_move
	lb t0, 0(s0)
	lb t1, 1(s0)
	
	li t3, 0
	li t4, 1
	# up (box is down)
	mv a0, t0
	addi a0, a0, 1
	mv a1, t1
	mv a2, s11	# &boxes
	jal in
	add t3, t3, a0
	mv s1, a0
	
	# down (box is up)
	mv a0, t0
	addi a0, a0, -1
	mv a1, t1
	mv a2, s11	# &boxes
	jal in
	add t3, t3, a0
	mv s2, a0
	
	# right (box is left)
	mv a0, t0
	mv a1, t1
	addi a1, a1, 1
	mv a2, s11	# &boxes
	jal in
	add t3, t3, a0
	mv s3, a0
	
	# left (box is right)
	mv a0, t0
	mv a1, t1
	addi a1, a1, -1
	mv a2, s11	# &boxes
	jal in
	add t3, t3, a0
	mv s4, a0
	
	bne t3, t4, PULL_BOX_RET	# multiple or no boxes around player
	
	# check for which direction the box is at
	bne s1, zero, PULL_UP
	bne s2, zero, PULL_DOWN
	bne s3, zero, PULL_RIGHT
	bne s4, zero, PULL_LEFT
	
	PULL_UP:
		lb a0, 0(s0)
		addi a0, a0, 1
		lb a1, 1(s0)
		mv a2, s11
		jal get
		add s1, s11, a0		# &box[i]
		
		# copy the box
		lb t5, 0(s1)
		lb t6, 1(s1)

		lb s2, 0(s1)
		addi s2, s2, -1
		sb s2, 0(s1)
		j PULL_BOX_RET
		
	PULL_DOWN:
		lb a0, 0(s0)
		addi a0, a0, -1
		lb a1, 1(s0)
		mv a2, s11
		jal get
		add s1, s11, a0		# &box[i]

		# copy the box
		lb t5, 0(s1)
		lb t6, 1(s1)
		
		lb s2, 0(s1)
		addi s2, s2, 1
		sb s2, 0(s1)
		j PULL_BOX_RET
		
	PULL_RIGHT:
		lb a0, 0(s0)
		lb a1, 1(s0)
		addi a1, a1, 1
		mv a2, s11
		jal get
		add s1, s11, a0		# &box[i]

		# copy the box
		lb t5, 0(s1)
		lb t6, 1(s1)

		lb s2, 1(s1)
		addi s2, s2, -1
		sb s2, 1(s1)
		j PULL_BOX_RET
		
	PULL_LEFT:
		lb a0, 0(s0)
		lb a1, 1(s0)
		addi a1, a1, -1
		mv a2, s11
		jal get
		add s1, s11, a0		# &box[i]

		# copy the box
		lb t5, 0(s1)
		lb t6, 1(s1)

		lb s2, 1(s1)
		addi s2, s2, 1
		sb s2, 1(s1)
		j PULL_BOX_RET
	
	RESET_BOX:
	sb t5, 0(s1)
	sb t6, 1(s1)
	# print invalid move message
	li a7, 4
	la a0, invalid_move_msg
	ecall

	PULL_BOX_RET:

	la t0, character
	lb a0, 0(t0)
	lb a1, 1(t0)
	lb a2, 0(s1)
	lb a3, 1(s1)
	jal is

	END_PULL_BOX:
	bne a0, zero, RESET_BOX
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	addi sp, sp, 20
	
	lw ra, 0(sp)
	addi sp, sp, 4
	ret
# Arguments: [a0, a1] is object, a2 is base address of array
# Return: a0 - the index of object (offset), -1 if index not found
get:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	addi sp, sp, -4
	sw ra, 0(sp)
	
	# copy the arguments
	mv s0, a0
	mv s1, a1
	mv s2, a2
	
	FOR_GET_INIT:
	la s5, num_objects		# stopping index
	lw s5, 0(s5)
	slli s5, s5, 1
	li s6, 0
	FOR_GET:
		beq s5, s6, END_FOR_GET
		
		add s7, s2, s6
		
		# check is
		mv a0, s0
		mv a1, s1
		# curr
		lb a2, 0(s7)
		lb a3, 1(s7)
		
		jal is
		bne a0, zero, GET_FOUND
		
		addi s6, s6, 2
		j FOR_GET
		
	END_FOR_GET:
	li a0, -1
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret
	
	GET_FOUND:
	mv a0, s6
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret
	
hits_target:
	addi sp, sp, -4
	sw ra, 0(sp)
	
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 1
	add s0, s11, t0	# &targets
	
	la s9, solved
	
	FOR_BOX_IN_BOXES_HIT_INIT:
	la t0, num_objects
	lw s6, 0(t0)
	slli s6, s6, 1		# stopping index
	li s5, 0			# i
	
	FOR_BOX_IN_BOXES_HIT:
		
		bge s5, s6, END_FOR_BOX_IN_BOXES
		add s1, s11, s5	# box
		
		lb s2, 0(s1)
		lb s3, 1(s1)
		
		# check for box in targets
		mv a0, s2
		mv a1, s3
		mv a2, s0
		
		jal in
		
		bne a0, zero, BOX_IN_TARGET_HIT
		
		BACK5:
		
		addi s5, s5, 2
		j FOR_BOX_IN_BOXES_HIT
		
		BOX_IN_TARGET_HIT:
		# get box and target at boxes.index(box)
		mv a0, s2
		mv a1, s3
		mv a2, s11
		
		jal get
		
		add s4, s11, a0	# the box.
		# write to solved
		lb t1, 0(s4)
		lb t2, 1(s4)
		sb t1, 0(s9)
		sb t2, 1(s9)
		
		# write zeros into the box
		sb zero, 0(s4)
		sb zero, 1(s4)
		
		# find target at boxes.index(box)
		mv a0, s2
		mv a1, s3
		mv a2, s0
		
		jal get
		
		add s7, s0, a0	# the target
		
		# write zeros into the target
		sb zero, 0(s7)
		sb zero, 1(s7)
		
		# increment solved_counter
		la t0, solved_counter
		lw t1, 0(t0)
		addi t1, t1, 1
		sw t1, 0(t0)
		
		j BACK5
		
	END_FOR_BOX_IN_BOXES:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

reset_game:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)

	la s9, num_objects
	lw s9, 0(s9)
	slli s9, s9, 1
	
	add t0, s9, s9
	add s0, s11, t0	# &initial_state
	mv s1, s11		# &boxes
	add s7, s11, s9	# &targets
	
	# first two bytes are character
	lb t1, 0(s0)
	lb t2, 1(s0)
	
	# store character from the first two bytes
	la t0, character
	sb t1, 0(t0)
	sb t2, 1(t0)
	
	addi s0, s0, 2
	add t0, s9, s0
	add s8, s11, t0		#& a copy of targets
	
	FOR_RESET_INIT:
	la t5, num_objects
	lw t5, 0(t5)
	slli t5, t5, 1
	li t6, 0
	
	FOR_RESET_STATE:
		bge t6, t5, END_FOR_RESET_STATE
		
		add s2, s0, t6
		add s3, s1, t6
		add s5, s4, t6
		add s9, s7, t6
		add s10, s8, t6
		
		# copy boxes back
		lb t3, 0(s2)
		lb t4, 1(s2)
		
		sb t3, 0(s3)
		sb t4, 1(s3)
		
		# copy targets back
		lb t3, 0(s10)
		lb t4, 1(s10)
		
		sb t3, 0(s9)
		sb t4, 1(s9)
		
		addi t6, t6, 2
		j FOR_RESET_STATE
		
	END_FOR_RESET_STATE:
	la t0, pull_toggle
	sb zero, 0(t0)
	la t0, player_moves
	sw zero, 0(t0)
	la t0, solved_counter
	sw zero, 0(t0)
	la t0, solved
	sb zero, 0(t0)
	sb zero, 1(t0)
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret

report_final:
	addi sp, sp, -4
	sw ra, 0(sp)

	addi sp, sp, -4
	sw s9, 0(sp)

	# print leaderboard sign
	li a7, 4
	la a0, leaderboard_msg
	ecall
	
	# sort
	jal _sort_leaderboard
	
	# print the rankings
	FOR_REPORT_FINAL_INIT:
	la t5, num_player
	lw t5, 0(t5)		# stopping index
	li t6, 0			# i

	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 3		# num_objects * 8
	addi t0, t0, 4
	la s9, num_player
	lw s9, 0(s9)
	slli s9, s9, 2
	add s9, s9, t0		#&moves

	FOR_REPORT_FINAL:
		bge t6, t5, END_FOR_REPORT_FINAL

		# number
		li a7, 1
		mv a0, t6
		addi a0, a0, 1
		ecall

		li a7, 4
		la a0, dot
		ecall

		li a7, 4
		la a0, tab
		ecall

		# player
		li a7, 4
		la a0, player
		ecall

		la t0, num_objects	
		lw t0, 0(t0)
		slli t0, t0, 3
		addi t0, t0, 4
		add t0, s11, t0		# &players
		mv t1, t6
		slli t1, t1, 2
		add t1, t0, t1		# &players[i]


		li a7, 1
		lw a0, 0(t1)
		ecall

		li a7, 4
		la a0, tab
		ecall

		li a7, 4
		la a0, move_str
		ecall
		
		mv t0, s9
		mv t1, t6
		slli t1, t1, 2
		add t2, t0, t1		#&moves[i]

		li a7, 1
		lw a0, 0(t2)
		ecall

		li a7, 4
		la a0, newline
		ecall

		addi t6, t6, 1
		j FOR_REPORT_FINAL
		
	END_FOR_REPORT_FINAL:
	lw s9, 0(sp)
	addi sp, sp, 4

	lw ra, 0(sp)
	addi sp, sp, 4
	ret

target_generator:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	# store ra
	addi sp, sp, -4
	sw ra, 0(sp)
	
	# load base address of array
	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 1
	add s0, s11, t0	# s0 = &targets
	
	FOR_T_GEN_INIT:
	la s4, gridsize
	la s1, num_objects
	lw s1, 0(s1)
	slli s1, s1, 1		# stopping index
	li s2, 0			# i
	
	FOR_T_GEN:

		bge s2, s1, END_FOR_T_GEN
		
		WHILE_TARGET_CANNOT_GEN:
			# generate two random numbers
			add s3, s0, s2	# target[i]

			lb a0, 0(s4)	# x
			jal rand
			addi a0, a0, 1
			mv s6, a0

			lb a0, 1(s4)	# y
			jal rand
			addi a0, a0, 1
			mv s7, a0

			# check for invalid gens
			mv a0, s6
			mv a1, s7
			mv a2, s0

			jal _targen_can_gen
			
			beq a0, zero, WHILE_TARGET_CANNOT_GEN
		
		sb s6, 0(s3)
		sb s7, 1(s3)
		addi s2, s2, 2
		j FOR_T_GEN
	
	END_FOR_T_GEN:

	# pop ra
	lw ra, 0(sp)
	addi sp, sp, 4
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret

boxes_generator:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	# store ra
	addi sp, sp, -4
	sw ra, 0(sp)
	
	# load base address of array
	mv s0, s11	# s0 = &boxes
	
	FOR_BOX_GEN_INIT:
	la s4, gridsize
	la s1, num_objects
	lw s1, 0(s1)
	slli s1, s1, 1		# stopping index
	li s2, 0			# i
	
	FOR_BOX_GEN:
		
		WHILE_BOX_CANNOT_GEN:
			# generate two random numbers
			bge s2, s1, END_FOR_BOX_GEN
			add s3, s0, s2	# target[i]

			lb a0, 0(s4)	# x
			jal rand
			addi a0, a0, 1
			mv s6, a0

			lb a0, 1(s4)	# y
			jal rand
			addi a0, a0, 1
			mv s7, a0

			# check for invalid gens
			mv a0, s6
			mv a1, s7
			mv a2, s0

			jal _box_can_gen
			
			beq a0, zero, WHILE_BOX_CANNOT_GEN
		
		sb s6, 0(s3)
		sb s7, 1(s3)
		addi s2, s2, 2
		j FOR_BOX_GEN
	
	END_FOR_BOX_GEN:
	
	# pop ra
	lw ra, 0(sp)
	addi sp, sp, 4
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret
	
save_initial_state:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 2	# num_objects * 4
	add s0, s11, t0	# &initial_state
	mv s1, s11		# &boxes
	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 1
	add s5, s11, t0	# &targets
	
	la t2, character
	lb t1, 0(t2)
	lb t2, 1(t2)
	
	# store character into first two bytes
	sb t1, 0(s0)
	sb t2, 1(s0)
	
	addi s0, s0, 2
	
	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 1
	add t0, s0, t0
	add s8, s11, t0		#& a copy of targets
	
	FOR_INIT_STATE_INIT:
	la t5, num_objects
	lw t5, 0(t5)
	slli t5, t5, 1
	li t6, 0
	
	FOR_INIT_STATE:
		bge t6, t5, END_FOR_INIT_STATE
		
		add s2, s0, t6
		add s3, s1, t6
		add s4, s5, t6
		add s6, s8, t6
		
		# copy boxes
		lb t3, 0(s3)
		lb t4, 1(s3)
		
		sb t3, 0(s2)
		sb t4, 1(s2)
		
		# copy targets
		lb t3, 0(s4)
		lb t4, 1(s4)
		
		sb t3, 0(s6)
		sb t4, 1(s6)
		
		addi t6, t6, 2
		j FOR_INIT_STATE
		
	END_FOR_INIT_STATE:
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret

# this is bubble sort on two parallel arrays (players and moves)
# we are sorting moves and shifting the indexes in players
# moves is an array of words, players is an array of bytes
_sort_leaderboard:
	
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 3
	addi t0, t0, 4
	la s9, num_player
	lw s9, 0(s9)
	slli s9, s9, 2
	add s0, s9, t0		#&moves

	la t0, num_objects	
	lw t0, 0(t0)
	slli t0, t0, 3
	addi t0, t0, 4
	add s1, s11, t0		# &players
	
	FOR_SORT_LEADERBOARD_i_INIT:
	la t5, num_player
	lw t5, 0(t5)		# stopping index
	li t6, 0			# i
	FOR_SORT_LEADERBOARD_i:
		bge t6, t5, END_FOR_SORT_LEADERBOARD_i
		
		FOR_SORT_LEADERBOARD_j_INIT:
		mv t3, t5
		sub t3, t3, t6
		addi t3, t3, -1		# stopping index
		li t4, 0			# j
		FOR_SORT_LEADERBOARD_j:
			bge t4, t3, END_FOR_SORT_LEADERBOARD
			
			mv t0, t4
			mv t1, t4
			addi t1, t1, 1
			slli t0, t0, 2		# t0 = j * 4
			slli t1, t1, 2		# t1 = (j + 1) * 4
			
			add s2, s0, t0		# &moves[j]
			add s3, s0, t1		# &moves[j + 1]
			
			add s6, s1, t0		# &player[j]
			add s7, s1, t1		# &player[j + 1]
			
			lw t0, 0(s2)
			lw t1, 0(s3)
			bgt t0, t1, SORT
			
			BACK6:
			
			addi t4, t4, 1
			j FOR_SORT_LEADERBOARD_j
			
			SORT:
			
			# sort moves
			mv s4, s2		# temp = &moves[j]
			lw s4, 0(s4)	# temp = moves[j]
			lw s5, 0(s3)	# moves[j + 1]
			sw s5, 0(s2)	# moves[j] = moves[j + 1]
			sw s4, 0(s3)	# moves[j + 1] = temp
			
			# sort players
			mv s8, s6
			lw s8, 0(s8)
			lw s9, 0(s7)
			sw s9, 0(s6)
			sw s8, 0(s7)
			
			j BACK6
		END_FOR_SORT_LEADERBOARD:
		
		addi t6, t6, 1
		j FOR_SORT_LEADERBOARD_i
	END_FOR_SORT_LEADERBOARD_i:
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44

# Arguments: (a0, a1) are (x, y), a2 is the base address of the array
# Return: 0 for false, 1 for true
_targen_can_gen:
	addi sp, sp, -4
	sw ra, 0(sp)

	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	# copy the arguments
	mv s1, a0
	mv s2, a1
	mv s3, a2
	
	# check if target is on character
	mv a0, s1
	mv a1, s2
	la s0, character
	lb a2, 0(s0)
	lb a3, 1(s0)
	
	jal is
	
	bne a0, zero, RET_FALSE
	
	
	# check if target is in targets
	mv a0, s1
	mv a1, s2
	mv a2, s3
	
	jal in
	
	bne a0, zero, RET_FALSE
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	li a0, 1
	ret
	
	RET_FALSE:		# this is used for everything that returns false fr
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	li a0, 0
	ret

# Arguments: (a0, a1) are (x, y), a2 is the base address of the array
# Return: 0 for false, 1 for true
_box_can_gen:
	addi sp, sp, -4
	sw ra, 0(sp)

	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	mv s7, a0
	mv s8, a1
	mv s9, a2
	
	# check if box is on character
	la s0, character
	lb a2, 0(s0)
	lb a3, 1(s0)
	mv a0, s7
	mv a1, s8
	jal is
	bne a0, zero, RET_F
	
	# check if box is in boxes
	mv a0, s7
	mv a1, s8
	mv a2, s11
	jal in
	bne a0, zero, RET_F
	
	# check if box is in targets
	mv a0, s7
	mv a1, s8
	la t0, num_objects
	lw t0, 0(t0)
	slli t0, t0, 1
	add a2, s11, t0		# &target
	
	jal in
	bne a0, zero, RET_F
	
	RET_T:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	li a0, 1
	ret
	
	RET_F:
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	li a0, 0
	ret

# checking [a0, a1] == [a2, a3]
# Arguments: a0, a1, a2, a3
# Return: a0 - 1 for True, 0 for False
is:
	beq a0, a2, EQUAL_IS
	j END_EQUAL_IS
	
	EQUAL_IS:
		beq a1, a3, is_ret_true
		
	END_EQUAL_IS:
	
	li a0, 0
	ret
	
	is_ret_true:
	li a0, 1
	ret

# Arguments: [a0, a1] is object, a2 is base address of array
# Return: a0 - 1 for True, 0 for False
in:
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	beq a0, zero, END_FOR_IN
	beq a1, zero, END_FOR_IN

	FOR_IN_INIT:
	la s5, num_objects		# stopping index
	lw s5, 0(s5)
	slli s5, s5, 1
	li s6, 0
	FOR_IN:
		beq s5, s6, END_FOR_IN
		
		add s7, a2, s6
		lb s8, 0(s7)
		lb s9, 1(s7)
		
		beq s8, a0, EQUAL1
		j END_EQUAL1
		
		EQUAL1:
			beq s9, a1, EQUAL_IN
			
		END_EQUAL1:
		
		addi s6, s6, 2
		j FOR_IN
		
	EQUAL_IN:
	li a0, 1
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret
		
	END_FOR_IN:
	li a0, 0
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	ret

# Argument: a0 is the base address of the array
print_array:
	mv t4, a0
	
	li a7, 4
	la a0, newline
	ecall
	
	PRINT_ARRAY_INIT:
	la t1, num_objects
	lw t1, 0(t1)
	slli t1, t1, 1
	li t0, 0		# i
	
	FOR_PRINT_ARRAY:
		bge t0, t1, END_PRINT_ARRAY
		
		add t3, t0, t4		# get array[i]
		
		li a7, 1
		lb a0, 0(t3)
		ecall
		
		li a7, 4
		la a0, comma
		ecall
		
		li a7, 1
		lb a0, 1(t3)
		ecall
		
		li a7, 4
		la a0, newline
		ecall
		
		addi t0, t0, 2
		j FOR_PRINT_ARRAY
	END_PRINT_ARRAY:
	ret

print_board:
	addi sp, sp, -4
	sw ra, 0(sp)
	
	addi sp, sp, -44
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw s9, 36(sp)
	sw s10, 40(sp)
	
	li a7, 4
	la a0, newline
	ecall
	
	mv s0, s11		# &boxes
	la s9, num_objects
	lw s9, 0(s9)
	slli s9, s9, 1
	add s1, s11, s9	# &targets
	la s2, solved
	
	la t1, gridsize
	lb t0, 0(t1)
	lb t1, 1(t1)
	addi t0, t0, 2
	addi t1, t1, 2
	li t5, 0	# i
	
	PRINT_FOR1:
		bge t5, t0, END_PRINT_FOR1
		li t6, 0	# j
		PRINT_FOR2:
			bge t6, t1, END_PRINT_FOR2
			
			li a0, 0
			
			# conditionals
			# if [i, j] in walls
			beq t5, zero, PRINT_WALL
			beq t6, zero, PRINT_WALL
			la t4, gridsize
			lb t3, 0(t4)
			lb t4, 1(t4)
			addi t3, t3, 1
			addi t4, t4, 1
			beq t5, t3, PRINT_WALL
			beq t6, t4, PRINT_WALL
			
			# if [i, j] == character
			la t3, character
			mv a0, t5
			mv a1, t6
			lb a2, 0(t3)
			lb a3, 1(t3)
			jal is
			bne a0, zero, PRINT_CHARACTER
			
			# if [i, j] in solved
			mv a0, t5
			mv a1, t6
			lb a2, 0(s2)
			lb a3, 1(s2)
			jal is
			bne a0, zero, PRINT_SOLVED
			
			# if [i, j] in targets
			mv a0, t5
			mv a1, t6
			mv a2, s1
			jal in
			bne a0, zero, PRINT_TARGET
			
			# if [i, j] in boxes
			mv a0, t5
			mv a1, t6
			mv a2, s0
			jal in
			bne a0, zero, PRINT_BOX
			
			li a7, 4
			la a0, dot
			ecall
			
			BACK3:
			
			addi t6, t6, 1
			j PRINT_FOR2
			
		END_PRINT_FOR2:
		addi t5, t5, 1
		
		li a7, 4
		la a0, newline
		ecall
		
		j PRINT_FOR1
		
		PRINT_WALL:
		li a7, 4
		la a0, wall_str
		ecall
		j BACK3
		
		PRINT_CHARACTER:
		li a7, 4
		la a0, character_str
		ecall
		j BACK3
		
		PRINT_SOLVED:
		li a7, 4
		la a0, solved_str
		ecall
		
		# store zeros into solved so it doesn't print next time
		sb zero, 0(s2)
		sb zero, 1(s2)
		
		j BACK3
		
		PRINT_TARGET:
		li a7, 4
		la a0, target_str
		ecall
		j BACK3
		
		PRINT_BOX:
		li a7, 4
		la a0, box_str
		ecall
		j BACK3
		
	END_PRINT_FOR1:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw s9, 36(sp)
	lw s10, 40(sp)
	addi sp, sp, 44
	
	lw ra, 0(sp)
	addi sp, sp, 4
	ret
	
# [1] Jabberwocky. 2018. Answer to "How does XorShift32 works?".
# Stack Overflow: Where Developers Learn, Share, & Build Careers. 
# Retrieved from https://stackoverflow.com/a/53886716
#
# This is a pseudorandom number generator.
#
# Arguments: an integer MAX in a0
# Return: A number from 0 (inclusive) to MAX (exclusive)
rand:
	addi sp, sp, -16
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	
	mv t3, a0
	la t0, seed
	lw t1, 0(t0)
	
	slli t2, t1, 13
	xor t1, t1, t2
	srli t2, t1, 17
	xor t1, t1, t2
	slli t2, t1, 5
	xor t1, t1, t2
	
	sw t1, 0(t0)
	
	remu a0, t1, t3
	
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	addi sp, sp, 16
    ret
