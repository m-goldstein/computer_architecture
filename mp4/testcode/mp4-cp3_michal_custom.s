#  mp4-cp1.s version 4.0
.align 4
.section .text
.globl _start
_start:

    nop
  	lw x1, GOOD
	lw x2, GOOD
	lw x3, GOOD
	lw x1, GOOF
	la x4, ONE
	sw x3, 0(x4)
	lw x5, ONE

	la x2, TWO
	sb x1, 0(x2)
	lw x5, TWO

	la x2, ONE
	sh x1, 2(x2)
	lw x5, ONE

	andi x31, x31, 0   #x31 = 0
	addi x6, x31, 5    #x6 = 5
	slti x6, x6, 6     #x6 = 1
	slti x6, x6, 0     #x6 = 0

	lw x6, NEGTWO      # x6 = 0xfffffffe
	#nop
	#nop
	nop
	#and x5, x6, x6
	sw x6, 0(x2)
	lw x5, ONE         # x5 = 0xfffffffe

	bne x0, x0, LOOP
	lw x10, GOOD
	lw x11, GOOD
	lw x12, GOOD       #x10,11,12 = 600d600d

	beq x0, x0, LOOP
	lw x10, BADD
	lw x11, BADD
	lw x12, BADD

PASS:
	lw x8, GOOD
	jal x0, HALT
	lw x5, ONE
	lw x6, ONE
	lw x7, ONE
	
HALT:
    beq x0, x0, HALT
    nop
    nop
    nop
    nop
    nop
    nop
    nop
	

.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
THREE:  .word 0x00000003
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD
BYTES:  .word 0x04030201
HALF:   .word 0x0020FFFF
GOOF:   .word 0x0000600F

LOOP:
	la x1, PASS
	jalr x0, x1, 0 
	nop
	nop
	nop
