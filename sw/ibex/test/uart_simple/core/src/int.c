#include "int.h"

#include "main.h"

void TIMER_IRQHandler(void) __attribute__((interrupt));

void TIMER_IRQHandler(void) {
#if TIMER_IRQ_HANDLER == 1
  timer_irq_handler();
#endif
#if TIMER_IRQ_CALLBACK == 1
  timer_irq_callback();
#endif
}

void GPIO_IRQHandler(void) __attribute__((interrupt));

void GPIO_IRQHandler(void) {
#if GPIO_IRQ_HANDLER == 1
  gpio_irq_handler();
#endif
#if GPIO_IRQ_CALLBACK == 1
  gpio_irq_callback();
#endif
}

void I2C_IRQHandler(void) __attribute__((interrupt));

void I2C_IRQHandler(void) {
#if I2C_IRQ_HANDLER == 1
  // Call I2C library function
  // Change function argument 'i2c' to suit your own code
  I2C_IRQ_Handler(&i2c);
#endif
#if I2C_IRQ_CALLBACK == 1
  i2c_irq_callback();
#endif
}

void DEFAULT_IRQHandler(void) { while (1); }


void UART_RX_HALF_FULL_IRQHandler(void) __attribute__((interrupt));

void UART_RX_HALF_FULL_IRQHandler(void) {
#if UART_IRQ_HANDLER == 1
#endif
#if UART_IRQ_CALLBACK == 1
#endif
}

void UART_RX_NOT_EMPTY_IRQHandler(void) __attribute__((interrupt));

void UART_RX_NOT_EMPTY_IRQHandler(void) {
#if UART_IRQ_HANDLER == 1
    UART_RX_Not_Empty_IRQHandler(&huart);
#endif
#if UART_IRQ_CALLBACK == 1
#endif
}

void UART_TX_HALF_EMPTY_IRQHandler(void) __attribute__((interrupt));

void UART_TX_HALF_EMPTY_IRQHandler(void) {
#if UART_IRQ_HANDLER == 1
#endif
#if UART_IRQ_CALLBACK == 1
#endif
}

void UART_TX_NOT_FULL_IRQHandler(void) __attribute__((interrupt));

void UART_TX_NOT_FULL_IRQHandler(void) {
#if UART_IRQ_HANDLER == 1
    UART_TX_Not_Full_IRQHandler(&huart);
#endif
#if UART_IRQ_CALLBACK == 1
#endif
}

