//---------------------------------------------------------------------
// GPIO EXAMPLE

#define GPIO_ADDR 0x40000000

#include <stdint.h>
#include "int.h"

void display_number(uint32_t value);

void display_number_timed(uint32_t value, uint32_t duration_us);

volatile uint32_t* gpio_regs = (uint32_t*) GPIO_ADDR; // First GPIO reg - output register

int main() {
    // To test the display function write a loop that counts from 0 to 9

    return 0;
}

void display_number(uint32_t value){
    // Implement the segment display driver HERE
    
}

void display_number_timed(uint32_t value, uint32_t duration_us){
    /*
     * Convert the desired delay (duration_us, in microseconds)
     * into the equivalent number of CPU cycles.
     */
    // uint64_t cycles = ;

    /*
     * UNCOMMENT the following for loop to use as a blocking delay function
     */

    // for(volatile int i=0; i<cycles; i++){
    //     __asm__ volatile ("nop");
    // }
}

// Ignore the following function. We're not using interrupts in this task
void gpio_handler(void){
}




