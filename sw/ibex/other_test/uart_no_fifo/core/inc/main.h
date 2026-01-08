#ifndef __MAIN_H
#define __MAIN_H

#include "uart.h"

#define TIMER_IRQ_HANDLER 0
#define GPIO_IRQ_HANDLER 0
#define I2C_IRQ_HANDLER 0
#define UART_IRQ_HANDLER 1

#define TIMER_IRQ_CALLBACK 0
#define GPIO_IRQ_CALLBACK 0
#define I2C_IRQ_CALLBACK 0
#define UART_IRQ_CALLBACK 0

extern UART_HandleTypeDef huart;

#endif /* __MAIN_H */
