/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Firmware for compress_acc full-system testbench.
    *
    * Sequence:
    *   1. Enable auto_start - the accelerator begins as soon as the inter
    *      FIFO has data (injected by the testbench).
    *   2. Poll STATUS.done (bit 1) - set when one full frame of TOTAL_PIXELS
    *      bytes has been consumed and compressed.
    *   3. Raise GPIO0 - signals the testbench that results are ready.
*/
#include "main.h"
#include "int.h"
#include <stdint.h>

#define COMPRESS_CTRL   (*(volatile uint32_t *)0x70000000)
#define COMPRESS_STATUS (*(volatile uint32_t *)0x70000004)
#define COMPRESSED_SIZE (*(volatile uint32_t *)0x70000008)

#define GPIO_OUT (*(volatile uint32_t *)0x40000004)
#define GPIO_OE  (*(volatile uint32_t *)0x40000008)

int main(void) {
    GPIO_OE  = 0x1;
    GPIO_OUT = 0x0;

    COMPRESS_CTRL = 0x1;

    while (!(COMPRESS_STATUS & 0x2));

    GPIO_OUT = 0x1;

    while (1);
    return 0;
}
