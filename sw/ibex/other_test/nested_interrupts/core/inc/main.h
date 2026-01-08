#ifndef __MAIN_H
#define __MAIN_H

#include <stdint.h>

#include "gpio.h"
#include "timer.h"
#include "i2c_master.h"

// To run on FPGA set to 1
#define FPGA 0

#define NESTED_IRQ 1

#define TIMER_IRQ_HANDLER 1
#define GPIO_IRQ_HANDLER 1
#define I2C_IRQ_HANDLER 1

#if TIMER_IRQ_HANDLER == 1
extern timer_handle g_timer_handle;
#endif

#if GPIO_IRQ_HANDLER == 1
extern gpio_handle g_gpio_handle;
#endif

#if I2C_IRQ_HANDLER == 1
extern i2c_handle g_i2c_handle;
#endif


#endif  // __MAIN_H
