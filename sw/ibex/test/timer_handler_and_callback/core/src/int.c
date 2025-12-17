#include "int.h"

#include "main.h"

void TIMER_IRQHandler(void) __attribute__((interrupt));

void TIMER_IRQHandler(void) {
#if TIMER_IRQ_HANDLER == 1
  timer_irq_handler(&g_timer_handle);
#endif
#if TIMER_IRQ_CALLBACK == 1
  timer_irq_callback(&g_timer_handle);
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
  i2c_irq_handler();
#endif
#if I2C_IRQ_CALLBACK == 1
  i2c_irq_callback();
#endif
}

void DEFAULT_IRQHandler(void) { while (1); }
