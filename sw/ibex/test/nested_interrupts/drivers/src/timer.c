/**
 * @file timer.c
 * @author Manfredas Lamsargis (manfredas.lamsargis@ktu.edu)
 * @version 0.1
 * @date 2025-08-11
 */

#include "timer.h"

void timer_irq_handler(timer_handle *timer) {
  timer_irq_handler_callback(timer);
}

void timer_handle_init(timer_handle *timer) {
  timer->regs = (timer_reg_map_t *)TIMER_BASE_ADDR;
}