#include "main.h"

#include <stdint.h>

#include "test.h"

// Interrupts.
#include "int.h"

// Drivers.
#include "gpio.h"
#include "i2c_master.h"
#include "timer.h"

#define FLASH_BASE_ADDR 0xA0000000

#define GPIO_BASE_ADDR 0x40000000

GPIO_HandleTypeDef gpio;
I2C_HandleTypeDef I2C;


volatile uint32_t flashread;

int main() {
  GPIO_Init(&gpio);
  // Enable GPIOs 0 - 7 as outputs
  gpio.regs->OE = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 | GPIO_PIN_3 |
  GPIO_PIN_4 | GPIO_PIN_5 | GPIO_PIN_6 | GPIO_PIN_7;


  volatile uint32_t* flash;
  flash = (uint32_t*) FLASH_BASE_ADDR; // First GPIO reg - output register

  for (int j = 0; j<16; j++){
    flashread = *(flash + j);
    for (int i = 0; i<4; i++){
      gpio.regs->OUT = (flashread >> (i*8)) & 0xFF;
    }
  }




  return 0;
}

void gpio_handler() {
  // Record interrupt status and clear all interrupts.
  // GPIO->INTS = 0;
}
