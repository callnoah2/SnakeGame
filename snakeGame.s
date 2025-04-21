.equ speed1, 0xF0000
.equ speed2, 0x8F00
.equ speed3, 0xFF0

.text
.global main
.global _start
_start:
    BL main

main:
    MOV     x9, #3                  // x9 will hold total elements in the list (snake length)
    BL      seed                    // call seed function

    ADRP    x3, init                // get page base of `init`
    ADD     x3, x3, :lo12:init      // x3 = address of init (TOP OF QUEUE)
    MOV     x4, x3                  // x4 = bottom of the queue
    MOV     x7, #0x5F
    MOV     x11, #0xFF              // max queue size
    MOV     x11, #64                // max queue size (256 bytes / 4 bytes per word)

    MOV     x0, #0                  // syscall arg 0 (clear screen might be mapped to x0?)
    MOV     x8, #0x206              // syscall number for clear screen
    SVC     #0                      // software interrupt (supervisor call)

        MOV     x10, #240
    STR     x10, [x3], #4           // store 240, post-increment x3 by 4
    MOV     x10, #241
    STR     x10, [x3], #4           // store 241, post-increment x3 by 4
    MOV     x10, #242
    STR     x10, [x3]               // store 242

    MOV     x1, #8                  // y coordinate
    ADRP    x2, star
    ADD     x2, x2, :lo12:star      // x2 = address of star

    MOV     x0, #16                 // x coordinate
    MOV     x8, #0x204              // syscall for drawing character
    SVC     #0                      // draw first star

    ADD     x0, x0, #1
    SVC     #0                      // draw second star

    ADD     x0, x0, #1
    SVC     #0                      // draw third star

    BL createbox
	BL RANDOMPOINT

start:
	MOV X0, #0
	SVC #0x203
	CMP X0, #0
	B.NE CHK
	B start

Qseed:
    BL RANDOMPOINT
    RET

QRANDOMPOINT:
    BL RANDOMPOINT
    RET

CHK:
	CLZ X5, X6           // Count leading zeros in X6
	SUB X5, X5, #64      // X5 = 64 - CLZ => index of first set bit

	CMP X5, #2
	B.EQ TOP

	CMP X5, #5
	B.EQ LEFT

	CMP X5, #7
	B.EQ RIGHT

	CMP X5, #10
	B.EQ BOT

	B start

TOP:
    SUBS    x11, x11, #1        // Decrease queue size
    B.LE    COPYBACK            // If <= 0, restore queue

    LDR     x10, [x3]           // Load current head position
    CMP     x10, #32
    B.LT    GAMEOVER            // If it's off the top of the screen

    SUB     x10, x10, #32       // Move up one row

    // --- Boundary check ---
    ADRP    x12, init
    ADD     x12, x12, :lo12:init  // x12 = address of init
    SUB     x0, x3, x12         // difference in bytes from start
    LSR     x0, x0, #2          // compute number of words written
    CMP     x0, #64
    B.GE    GAMEOVER            // if we have reached (or exceeded) 64, game over

    // --- End boundary check ---
    ADD     x3, x3, #4
    STR     x10, [x3]

    BL      intersection
    BL      Delay
    BL      DELETE
    BL      PRINT 
    BL      CHECKu
    B       TOP

BOT:
    SUBS    X11, X11, #1
    B.LE    COPYBACK

    LDR     X10, [X3]
    MOV     X5, #385
    CMP     X10, X5
    B.GE    GAMEOVER

    ADD     X10, X10, #32        // Move down one row

    ADRP    X12, init
    ADD     X12, X12, :lo12:init  // X12 = address of init
    SUB     X0, X3, X12         // Compute difference from init
    LSR     X0, X0, #2          // Convert bytes to word count
    CMP     X0, #64
    B.GE    GAMEOVER            // If out of bounds, game over
  
    ADD     X3, X3, #4
    STR     X10, [X3]

    BL      intersection
    BL      Delay
    BL      DELETE
    BL      PRINT 
    BL      CHECKb
    B       BOT

LEFT:
    SUBS X11, X11, #1
    B.LE COPYBACK  // Queue full, reset

    LDR X10, [x3]
    LSL X8, X10, #27
    CMP X8, #0
    B.EQ GAMEOVER

    SUB X10, X10, #1
    ADD X3, X3, #4

    ADRP    X12, init
    ADD     X12, X12, :lo12:init  // X12 = base address of the snake queue
    SUB     X0, X3, X12         // Compute difference from the base
    LSR     X0, X0, #2          // Convert from bytes to word count
    CMP     X0, #64
    B.GE    GAMEOVER            // Out of bounds, game over

    
    STR X10, [x3]

    BL intersection
    BL Delay
    BL DELETE
    BL PRINT 
    BL CHECKl
    B LEFT

