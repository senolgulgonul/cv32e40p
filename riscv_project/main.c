/* =============================================================================
   main.c — Demo C program for CV32E40P on Tang Nano 9K
   - Prints boot message over UART
   - Counts up and prints value every second
   - Walks LEDs
   ============================================================================= */

#include "hal.h"

int main(void) {
    uart_puts("CV32E40P on Tang Nano 9K\r\n");
    uart_puts("RISC-V is running!\r\n");
    uart_puts("--------------------------\r\n");

    uint32_t led_pattern = 1;
    int count = 0;

    while (1) {
        /* Update LEDs */
        led_set(led_pattern);

        /* Print counter */
        uart_puts("Count: ");
        uart_putint(count++);
        uart_puts("\r\n");

        /* Rotate LED pattern through 6 bits */
        led_pattern = ((led_pattern << 1) | (led_pattern >> 5)) & 0x3F;

        delay_ms(500);
    }

    return 0;
}
