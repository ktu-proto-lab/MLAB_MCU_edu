#include "gpio.h"

volatile GPIO_reg_map_t *const GPIO_init() {
  return (volatile GPIO_reg_map_t *const)GPIO_BASE_ADDR;
}