//---------------------------------------------------------------------
// GPIO EXAMPLE

// GPIO6 and GPIO7 buttons
// IF GPIO6 is pressed leds increment in one direction
// IF GPIO7 is pressed leds increment in opposite direction
// led0 blinks while none of the buttons are pressed
#include "gpio.h"

#include <stdint.h>

#define GPIO_BASE_ADDR 0x40000000

GPIO_HandleTypeDef gpio;

volatile uint8_t shift_right, shift_left;

int main() {

  GPIO_Init(&gpio);

  // Enable GPIOs 0 - 5 as outputs
  gpio.regs->OE = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 | GPIO_PIN_3 |
                  GPIO_PIN_4 | GPIO_PIN_5;

  // Enable interrupts globally
  gpio.regs->CTRL = ENABLE_INT;

  // Enable interrupts on specific pins
  gpio.regs->INTE = GPIO_PIN_6 | GPIO_PIN_7;

  while (1) {
    if (shift_right) {
      shift_right = 0;
      // Turn on LEDs 1 to 5 incrementally
      for (int i = 1; i < 6; i++) {
        gpio.regs->OUT = (1 << i);
        // Delay to make LED toggle visible
        // for (volatile int i = 0; i < 3338853; i++);
      }
    } else if ((shift_left)) {
      shift_left = 0;
      // Turn on LEDs 5 to 1 incrementally
      for (int i = 5; i > 0; i--) {
        gpio.regs->OUT = (1 << i);
        // Delay to make LED toggle visible
        // for (volatile int i = 0; i < 3338853; i++);
      }
    }
  }

  return 0;
}

void GPIO_EXTI_Callback(GPIO_HandleTypeDef *gpio) {
  if (gpio->Interrupt_Status & GPIO_PIN_6) {
    shift_right = 1;
  }
  if (gpio->Interrupt_Status & GPIO_PIN_7) {
    shift_left = 1;
  }
}
