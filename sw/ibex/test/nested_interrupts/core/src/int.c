#include "int.h"

#define NESTED_IRQ_DECLARE_SAVE_STATUS_LOCALS \
  uint32_t mepc_bak;                          \
  uint32_t mstatus_bak;                       \
  uint32_t mie_bak;

// --- CRITICAL SECTION ENTRY ---
// 1. Save current return address.
// 2. Save current status.
// 3. Save current interrupt filter (interrupt enable).
// 4. Re-enable global interrupts (set MSTATUS 3rd bit).
#define NESTED_IRQ_CRITICAL_SECTION_ENTRY()                   \
  do {                                                        \
    __asm__ volatile("csrr %0, mepc" : "=r"(mepc_bak));       \
    __asm__ volatile("csrr %0, mstatus" : "=r"(mstatus_bak)); \
    __asm__ volatile("csrr %0, mie" : "=r"(mie_bak));         \
    __asm__ volatile("csrsi mstatus, 0x8");                   \
  } while (0)

// --- CRITICAL SECTION EXIT ---
// 1. Disable global interrupts.
// 2. Restore original global interrupt filter.
// 3. Restore original status.
// 4. Restore original return address.
#define NESTED_IRQ_CRITICAL_SECTION_EXIT()                   \
  do {                                                       \
    __asm__ volatile("csrci mstatus, 0x8");                  \
    __asm__ volatile("csrw mie, %0" ::"r"(mie_bak));         \
    __asm__ volatile("csrw mstatus, %0" ::"r"(mstatus_bak)); \
    __asm__ volatile("csrw mepc, %0" ::"r"(mepc_bak));       \
  } while (0)

void TIMER_IRQHandler(void) __attribute__((interrupt));

void TIMER_IRQHandler(void) {
#if TIMER_IRQ_HANDLER == 1
  timer_handle *timer_handle_ptr = &g_timer_handle;
  TIMER_ACK_INT_AND_DISABLE_IRQ(timer_handle_ptr);
#if NESTED_IRQ == 1
  NESTED_IRQ_DECLARE_SAVE_STATUS_LOCALS;
  NESTED_IRQ_CRITICAL_SECTION_ENTRY();
#endif
  timer_irq_handler(&g_timer_handle);
#if NESTED_IRQ == 1
  NESTED_IRQ_CRITICAL_SECTION_EXIT();
#endif
#else
  while(1);
#endif
}

void GPIO_IRQHandler(void) __attribute__((interrupt));

void GPIO_IRQHandler(void) {
#if GPIO_IRQ_HANDLER == 1
  gpio_handle *gpio_handle_ptr = &g_gpio_handle;
  GPIO_ACK_INT_AND_SAVE_INTS(gpio_handle_ptr);
#if NESTED_IRQ == 1
  NESTED_IRQ_DECLARE_SAVE_STATUS_LOCALS;
  NESTED_IRQ_CRITICAL_SECTION_ENTRY();
#endif
  gpio_irq_handler(&g_gpio_handle);
#if NESTED_IRQ == 1
  NESTED_IRQ_CRITICAL_SECTION_EXIT();
#endif
#else
  while(1);
#endif
}

void I2C_IRQHandler(void) __attribute__((interrupt));

void I2C_IRQHandler(void) {
#if I2C_IRQ_HANDLER == 1
  i2c_handle *i2c_handle_ptr = &g_i2c_handle;
  I2C_ACK_INT(i2c_handle_ptr);
#if NESTED_IRQ == 1
  NESTED_IRQ_DECLARE_SAVE_STATUS_LOCALS;
  NESTED_IRQ_CRITICAL_SECTION_ENTRY();
#endif
  i2c_irq_handler(&g_i2c_handle);
#if NESTED_IRQ == 1
#endif
  NESTED_IRQ_CRITICAL_SECTION_EXIT();
#else
  while (1);
#endif
}

// Unused.

void DEFAULT_IRQHandler(void) { while (1); }

void UART_RX_HALF_FULL_IRQHandler(void) __attribute__((interrupt));

void UART_RX_HALF_FULL_IRQHandler(void) { while (1); }

void UART_TX_HALF_EMPTY_IRQHandler(void) __attribute__((interrupt));

void UART_TX_HALF_EMPTY_IRQHandler(void) { while (1); }

void UART_RX_NOT_EMPTY_IRQHandler(void) __attribute__((interrupt));

void UART_RX_NOT_EMPTY_IRQHandler(void) { while (1); }

void UART_TX_NOT_FULL_IRQHandler(void) __attribute__((interrupt));

void UART_TX_NOT_FULL_IRQHandler(void) { while (1); }