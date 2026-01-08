//---------------------------------------------------------------------
// GPIO EXAMPLE

#define GPIO_ADDR 0x40000000

#include <stdint.h>
#include "int.h"

volatile uint32_t counter = 1;      // Checks data initialization in dmem
volatile uint16_t stepper = 255;    // Checks half-word instructions

volatile uint32_t  gpio_int_status = 0; // Holds interrupt status

uint8_t numbers [10] = {0b00111111, // 0
                        0b00000110, // 1
                        0b01011011, // 2
                        0b01001111, // 3
                        0b01100110, // 4
                        0b01101101, // 5
                        0b01111101, // 6
                        0b00000111, // 7
                        0b01111111, // 8
                        0b01101111, // 9
};

int main() {
    //####################################################
    // GPIO testing
    //####################################################

    volatile uint32_t* gpio_regs;
    gpio_regs = (uint32_t*) GPIO_ADDR; // First GPIO reg - output register

    // All segments test one by one
    *(gpio_regs + 2) = 0xFF;
    for (int i = 0; i < 7; i++) {
        *(gpio_regs + 1) = (0x01 << i);
    }

    // All segments on
    *(gpio_regs + 1) = 0xFF;

    // Counts from 0 to 9
    for (int i = 0; i < 10; i++) {
        *(gpio_regs + 1) = numbers[i];
    }
}

void gpio_handler(void){
    volatile uint32_t* reg;

    reg = (uint32_t*) (GPIO_ADDR + 0x1C); // Interrupt status register
    gpio_int_status = *reg;               // Record interrupt status
    *reg = 0x0;                           // Clear interrupt status
}




