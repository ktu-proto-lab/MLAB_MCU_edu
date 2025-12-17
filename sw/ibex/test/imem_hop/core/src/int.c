#include "main.h"

__attribute__((interrupt)) void GPIO_IRQHandler(void) {
  volatile gpio_handle *gpio_handle_ptr;
  gpio_handle_ptr = &g_gpio_handle;
  GPIO_ACK_INT_AND_SAVE_INTS(gpio_handle_ptr);
  gpio_irq_handler(&g_gpio_handle);
}

__attribute__((interrupt)) void I2C_IRQHandler(void) { while (1); }

__attribute__((interrupt)) void TIMER_IRQHandler(void) { while (1); }

__attribute__((interrupt)) void DEFAULT_IRQHandler(void) { while (1); }

__attribute__((interrupt)) void UART_RX_HALF_FULL_IRQHandler() { while (1); }

__attribute__((interrupt)) void UART_TX_HALF_EMPTY_IRQHandler() { while (1); }

__attribute__((interrupt)) void UART_RX_NOT_EMPTY_IRQHandler() { while (1); }

__attribute__((interrupt)) void UART_TX_NOT_FULL_IRQHandler() { while (1); }