#include "int.h"

#include "gpio.h"

void GPIO_IRQHandler(void) __attribute__((interrupt));

void GPIO_IRQHandler(void) { gpio_handler(); }

void I2C_IRQHandler(void) __attribute__((interrupt));

void I2C_IRQHandler(void) { while (1); }

void TIMER_IRQHandler(void) __attribute__((interrupt));

void TIMER_IRQHandler(void) { while (1); }


void UART_RX_HALF_FULL_IRQHandler(void) __attribute__((interrupt));

void UART_RX_HALF_FULL_IRQHandler(void) { while (1); }

void UART_TX_HALF_EMPTY_IRQHandler(void) __attribute__((interrupt));

void UART_TX_HALF_EMPTY_IRQHandler(void) { while (1); }

void UART_RX_NOT_EMPTY_IRQHandler(void) __attribute__((interrupt));

void UART_RX_NOT_EMPTY_IRQHandler(void) { while (1); }

void UART_TX_NOT_FULL_IRQHandler(void) __attribute__((interrupt));

void UART_TX_NOT_FULL_IRQHandler(void) { while (1); }


void DEFAULT_IRQHandler(void) { while (1); }


