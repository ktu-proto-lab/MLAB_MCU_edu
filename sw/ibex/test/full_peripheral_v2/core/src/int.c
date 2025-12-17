#include "int.h"

#include "gpio.h"
#include "main.h"
#include "timer.h"

void GPIO_IRQHandler(void) { gpio_handler(); }

void I2C_IRQHandler(void) { while (1); }

void TIMER_IRQHandler(void) {
  volatile timer_reg_map_t *const timer = timer_init();
  timer_ack_intrq(timer);
  g_TIMER_int_status = 1;
}

void DEFAULT_IRQHandler(void) { while (1); }

__attribute__((interrupt)) void UART_RX_HALF_FULL_IRQHandler() { while(1); }

__attribute__((interrupt)) void UART_TX_HALF_EMPTY_IRQHandler() { while(1); }

__attribute__((interrupt)) void UART_RX_NOT_EMPTY_IRQHandler() { 
  UART_RX_Not_Empty_IRQHandler(&huart);
}

__attribute__((interrupt)) void UART_TX_NOT_FULL_IRQHandler() { 
  UART_TX_Not_Full_IRQHandler(&huart);
}