RIGHT:
    SUBS X11, X11, #1
    B.LE COPYBACK

    LDR X10, [X3]
    AND X8, X10, #0x1F
    CMP X8, #0x1F
    B.EQ GAMEOVER

    ADD X10, X10, #1
    ADD X3, X3, #4

    // --- Boundary check for RIGHT ---
    ADRP    X12, init
    ADD     X12, X12, :lo12:init  // X12 = base address of the snake queue
    SUB     X0, X3, X12          // Compute difference from base
    LSR     X0, X0, #2           // Convert bytes to word count
    CMP     X0, #64
    B.GE    GAMEOVER             // Out of bounds, game over
    // --- End boundary check ---
    
    STR X10, [X3]

    BL intersection
    BL Delay
    BL DELETE
    BL PRINT 
    BL CHECKr
    B RIGHT

DELETE:
	STP X29, X30, [SP, #-16]!      // Push frame
	LDR X2, =space
	LDR X10, [X4]
	AND X0, X10, #0x1F             // X position (lowest 5 bits)
	LSR X1, X10, #5                // Y position
	ADD X1, X1, #1                 // Adjust y offset
	SVC #0x204                     // Print " " at (X0, X1)
	ADD X4, X4, #4                 // Move tail pointer forward
	LDP X29, X30, [SP], #16       // Pop frame
	RET

PRINT:
	STP X29, X30, [SP, #-16]!      // Push frame
	LDR X2, =star
	LDR X10, [X3]
	AND X0, X10, #0x1F             // X position
	LSR X1, X10, #5                // Y position
	ADD X1, X1, #1
	SVC #0x204                     // Print "*"
	LDP X29, X30, [SP], #16       // Pop frame
	RET

CHECKu:
    STP     X29, X30, [SP, #-16]!          // Push frame
    LDR     X10, [X3]
    CMP     X10, X7
    B.NE    CHECKu_NoUpdate                // If not equal, skip update block

    // Update block (was executed conditionally via addeq/subeq/...)
    ADD     X9, X9, #1                     // Increment snake length
    SUB     X10, X10, #32                  // Adjust head position
    ADD     X3, X3, #4                     // Update pointer into queue
    STR     X10, [X3]
    // You had two BLEQ instructions. Here we branch if condition holds.
    CMP     X10, #0                       // (Example comparison; adjust as needed)
    BLE     PRINT
    BLE     RANDOMPOINT

CHECKu_NoUpdate:
    MOV     X0, #0
    SVC     #0x203                        // Get key input
    CMP     X0, #0
    BEQ     CHK
    MOV     X6, X0
    LDP     X29, X30, [SP], #16           // Pop frame
    RET

CHECKb:
	STP X29, X30, [SP, #-16]!      // Push frame
	LDR X10, [X3]
	CMP X10, X7
	ADD X9, X9, #1
	ADD X10, X10, #32
	ADD X3, X3, #4
	STR X10, [X3]
	BL PRINT
	BL RANDOMPOINT
	MOV X0, #0
	SVC #0x203                     // Get key input
	CMP X0, #0
	MOV X6, X0
	BNE CHK
	LDP X29, X30, [SP], #16       // Pop frame
	RET

CHECKl:
	STP X29, X30, [SP, #-16]!      // Push frame
	LDR X10, [X3]
	CMP X10, X7
	ADD X9, X9, #1
	SUB X10, X10, #1
	ADD X3, X3, #4
	STR X10, [X3]
	BL PRINT
	BL RANDOMPOINT
	MOV X0, #0
	SVC #0x203                     // Get key input
	CMP X0, #0
	MOV X6, X0
	BNE CHK
	LDP X29, X30, [SP], #16       // Pop frame
	RET

CHECKr:
	STP X29, X30, [SP, #-16]!      // Push frame
	LDR X10, [X3]
	CMP X10, X7
	ADD X9, X9, #1
	ADD X10, X10, #1
	ADD X3, X3, #4
	STR X10, [X3]
	BL PRINT
	BL RANDOMPOINT
	MOV X0, #0
	SVC #0x203                     // Get key input
	CMP X0, #0
	MOV X6, X0
	BNE CHK
	LDP X29, X30, [SP], #16       // Pop frame
	RET

GAMEOVER:     // Gameover conditions
	LDR X2, =gameover
	MOV X0, #0
	MOV X1, #0
	SVC #0x204                   // Print gameover message
	MOV X1, #1
	LDR X2, =Cscore
	SVC #0x204                   // Print "Your score is"
	MOV X2, X9                    // Print score value
	MOV X0, #15
	SVC #0x205                   // Print score

	MOV X0, #0

	BL gethighscore
	CMP X9, X3
	BLE prints
	BL storehighscore
	MOV X1, #2
	LDR X2, =congo
	MOV X0, #0
	SVC #0x204                   // Print "You got a highscore Congrats :-)"
	
	BL gethighscore
prints:
	MOV X0, #0
	MOV X1, #3
	LDR X2, =Hscore
	SVC #0x204                   // Print "Highest score ever is"
	MOV X2, X3                    // Print highscore value
	MOV X0, #24
	SVC #0x205                   // Print highscore value

end:
	SVC #0x11                     // Exit the program

RANDOMPOINT:
gen:
    SUB     SP, SP, #16           // allocate 16 bytes to save X5
    STR     X5, [SP]              // push X5
    
    BL      seed                  // call seed function to randomize
    LDR     X7, =rand             // load address of rand
    LDR     X7, [X7]              // fetch random seed value
    LDR     X5, =0x1FF            // mask value
    AND     X7, X7, X5            // apply mask
    LDR     X5, =404              // threshold
    CMP     X7, X5              // compare
    SUB     X7, X7, #0xFF         // adjust if needed

    BL      intersectionfood      // now returns a success flag in X0 (1 = good; 0 = regenerate)
    CMP     X0, #0
    BEQ     gen                 // if failure, generate another point

    LDR     X2, =food             // load food symbol address
    AND     X0, X7, #0x1F         // calculate x coordinate
    MOV     X1, X7, LSR #5        // calculate y coordinate (shift right)
    ADD     X1, X1, #1            // adjust y offset
    svc     #0x204                // print food

    LDR     X5, [SP]              // restore saved X5
    ADD     SP, SP, #16           // free stack space
    RET

COPYBACK:
    // Push X5 using a one–register push
    SUB     SP, SP, #16           // allocate 16 bytes
    STR     X5, [SP]              // save X5

    MOV     X5, X9                // Move R9 to X5 (temporary storage)
    LDR     X8, =init             // Load address of init (initial snake body position)
loopi:
    LDR     X6, [X4]              // Load current snake body part from back of queue
    STR     X6, [X8]             // Store it to the beginning of the snake's body
    ADD     X8, X8, #4           // Advance pointer
    ADD     X4, X4, #4           // Advance pointer in queue
    SUB     X5, X5, #1           // Decrement part count
    CMP     X5, #0
    BNE     loopi
    SUB     X3, X8, #4           // New head position

    LDR     X4, =init            // Reload initial position
    LDR     X11, =0xFF           // Set queue size

    // Pop X5 and restore
    LDR     X5, [SP]
    ADD     SP, SP, #16
    RET

Delay:
    // Push X6
    SUB     SP, SP, #16
    STR     X6, [SP]

    CMP     X9, #10
    MOV     X6, #speed1         // Use speed1 if snake length <= 10
    CMP     X9, #20
    MOV     X6, #speed2         // Use speed2 if snake length > 10
    MOV     X6, #speed3         // Otherwise, use speed3
loopj:
    CMP     X6, #0
    SUB     X6, X6, #1
    BNE     loopj

    // Pop X6 and restore X29 if needed (here assuming X29 was saved before)
    LDP     X6, X29, [SP]       // if two registers were pushed; otherwise use LDR for one
    ADD     SP, SP, #16
    RET

createbox:
    SUB     SP, SP, #16         // push X6
    STR     X6, [SP]

    MOV     X0, #0
    MOV     X6, #32             // loop counter for dashes
    LDR     X2, =dash
loopk:
    MOV     X1, #0
    svc     #0x204             // print dash (replaces swi 0x204)
    MOV     X1, #14
    svc     #0x204             // print another character
    SUB     X6, X6, #1
    ADD     X0, X0, #1
    CMP     X6, #0
    BNE     loopk

    MOV     X1, #1
    MOV     X0, #32
    MOV     X6, #32             // loop counter for pipes
    LDR     X2, =pipe
loopl:
    svc     #0x204             // print pipe character
    SUB     X6, X6, #1
    ADD     X1, X1, #1
    CMP     X6, #0
    BNE     loopl

    LDR     X6, [SP]            // pop X6
    ADD     SP, SP, #16
    RET

seed:
    SUB     SP, SP, #16         // push X6
    STR     X6, [SP]
    
    LDR     X6, =rand           // load address of rand
    svc     #0x6d              // get current time (or RNG seed) – replaces swi 0x6d
    STR     X0, [X6]            // store seed
    
    LDR     X6, [SP]            // restore X6
    ADD     SP, SP, #16
    RET

intersection:	// Checking whether snake intersects itself
	SUB     SP, SP, #32
    STP     X5, X10, [SP]         // store X5 and X10 at offset 0
    STP     X12, XZR, [SP, #16]    // store X12 and a dummy at offset 16
	MOV X5, X9                    // Move R9 (snake length) to X5
	LDR X10, [X3]                 // Load current element of the snake into X10
	MOV X12, X4                   // Move the bottom of the queue (R4) to X12

loopm:
	LDR X6, [X12], #4             // Load the next snake segment
	CMP X6, X10                   // Compare the segment with the head (X10)
	BEQ GAMEOVER                  // If they are equal, it's a game-over situation
	SUB X5, X5, #1                // Decrement the snake length
	CMP X5, #0                    // If snake length is zero, end loop
	BNE loopm                     // If not zero, continue looping
	LDP     X5, X10, [SP]
    LDP     X12, XZR, [SP, #16]
    ADD     SP, SP, #32

intersectionfood:
    SUB     SP, SP, #32           // allocate 32 bytes to save 3 registers
    STP     X5, X10, [SP]         // save X5 and X10
    STP     X12, XZR, [SP, #16]    // save X12 and dummy

    // Set up for the check: use snake length in X5 and current food candidate in X7
    MOV     X5, X9                // move snake length into X5
    LDR     X10, [X3]             // load the head of the snake (current food candidate)
    MOV     X12, X4               // get bottom of snake queue

loopn:
    LDR     X6, [X12], #4         // load next snake segment
    CMP     X6, X7                // compare segment to candidate food coordinate
    B.LE    fail_food           // if candidate is less or equal, indicate failure
    SUB     X5, X5, #1            // decrement count
    CMP     X5, #0
    B.NE    loopn                // continue if more segments remain

    MOV     X0, #1                // success flag: food does not intersect snake
    B       end_intfood

fail_food:
    MOV     X0, #0                // failure flag: regenerate food

end_intfood:
    LDP     X5, X10, [SP]
    LDP     X12, XZR, [SP, #16]
    ADD     SP, SP, #32
    RET

storehighscore:
    SUB     SP, SP, #32                 // allocate 32 bytes for three registers
    STP     X5, X0, [SP]                // save X5 and X0 at offset 0
    STP     X1, XZR, [SP, #16]           // save X1 and use XZR as dummy
    
    LDR     X0, =highscore              // load highscore filename address
    MOV     X1, #1                      // open for write mode
    svc     #0x66                     // system call (open file)
    LDR     X1, =OutFileHandle          // get pointer to file handle storage
    STR     X0, [X1]                    // store file handle
    
    LDR     X0, =OutFileHandle
    LDR     X0, [X0]                    // load file handle
    MOV     X1, X9                      // move score into X1
    svc     #0x6B                     // write system call
    MOV     X3, X0                      // move returned file data
    LDR     X0, =OutFileHandle
    LDR     X0, [X0]
    svc     #0x68                     // close file system call
    
    LDP     X1, XZR, [SP, #16]          // restore X1 (and dummy)
    LDP     X5, X0, [SP]                // restore X5 and X0
    ADD     SP, SP, #32                 // free allocated space
    RET

gethighscore:
    SUB     SP, SP, #32 
    STP     X5, X0, [SP] 
    STP     X1, XZR, [SP, #16]
    
    LDR     X0, =highscore
    MOV     X1, #0                      // open for reading
    svc     #0x66                     // open file
    LDR     X1, =InFileHandle
    STR     X0, [X1]
    
    LDR     X0, =InFileHandle
    LDR     X0, [X0]
    BCS     storehighscore              // if error, branch to storehighscore
    svc     #0x6C                     // read file
    MOV     X3, X0                      // store file data in X3
    
    LDR     X0, =InFileHandle
    LDR     X0, [X0]
    svc     #0x68                     // close file
    LDP     X1, XZR, [SP, #16]
    LDP     X5, X0, [SP]
    ADD     SP, SP, #32
    RET

	.data
OutFileHandle: .word 0              // Initialize output file handle
InFileHandle: .word 0               // Initialize input file handle
chararray: .skip 80                 // Reserve space for 80 bytes
gameover: .asciz "Game Over" // Game over message
Cscore:   .asciz "Your score is "  // Score message
Hscore:   .asciz "Highest score ever is " // Highest score message
congo:    .asciz "You are now the proud owner of the highscore" // Congratulatory message

space:    .asciz " "                // Single space character
star:     .asciz "*"                // Star symbol
food:     .asciz "#"                // Food symbol
dash:     .asciz "-"                // Dash symbol
pipe:     .asciz "|"                // Pipe symbol
rand:     .word 80                  // Reserve 80 bytes for random number seed

highscore: .asciz "HighScore.sha"   // Highscore filename
init: .skip 256   // Allocate 256 bytes for the snake queue

	.end