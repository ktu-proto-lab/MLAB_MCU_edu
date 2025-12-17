#include "timer.h"

void timer_irq_handler(volatile timer_handle *timer_handle) { timer_handle->regs->CTRL = TIMER_CTRL_FLAG; }

void timer_handle_init(volatile timer_handle *timer_handle) {
  timer_handle->regs = (volatile timer_reg_map_t *)TIMER_BASE_ADDR;
}