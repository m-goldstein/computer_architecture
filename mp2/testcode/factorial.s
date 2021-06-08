factorial.s:
.align 4
.section .text
.globl factorial
# Registers
# a0 -- input / output value; for passing data to and from caller function
# t0 -- loaded with input value
# t1 -- stores memory address of output
# t2 -- iter_loop counter, from 1 up to a0
# t3 -- previous iter_loop result
# t4 -- stores result / used for canary check
# t5 -- accumulator counter
# ra -- address of where to resume execution from
factorial:
    addi t0, a0, 0               # t0 <-- input + 0
    lw t2, posone                # t2 <= 1 (iter_loop counter)
    lw t3, posone                # t3 <= 1
    addi t4, t3, 0               # t4 <= t3 + 0 (result)
    beq a0, t4, done             # branch to done if a0 == t4 (input = 1)
iter_loop:
    xor t4, t4, t4               # t4 <= 0      (iteration sum)
    xor t5, t5, t5               # t5 <= 0      (accumulator loop counter)
accumulator:
    add t4, t4, t3               # t4 <= t4 + t3
    addi t5, t5, 1               # t5 <= t5 + 1; increment accumulator loop counter
    bltu t5, t2, accumulator     # branch if t5 < t2
    addi t3, t4, 0               # t3 <= t4 + 0
    addi t2, t2, 1               # t2 <= X2 + 1; increment iteration loop counter
    bltu t2, t0, iter_loop       # branch if t2 < t0
    beq t2, t0, iter_loop        # branch if t2 = t0
done:
    la t1, output                # t1 <= output
    sw t4, 0(t1)                 # [output] <= t4 ; store contents of t4 into memory location output
    lw a0, output                # a0 <= [output]
    bne t4, a0, canary           # PC <= canary if a0 != t4
ret:
    jr ra                        # return to caller
halt:
    beq t4, t4, halt             # infinite loop at the end to stop processor
                                 # from reaching instructions below
# serves as a canary to signal execution is about to occur in the data section
# forces processor not to execute code below...
## taken from riscv_mp2test.s
canary:
    lw t0, deadbeef                   # t0 <= 0xdeadbeef
badloop:
    beq t0, t0, badloop        

.section .rodata
posone:    .word   0x00000001
output:    .word   0x00000000
deadbeef:  .word   0xdeadbeef
