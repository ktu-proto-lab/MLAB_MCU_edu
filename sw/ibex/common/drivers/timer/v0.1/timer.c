/**
 * @file timer.c
 * @author Manfredas Lamsargis (manfredas.lamsargis@ktu.edu)
 * @version 0.1
 * @date 2025-08-11
 */

#include "timer.h"

void timer_irq_handler(volatile timer_handle *timer_handle) { timer_handle->regs->CTRL = TIMER_CTRL_FLAG; }

void timer_handle_init(volatile timer_handle *timer_handle) {
  timer_handle->regs = (volatile timer_reg_map_t *)TIMER_BASE_ADDR;
}