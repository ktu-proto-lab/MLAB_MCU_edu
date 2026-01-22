//---------------------------------------------------------------------
// GPIO EXAMPLE

#define GPIO_ADDR 0x40000000

#include <stdint.h>
#include "int.h"

volatile uint32_t counter = 1;      // Checks data initialization in dmem
volatile uint16_t stepper = 255;    // Checks half-word instructions

volatile uint32_t  gpio_int_status = 0; // Holds interrupt status

void display_number(uint32_t value);

void display_number_timed(uint32_t value, uint32_t duration_us);

int main() {
    //####################################################
    // GPIO testing
    //####################################################

    volatile uint32_t* gpio_regs;
    gpio_regs = (uint32_t*) GPIO_ADDR; // First GPIO reg - output register

    // All segments test one by one
    

    // All segments on
    

    // Counts from 0 to 9
    
}

void gpio_handler(void){
    volatile uint32_t* reg;

    reg = (uint32_t*) (GPIO_ADDR + 0x1C); // Interrupt status register
    gpio_int_status = *reg;               // Record interrupt status
    *reg = 0x0;                           // Clear interrupt status
}




