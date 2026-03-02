/* =============================================================================
   hal.h — Hardware Abstraction Layer for CV32E40P on Tang Nano 9K
   ============================================================================= */

#ifndef HAL_H
#define HAL_H

#include <stdint.h>

/* Peripheral base addresses */
#define LED_REG   (*((volatile uint32_t*)0x20000000))
#define UART_REG  (*((volatile uint32_t*)0x20000004))

/* LED helpers — bits[5:0], 1=on */
#define led_set(pattern)   (LED_REG = (pattern) & 0x3F)
#define led_on(n)          (LED_REG |=  (1 << (n)))
#define led_off(n)         (LED_REG &= ~(1 << (n)))

/* UART helpers */
static inline void uart_putc(char c) {
    /* Fixed delay instead of busy polling (2000 cycles > 1 char time) */
    UART_REG = (uint32_t)c;
    for (volatile int i = 0; i < 2000; i++);
}

static inline void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

static inline void uart_puthex(uint32_t val) {
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uint8_t nibble = (val >> i) & 0xF;
        uart_putc(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
    }
}

static inline void uart_putint(int val) {
    if (val < 0) { uart_putc('-'); val = -val; }
    if (val == 0) { uart_putc('0'); return; }
    char buf[12]; int i = 0;
    while (val > 0) { buf[i++] = '0' + (val % 10); val /= 10; }
    while (i > 0) uart_putc(buf[--i]);
}

/* Delay in approximate milliseconds (27MHz clock, rough calibration) */
static inline void delay_ms(int ms) {
    for (volatile int i = 0; i < ms * 2700; i++);
}

#endif /* HAL_H */
