#include "main.h"

#include "int.h"

volatile timer_handle g_timer_handle;

int main() {
  timer_handle_init(&g_timer_handle);
  g_timer_handle.regs->MOD = 0x20U;
  g_timer_handle.regs->CTRL = TIMER_CTRL_PRE_SCALR(0x2U) | TIMER_CTRL_CNT_EN | TIMER_CTRL_ENA_INT;
  while (1);
  return 0;
}

void timer_irq_callback(volatile timer_handle *timer_handle) {
  timer_handle->regs->MOD = 0xFFFFU;
  timer_handle->regs->CTRL = TIMER_CTRL_PRE_SCALR(0xFU) | TIMER_CTRL_CNT_EN | TIMER_CTRL_ENA_INT;
}