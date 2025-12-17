#ifndef __MAIN_H
#define __MAIN_H

#include <stdint.h>
#include "uart.h"

extern uint32_t g_GPIO_int_status;
extern uint16_t g_TIMER_int_status;
extern UART_HandleTypeDef huart;

#endif /* __MAIN_H */
