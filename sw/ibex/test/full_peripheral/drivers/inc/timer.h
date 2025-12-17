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
// Timer struct's methods
//=============================================================================

/**
 * @brief Initializes the timer hardware and the driver state.
 * @return A pointer to the timer's memory-mapped registers.
 * @note This function actively modifies the hardware by writing `0` to the
 *       `CTRL` and `MOD` registers, stopping the timer and clearing its
 * settings.
 */
volatile timer_reg_map_t *timer_init();

/**
 * @brief Acknowledges a Timer Interrupt request by clearing the `FLAG` status
 * bit and the interrupt output.
 * @param t A pointer to the timer instance.
 * @note
 * @warning This function MUST be followed by calls to `timer_set()` and
 * `timer_en()` to restart the timer for the next interval.
 */
void timer_ack_intrq(volatile timer_reg_map_t *const t);

/**
 * @brief Clears the Timer's Control Register (`CTRL`) and it's state.
 * This function stops the timer and resets its configuration to defaults.
 */
void timer_clear_ctrl(volatile timer_reg_map_t *const t);

/**
 * @brief Configures the timer's period `MOD` and clock prescaler `PRE_SCALR`.
 * @param t       A pointer to the timer instance.
 * @param mod     The main counter's rollover value `MOD` (16-bit).
 * @param pre_scl The clock prescaler value `PRE_SCALR` (4-bit).
 * @warning This function does not modify other `CTRL` register bits.
 * @note This function should typically be followed by a call to `timer_en()`
 *       to start the timer with the new configuration.
 */
void timer_set(volatile timer_reg_map_t *const t, const uint16_t mod,
               const uint8_t pre_scl);

/**
 * @brief Enables `CTRL.CNT_EN` bit to start countdown and enables
 * `CTRL.ENA_INT` bit to output Interrupt Request signal to Core when the
 * counting is done.
 * @param t A pointer to the timer instance.
 * @note This function preserves the existing prescaler setting from the last
 *       call to `timer_set()` and then sets the enable bits.
 */
void timer_en(volatile timer_reg_map_t *const t);

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
#define TIMER_CTRL_PRE_SCALR(value) \
  (((value) & 0xFU) << TIMER_CTRL_PRE_SCALR_POS)

//=============================================================================
// Interrupt
//=============================================================================

/**
 * @brief Timer interrupt handler.
 */
void timer_int_handler(void) __attribute__((interrupt));

#endif  // TIMER_H