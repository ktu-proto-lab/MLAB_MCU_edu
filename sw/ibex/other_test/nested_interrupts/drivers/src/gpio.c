/**
 * @file gpio.c
 * @author Dovydas Liutkus (dovydas.liutkus@ktu.edu)
 * @version 0.1
 * @date 2025-08-11
 */

#include "gpio.h"

void gpio_handle_init(gpio_handle *gpio) {
  // Initialize register pointer to GPIO peripheral
  gpio->regs = (volatile gpio_reg_map_t *)GPIO_BASE_ADDR;
  gpio->ints = 0;
}

/**
 * @brief  Sets or clears the selected data port bit.
 *
 * @param  gpio_pin specifies the port bit to be written.
 *         This parameter can be any combination of GPIO_PIN_x where x can be (0..11).
 * @param  state specifies the value to be written to the selected bit.gpio_pin_state
 *          This parameter can be one of the gpio_pin_state enum values:
 *            @arg GPIO_PIN_RESET: to clear the port pin
 *            @arg GPIO_PIN_SET: to set the port pin
 * @retval None
 */
void gpio_write_pin(gpio_handle *gpio, uint32_t gpio_pin, gpio_pin_state state) {
  if (state != GPIO_PIN_RESET) {
    gpio->regs->OUT |= gpio_pin;
  } else {
    gpio->regs->OUT &= ~gpio_pin;
  }
}
/**
 * @brief  Toggles the specified GPIO pins.
 * @param  gpio_pin Specifies the pins to be toggled.
 *         This parameter can be any combination of GPIO_PIN_x where x can be (0..11).
 * @retval None
 */
void gpio_toggle(gpio_handle *gpio, uint32_t gpio_pin) {
  // XOR to toggle
  gpio->regs->OUT ^= gpio_pin;
}

void gpio_irq_handler(gpio_handle *gpio) {
  gpio_irq_handler_callback(gpio);
}