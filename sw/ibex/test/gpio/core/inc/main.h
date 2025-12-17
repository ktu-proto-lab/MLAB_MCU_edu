#ifndef __MAIN_H
#define __MAIN_H

#include "gpio.h"

extern GPIO_HandleTypeDef gpio;

#define TIMER_IRQ_HANDLER 0
#define GPIO_IRQ_HANDLER 1
#define I2C_IRQ_HANDLER 0

#define TIMER_IRQ_CALLBACK 0
#define GPIO_IRQ_CALLBACK 0
#define I2C_IRQ_CALLBACK 0

#endif // __MAIN_H
