.section .data
newline:     .asciz "\n"
wall:        .asciz "#"
space:       .asciz " "
snake_char:  .asciz "O"
clear_code:  .asciz "\033[H\033[J"

snake_len:   .quad 5

// Each (row, col) pair is a snake segment
snake_body:
    .quad 5, 5
    .quad 5, 6
    .quad 5, 7
    .quad 5, 8
    .quad 5, 9

.section .text
.global _start

_start:
game_loop:
    // --- Clear Screen ---
    ldr x1, =clear_code
    mov x0, #1              // stdout
    mov x2, #6              // length of "\033[H\033[J"
    mov x8, #64             // syscall: write
    svc #0

    // --- Grid Dimensions ---
    mov x20, #50         // rows
    mov x21, #100        // columns

    mov x19, #0          // row counter

row_loop:
    cmp x19, x20
    bge after_draw

    mov x22, #0          // column counter

col_loop:
    cmp x22, x21
    bge end_row

    // Check if this cell is part of the snake
    mov x10, #0                          // snake index
    ldr x11, =snake_body                 // snake pointer
    ldr x12, =snake_len
    ldr x12, [x12]                       // snake_len value
check_snake_loop:
    cmp x10, x12
    bge check_wall                       // if no match, go to wall/space logic

    lsl x15, x10, #4                     // offset = x10 * 16
    add x16, x11, x15                    // base + offset
    ldr x13, [x16]                       // row
    ldr x14, [x16, #8]                   // col

    cmp x13, x19
    bne not_this_segment
    cmp x14, x22
    bne not_this_segment

    ldr x0, =snake_char
    b print_char

not_this_segment:
    add x10, x10, #1
    b check_snake_loop

check_wall:
    cmp x19, #0
    beq print_wall
    sub x23, x20, #1
    cmp x19, x23
    beq print_wall

    cmp x22, #0
    beq print_wall
    sub x24, x21, #1
    cmp x22, x24
    beq print_wall

    ldr x0, =space
    b print_char

print_wall:
    ldr x0, =wall

print_char:
    mov x1, x0
    mov x0, #1
    mov x2, #1
    mov x8, #64
    svc #0

    add x22, x22, #1
    b col_loop

end_row:
    ldr x1, =newline
    mov x0, #1
    mov x2, #1
    mov x8, #64
    svc #0

    add x19, x19, #1
    b row_loop

after_draw:
    // --- Move Snake Right ---
    ldr x10, =snake_body
    ldr x11, =snake_len
    ldr x11, [x11]

    mov x12, #0
move_loop:
    cmp x12, x11
    bge delay

    lsl x13, x12, #4       // offset = i * 16
    add x14, x10, x13      // &snake_body[i]
    add x15, x14, #8       // col address
    ldr x16, [x15]
    add x16, x16, #1       // col += 1
    str x16, [x15]

    add x12, x12, #1
    b move_loop

// --- Delay ---
delay:
    mov x0, #0
delay_loop:
    add x0, x0, #1
    cmp x0, #999       // simple delay loop
    blt delay_loop

    b game_loop            // loop back