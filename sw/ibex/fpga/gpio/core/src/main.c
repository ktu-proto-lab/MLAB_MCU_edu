//---------------------------------------------------------------------
// GPIO EXAMPLE

// GPIO6 and GPIO7 buttons
// IF GPIO6 is pressed leds increment in one direction
// IF GPIO7 is pressed leds increment in opposite direction
// led0 blinks while none of the buttons are pressed

#include <stdint.h>
#include "main.h"

#define CPUFreq                 50     // MHz

#define GPIO_BASE_ADDR 0x40000000

GPIO_HandleTypeDef gpio;


void DELAY_US(uint64_t wait){
  uint64_t cycle;
  uint32_t mcycle;
  uint32_t mcycleh;
  wait=wait*CPUFreq;
  __asm__ volatile ("csrr %0, mcycle":"=r"(mcycle));
  __asm__ volatile ("csrr %0, mcycleh":"=r"(mcycleh));
  cycle=mcycle | (uint64_t)mcycleh << 32;
  wait+=cycle;
  while (cycle < wait){
    __asm__ volatile ("csrr %0, mcycle":"=r"(mcycle));
    __asm__ volatile ("csrr %0, mcycleh":"=r"(mcycleh));
    cycle=mcycle | (uint64_t)mcycleh << 32;
  }
}

void DELAY_MS(uint64_t wait){
  DELAY_US(wait*1000);
}


int main() {
  
  
  GPIO_Init(&gpio);

  
  // Enable GPIOs 0 - 5 as outputs
  gpio.regs->OE = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 | GPIO_PIN_3 | GPIO_PIN_4 | GPIO_PIN_5;

  // Enable interrupts globally
  gpio.regs->CTRL = ENABLE_INT;

  // Enable interrupts on specific pins
  gpio.regs->INTE = GPIO_PIN_8 | GPIO_PIN_9;

  while (1) {
    if ((gpio.Interrupt_Status & GPIO_PIN_8)) {
      gpio.Interrupt_Status &= ~GPIO_PIN_8;
      // Turn on LEDs 1 to 5 incrementally
      for (int i = 1; i < 6; i++) {
        gpio.regs->OUT = (1 << i);
        // Delay to make LED toggle visible
         DELAY_MS(500);
      }
    } else if ((gpio.Interrupt_Status & GPIO_PIN_9)) {
      gpio.Interrupt_Status &= ~GPIO_PIN_9;
      // Turn on LEDs 5 to 1 incrementally
      for (int i = 5; i > 0; i--) {
        gpio.regs->OUT = (1 << i);
        // Delay to make LED toggle visible
        DELAY_MS(100);
      }
    } else {
      // Toggle LED 0
      gpio.regs->OUT ^= GPIO_PIN_0;
      DELAY_MS(100);
    }
  }

  return 0;
}

// void gpio_irq_handler() {
//   // Record interrupt status and clear all interrupts
//   gpio_int_status = GPIO->INTS;
//   GPIO->INTS = 0x0;
// }
