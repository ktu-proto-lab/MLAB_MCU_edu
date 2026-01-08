#include "int.h"

#include "main.h"

void GPIO_IRQHandler(void) __attribute__((interrupt));

void GPIO_IRQHandler(void) { while (1); }

void I2C_IRQHandler(void) __attribute__((interrupt));

void I2C_IRQHandler(void) { while (1); }

void TIMER_IRQHandler(void) __attribute__((interrupt));

void TIMER_IRQHandler(void) {
  timer_ack_intrq(timer_ptr);
  timer_set(timer_ptr, (uint16_t)0x10U, (uint16_t)0x04U);
}

void DEFAULT_IRQHandler(void) { while (1); }
