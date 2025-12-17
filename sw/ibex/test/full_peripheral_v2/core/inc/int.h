#ifndef __IT_H
#define __IT_H

void GPIO_IRQHandler(void) __attribute__((interrupt));
void I2C_IRQHandler(void) __attribute__((interrupt));
void TIMER_IRQHandler(void) __attribute__((interrupt));

#endif
