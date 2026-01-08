#include <stdint.h>

#include "timer.h"

volatile timer_reg_map_t *timer_ptr;

int main() {
  timer_ptr = timer_init();
  timer_set(timer_ptr, (uint16_t)0x20U, (uint16_t)0xFU);
  timer_en(timer_ptr);
  while (1);
  return 0;
}
