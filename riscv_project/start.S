/* =============================================================================
   start.S — Bare-metal startup for CV32E40P on Tang Nano 9K
   Sets up stack pointer, clears BSS, calls main()
   ============================================================================= */

.section .text.start
.global _start

_start:
    /* Set stack pointer to top of DMEM (0x10FFC) */
    lui  sp, 0x11
    addi sp, sp, -4

    /* Clear BSS section */
    la   a0, __bss_start
    la   a1, __bss_end
bss_loop:
    bge  a0, a1, bss_done
    sw   zero, 0(a0)
    addi a0, a0, 4
    j    bss_loop
bss_done:

    /* Call main */
    call main

    /* If main returns, loop forever */
halt:
    j halt

/* =============================================================================
   Exception/interrupt handler — just loop forever
   ============================================================================= */
.section .text.trap
.global _trap_handler
.align 2
_trap_handler:
    j _trap_handler
