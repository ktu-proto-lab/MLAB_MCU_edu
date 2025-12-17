/**
 * @file gpio.c
 * @author Dovydas Liutkus (dovydas.liutkus@ktu.edu)
 * @version 0.1
 * @date 2025-08-11
 */

#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>

/**
 * @brief Base memory address of the GPIO peripheral.
 */
#define GPIO_BASE_ADDR 0x40000000

/**
 * @brief Bit definitions
 */
/* ----- Control register                                          */

#define GPIO_CTRL_ENA_INT (1 << 0)     /* Interrupt enable bit:              */
                                       /*      1 - Interrupt enabled         */
                                       /*      0 - Interrupt disabled        */
#define GPIO_CTRL_GLOBAL_INTS (1 << 1) /* Interrupt status bit */
/*      1 - Interrupt is pending      */
/*      0 - No interrupt pending      */
/* Other bits in CR are reserved      */

/**
 * @brief  GPIO Bit SET and Bit RESET enumeration
 */
typedef enum { GPIO_PIN_RESET = 0, GPIO_PIN_SET } gpio_pin_state;

/**
 * @brief GPIO Peripheral register map
 */
typedef struct {
  volatile uint32_t IN;     // Input data
  volatile uint32_t OUT;    // Output data
  volatile uint32_t OE;     // Output enable
  volatile uint32_t INTE;   // Interrupt enable
  volatile uint32_t PTRIG;  // Interrupt trigger edge ( 0 - negedge, 1 - posedge)
  volatile uint32_t AUX;    // Multiplex auxiliary inputs to GPIO ( 0 - driven by
                            // OUT, 1- driven by aux
  volatile uint32_t CTRL;   // Control register
  volatile uint32_t INTS;   // Interrupt status
} gpio_reg_map_t;
/**
 * @brief GPIO Handle
 */
typedef struct {
  volatile gpio_reg_map_t *regs;  // GPIO registers
  uint32_t ints;                  // Interrupt status
} gpio_handle;

/**
 * @brief  GPIO Bit SET and Bit RESET enumeration
 */
#define GPIO_PIN_0 ((uint32_t)0x0001)  /* Pin 0 selected    */
#define GPIO_PIN_1 ((uint32_t)0x0002)  /* Pin 1 selected    */
#define GPIO_PIN_2 ((uint32_t)0x0004)  /* Pin 2 selected    */
#define GPIO_PIN_3 ((uint32_t)0x0008)  /* Pin 3 selected    */
#define GPIO_PIN_4 ((uint32_t)0x0010)  /* Pin 4 selected    */
#define GPIO_PIN_5 ((uint32_t)0x0020)  /* Pin 5 selected    */
#define GPIO_PIN_6 ((uint32_t)0x0040)  /* Pin 6 selected    */
#define GPIO_PIN_7 ((uint32_t)0x0080)  /* Pin 7 selected    */
#define GPIO_PIN_8 ((uint32_t)0x0100)  /* Pin 8 selected    */
#define GPIO_PIN_9 ((uint32_t)0x0200)  /* Pin 9 selected    */
#define GPIO_PIN_10 ((uint32_t)0x0400) /* Pin 10 selected    */
#define GPIO_PIN_11 ((uint32_t)0x0800) /* Pin 11 selected    */

/**
 * @brief Acknowledge interrupt and save interrupt status of the `INTS` register in `gpio_hande.ints` struct.
 */
#define GPIO_ACK_INT_AND_SAVE_INTS(gpio)  \
do {                                      \
  gpio->ints = gpio->regs->INTS;          \
  gpio->regs->INTS = 0;                   \
} while (0)

void gpio_handle_init(gpio_handle *gpio);
void gpio_write_pin(gpio_handle *gpio, uint32_t gpio_pin, gpio_pin_state state);
void gpio_toggle(gpio_handle *gpio, uint32_t gpio_pin);
void gpio_irq_handler(gpio_handle *gpio);
void gpio_irq_handler_callback(gpio_handle *gpio) __attribute__((weak));

#endif  // TIMER_H