#ifndef __MAIN_H
#define __MAIN_H

#include "timer.h"

#define TIMER_IRQ_HANDLER 1
#define GPIO_IRQ_HANDLER 0
#define I2C_IRQ_HANDLER 0

#define TIMER_IRQ_CALLBACK 1
#define GPIO_IRQ_CALLBACK 0
#define I2C_IRQ_CALLBACK 0

#if TIMER_IRQ_HANDLER == 1
// Global handler (must be defined in 'main.c').
extern volatile timer_handle g_timer_handle;

// Declare timer handler (defined in 'timer.c' driver).
void timer_irq_handler(volatile timer_handle *timer_handle);
#endif

#if TIMER_IRQ_CALLBACK == 1
void timer_irq_callback(volatile timer_handle *timer_handle);
#endif

#endif  // __MAIN_H
