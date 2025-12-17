/**
 * @file gpio.c
 * @author Dovydas Liutkus (dovydas.liutkus@ktu.edu)
 * @version 0.1
 * @date 2025-08-11
 */

#include "gpio.h"

void gpio_handle_init(volatile gpio_handle *gpio) {
  gpio->regs = (volatile gpio_reg_map_t *)GPIO_BASE_ADDR;
  gpio->ints = 0;
}

void gpio_write_pin(volatile gpio_handle *gpio, uint32_t gpio_pin, gpio_pin_state state) {
  if (state != GPIO_PIN_RESET) {
    gpio->regs->OUT |= gpio_pin;
  } else {
    gpio->regs->OUT &= ~gpio_pin;
  }
}

void gpio_toggle(volatile gpio_handle *gpio, uint32_t gpio_pin) {
  // XOR to toggle
  gpio->regs->OUT ^= gpio_pin;
}

void gpio_irq_handler(volatile gpio_handle *gpio) { gpio_irq_handler_callback(gpio); }

__attribute__((weak)) void gpio_irq_handler_callback(volatile gpio_handle *gpio) { return; }