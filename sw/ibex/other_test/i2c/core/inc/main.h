#ifndef __MAIN_H
#define __MAIN_H

#include "i2c_master.h"

#define TIMER_IRQ_HANDLER 0
#define GPIO_IRQ_HANDLER 0
#define I2C_IRQ_HANDLER 1

#define TIMER_IRQ_CALLBACK 0
#define GPIO_IRQ_CALLBACK 0
#define I2C_IRQ_CALLBACK 0

extern I2C_HandleTypeDef i2c;

#endif /* __MAIN_H */
