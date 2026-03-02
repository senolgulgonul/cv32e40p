/* =============================================================================
   link.ld — Linker script for CV32E40P on Tang Nano 9K
   IMEM: 4KB at 0x00000000
   DMEM: 4KB at 0x00010000
   ============================================================================= */

MEMORY {
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    DMEM (rwx) : ORIGIN = 0x00010000, LENGTH = 4K
}

ENTRY(_start)

SECTIONS {
    /* Startup code first */
    .text.start : {
        *(.text.start)
    } > IMEM

    /* Exception handler at fixed address 0x100 */
    .text.trap 0x100 : {
        *(.text.trap)
    } > IMEM

    /* Rest of code */
    .text : {
        *(.text*)
        *(.rodata*)
    } > IMEM

    /* Data section — loaded into DMEM */
    .data : {
        *(.data*)
    } > DMEM

    /* BSS — zero-initialised */
    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > DMEM

    /* Stack grows down from top of DMEM — no explicit section needed */
}
