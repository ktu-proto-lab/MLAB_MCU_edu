//---------------------------------------------------------------------
// GPIO EXAMPLE

#define GPIO_ADDR 0x40000000

#include <stdint.h>
#include "int.h"

volatile uint32_t counter = 1;      // Checks data initialization in dmem
volatile uint16_t stepper = 255;    // Checks half-word instructions

volatile uint32_t  gpio_int_status = 0; // Holds interrupt status

int main() {
    //####################################################
    // General CPU testing
    //####################################################

    volatile uint32_t result;
    // Executes load, store, branch, add instructions
    while (counter < 10) {
        counter++;  
    }
    result = (uint32_t)(stepper * counter); // Check multiplication

    //####################################################
    // GPIO testing
    //####################################################

    volatile uint32_t* gpio_regs;
    gpio_regs = (uint32_t*) GPIO_ADDR; // First GPIO reg - output register

ž    *(gpio_regs + 6) = 0x01;
ž    *(gpio_regs + 3) = 0x08;

    while(1){
        if(gpio_int_status == 0x8){ // IF GPIO3 triggered an interrupt
            // Clear int status
            gpio_int_status = 0;
            for (int i = 0; i < 4; i++) {
                *(gpio_regs + 2) = (0x10 << i); 
                *(gpio_regs + 1) = (0x10 << i); 
            }
        }
    }
}

void gpio_handler(void){
    volatile uint32_t* reg;

    reg = (uint32_t*) (GPIO_ADDR + 0x1C); // Interrupt status register
    gpio_int_status = *reg;               // Record interrupt status
    *reg = 0x0;                           // Clear interrupt status
}




