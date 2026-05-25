#include "main.h"
#include "int.h"
#include <stdint.h>

// Sobel accelerator register map (see sobel_acc.sv header)
#define SOBEL_CTRL          (*(volatile uint32_t *)0x60000000)  // bit[0]: start
#define SOBEL_STATUS        (*(volatile uint32_t *)0x60000004)  // bit[1]: done
#define SOBEL_FRAME_COUNT   (*(volatile uint32_t *)0x60000008)  // Frame count

// GPIO register map (GPIO_reg_map_t offsets)
#define GPIO_OUT (*(volatile uint32_t *)0x40000004)  // output data
#define GPIO_OE  (*(volatile uint32_t *)0x40000008)  // output enable

int main() {
    // GPIO0 as output, start low
    GPIO_OE  = 0x1;
    GPIO_OUT = 0x0;

    // Set auto_start bit in accelerator (algo_sel=0: pixel inversion)
    SOBEL_CTRL = 0x1;

    // Poll SOBEL_FRAME_COUNT 
    while ((SOBEL_FRAME_COUNT) == 0);

    // Raise GPIO0 to signal the testbench that processing is done
    GPIO_OUT = 0x1;

    while (1);
    return 0;
}
