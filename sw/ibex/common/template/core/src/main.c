#include "main.h"

#include "int.h"

#if TIMER_IRQ_HANDLER
volatile g_timer_handle *timer_handle;
#endif

int main() { return 0; }

#if TIMER_IRQ_CALLBACK == 1
void timer_irq_callback(volatile timer_handle *timer_handle) {
  // User code goes here.
}
#endif

#if GPIO_IRQ_CALLBACK == 1
void gpio_irq_callback() {
  // User code goes here.
}
#endif

#if I2C_IRQ_CALLBACK == 1
void i2c_irq_callback() {
  // User code goes here.
}
#endif
