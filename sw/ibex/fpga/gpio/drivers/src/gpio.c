/**
 * @file gpio.c
 * @author Dovydas Liutkus (dovydas.liutkus@ktu.edu)
 * @version 0.1
 * @date 2025-08-11
 */

#include "gpio.h"

void GPIO_Init(GPIO_HandleTypeDef *gpio) {
  // Initialize register pointer to GPIO peripheral
  gpio->regs = (volatile GPIO_reg_map_t *)GPIO_BASE_ADDR;
}

/**
 * @brief  Sets or clears the selected data port bit.
 *
 * @param  GPIO_Pin specifies the port bit to be written.
 *         This parameter can be any combination of GPIO_PIN_x where x can be (0..11).
 * @param  PinState specifies the value to be written to the selected bit.GPIO_PinState
 *          This parameter can be one of the GPIO_PinState enum values:
 *            @arg GPIO_PIN_RESET: to clear the port pin
 *            @arg GPIO_PIN_SET: to set the port pin
 * @retval None
 */
void GPIO_WritePin(GPIO_HandleTypeDef *gpio, uint32_t GPIO_Pin, GPIO_PinState PinState) {
  if (PinState != GPIO_PIN_RESET) {
    gpio->regs->OUT |= GPIO_Pin;
  } else {
    gpio->regs->OUT &= ~GPIO_Pin;
  }
}
/**
 * @brief  Toggles the specified GPIO pins.
 * @param  GPIO_Pin Specifies the pins to be toggled.
 *         This parameter can be any combination of GPIO_PIN_x where x can be (0..11).
 * @retval None
 */
void GPIO_Toggle(GPIO_HandleTypeDef *gpio, uint32_t GPIO_Pin) {
  // XOR to toggle
  gpio->regs->OUT ^= GPIO_Pin;
}

void gpio_irq_handler(GPIO_HandleTypeDef *gpio) {
  // Record interrupt in handle and clear INTS register
  gpio->Interrupt_Status = gpio->regs->INTS;
  gpio->regs->INTS = 0;
  // Callback for User
  // GPIO_EXTI_Callback(gpio);
}
