#include "int.h"

#include "main.h"

void GPIO_IRQHandler(void) __attribute__((interrupt));

void GPIO_IRQHandler(void) { while (1); }

void I2C_IRQHandler(void) __attribute__((interrupt));

void I2C_IRQHandler(void) { while (1); }

void TIMER_IRQHandler(void) __attribute__((interrupt));

void TIMER_IRQHandler(void) { while (1); }

void DEFAULT_IRQHandler(void) { while (1); }
