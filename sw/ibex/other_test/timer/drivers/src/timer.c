#include "timer.h"

static uint32_t timer_ctrl_reg_shadow = 0;

volatile timer_reg_map_t *timer_init() {
  // Initialize clean Timer.
  volatile timer_reg_map_t *const t =
      (volatile timer_reg_map_t *)TIMER_BASE_ADDR;
  // Clear all previous states of the Timer's Control register.
  timer_ctrl_reg_shadow = 0;
  t->CTRL = timer_ctrl_reg_shadow;
  t->MOD = 0x0;

  return t;
}

void timer_ack_intrq(volatile timer_reg_map_t *const t) {
  // Direct write to a flag bit.
  t->CTRL = TIMER_CTRL_FLAG;
}

void timer_clear_ctrl(volatile timer_reg_map_t *const t) {
  timer_ctrl_reg_shadow = 0;
  t->CTRL = timer_ctrl_reg_shadow;
}

void timer_set(volatile timer_reg_map_t *const t, const uint16_t mod,
               const uint8_t pre_scl) {
  // Clear the prescaler value and set to the new
  timer_ctrl_reg_shadow &= ~TIMER_CTRL_PRE_SCALR_MSK;
  timer_ctrl_reg_shadow |= TIMER_CTRL_PRE_SCALR(pre_scl);

  // Set Timer registers
  t->MOD = (uint32_t)mod;
  t->CTRL = timer_ctrl_reg_shadow;
}

void timer_en(volatile timer_reg_map_t *const t) {
  timer_ctrl_reg_shadow |= (TIMER_CTRL_CNT_EN | TIMER_CTRL_ENA_INT);
  t->CTRL = timer_ctrl_reg_shadow;
}