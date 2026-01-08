#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>

/**
 * @brief Bit definitions
 */
/* ----- Control register                                             */

#define ENABLE_INT (1 << 0)  /* Interrupt enable bit:              */
                             /*      1 - Interrupt enabled         */
                             /*      0 - Interrupt disabled        */
#define GLOBAL_INTS (1 << 1) /* Interrupt status bit               */
                             /*      1 - Interrupt is pending      */
                             /*      0 - No interrupt pending      */
                             /* Other bits in CR are reserved      */
/**
 * @brief Interrupt enable bit:
 * `1` - enable;
 * `0` - disable;
 */
#define GPIO_CTRL_ENABLE_INT (1 << 0)

/**
 * @brief Base memory address of the GPIO peripheral.
 */
#define GPIO_BASE_ADDR 0x40000000

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
} GPIO_reg_map_t;

// volatile GPIO_reg_map_t *const GPIO_init() {
//   return (volatile GPIO_reg_map_t *const)GPIO_BASE_ADDR;
// }

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

void gpio_handler();
volatile GPIO_reg_map_t *const GPIO_init();

#endif  // TIMER_H
