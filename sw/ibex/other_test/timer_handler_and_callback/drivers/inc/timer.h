#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

//=============================================================================
// TIMER (PIT peripheral module)
//=============================================================================

/**
 * @brief Base memory address of the PIT peripheral.
 */
#define TIMER_BASE_ADDR 0x20000000

/**
 * @brief Acknowledge Timer interrupt
 */
#define TIMER_ACK_INT *((uint32_t *)TIMER_BASE_ADDR) = TIMER_CTRL_FLAG

//=============================================================================
// Timer struct
//=============================================================================

/**
 * @brief Memory-mapped register layout for the 16-bit Timer.
 */
typedef struct {
  /**
   * @brief Control Register, Offset: +0x00.
   * @note 16-bit register.
   */
  volatile uint32_t CTRL;

  /**
   * @brief Modulo Register, Offset: +0x04.
   * @note 16-bit register.
   */
  volatile uint32_t MOD;

  /**
   * @brief Counter Value Register (Read-Only), Offset: +0x08.
   * @note 16-bit register.
   */
  volatile uint32_t CNT;

  /**
   * @brief Reserved Register for alignment purposes.
   * @note Do not use it.
   */
  const volatile uint32_t RESERVED;
} timer_reg_map_t;

//=============================================================================
// Timer Handler
//=============================================================================
typedef struct {
  volatile timer_reg_map_t *regs;
} timer_handle;

//=============================================================================
// Timer Hanlder methods
//=============================================================================

/**
 * @brief Initializes Timer Handle.
 *
 * @param timer_handle Timer Handle struct.
 */
void timer_handle_init(volatile timer_handle *timer_handle);

/**
 * @brief Driver handle, enabled by the TIMER_IRQ_HANDLER = 1 in main.h.
 *
 * Clears Timer Interrupt Request to Core flag.
 */
void timer_irq_handler(volatile timer_handle *timer_handle)

//=============================================================================
// Control Register (CTRL) Bit Definitions
//=============================================================================

// --- Single Bit Definitions ---

#define TIMER_CTRL_CNT_EN_POS (0)

/**
 * @brief CNT_EN: Main Counter enable.
 * @note Write-Only. Setting this bit resets and starts the counter.
 */
#define TIMER_CTRL_CNT_EN (1U << TIMER_CTRL_CNT_EN_POS)

#define TIMER_CTRL_ENA_INT_POS (1)

/**
 * @brief ENA_INT: Interrupt enable.
 * @note Write-Only. Enables the interrupt output signal to Core.
 */
#define TIMER_CTRL_ENA_INT (1U << TIMER_CTRL_ENA_INT_POS)

#define TIMER_CTRL_FLAG_POS (2)

/**
 * @brief FLAG: Main counter rollover status flag.
 * @note Write-Only. Writing '1' to this bit clears the flag and releases
 * Interrupt Request signal to Core.
 */
#define TIMER_CTRL_FLAG (1U << TIMER_CTRL_FLAG_POS)

#define TIMER_CTRL_SLAVE_POS (15)

/**
 * @brief SLAVE: Slave mode enable bit.
 * @note Read-Write.
 */
#define TIMER_CTRL_SLAVE_Msk (1U << TIMER_CTRL_SLAVE_POS)

// --- Multi-Bit Field Definitions ---

#define TIMER_CTRL_PRE_SCALR_POS (8)
#define TIMER_CTRL_PRE_SCALR_MSK (0xFUL << TIMER_CTRL_PRE_SCALR_POS)

/**
 * @brief PRE_SCALR: Prescale Counter modulo value.
 * @param value 4-bit value for the prescaler. Min: `0x0U` Max: `0xFU`
 * @note Read-Write. Sets the divisor for the system clock.
 */
#define TIMER_CTRL_PRE_SCALR(value) (((value) & 0xFU) << TIMER_CTRL_PRE_SCALR_POS)

#endif  // TIMER_H