#ifndef I2C_MASTER_H
#define I2C_MASTER_H

#include <stdint.h>

#define I2C_BASE_ADDR 0x30000000
// #define I2C_SPEED 400  // kHz

/* ----- Bits definition                                              */

/* ----- Control register                                             */

#define I2C_EN (1 << 7)  /* Core enable bit:                   */
                            /*      1 - core is enabled           */
                            /*      0 - core is disabled          */
#define I2C_IEN (1 << 6) /* Interrupt enable bit               */
                            /*      1 - Interrupt enabled         */
                            /*      0 - Interrupt disabled        */
                            /* Other bits in CR are reserved      */

/* ----- Command register bits                                        */

#define I2C_CSR_STA (1 << 7)  /* Generate (repeated) start condition*/
#define I2C_CSR_STO (1 << 6)  /* Generate stop condition            */
#define I2C_CSR_RD (1 << 5)   /* Read from slave                    */
#define I2C_CSR_WR (1 << 4)   /* Write to slave                     */
#define I2C_CSR_ACK (1 << 3)  /* Acknowledge from slave             */
                             /*      1 - ACK                       */
                             /*      0 - NACK                      */
#define I2C_CSR_IACK (1 << 0) /* Interrupt acknowledge              */

/* ----- Status register bits                                         */

#define I2C_CSR_RXACK (1 << 7) /* ACK received from slave            */
                              /*      1 - ACK                       */
                              /*      0 - NACK                      */
#define I2C_CSR_BUSY (1 << 6)  /* Busy bit                           */
#define I2C_CSR_TIP (1 << 1)   /* Transfer in progress               */
#define I2C_CSR_IF (1 << 0)    /* Interrupt flag                     */

/* bit testing and setting macros                                     */

#define ISSET(reg, bitmask) ((reg) & (bitmask))
#define ISCLEAR(reg, bitmask) (!(ISSET(reg, bitmask)))
#define BITSET(reg, bitmask) ((reg) | (bitmask))
#define BITCLEAR(reg, bitmask) ((reg) | (~(bitmask)))
#define BITTOGGLE(reg, bitmask) ((reg) ^ (bitmask))
#define REGMOVE(reg, value) ((reg) = (value))

#define I2C_WAIT_BUSY(reg) while (ISSET(reg->regs->CSR, I2C_CSR_BUSY))
#define I2C_WAIT_TIP(reg) while (ISSET(reg->regs->CSR, I2C_CSR_TIP))

#define I2C_ENABLE(reg) reg->regs->CTR = I2C_EN
#define I2C_DISABLE(reg) reg->regs->CTR = 0x00

#define I2C_ENABLE_INT(reg) reg->regs->CTR |= I2C_IEN
#define I2C_DISABLE_INT(reg) reg->regs->CTR &= ~I2C_IEN

#define I2C_PRESCALE(CPU_Freq, I2C_Freq) (CPU_Freq * 200) / (I2C_Freq) - 1;
#define I2C_CSR_ACK_RECEIVED(reg) ISCLEAR(reg->regs->CSR, I2C_CSR_RXACK)

typedef enum {
  I2C_CSR_STATE_READY,
  I2C_CSR_STATE_BUSY,
  I2C_CSR_STATE_BUSY_TX_IT,
  I2C_CSR_STATE_BUSY_RX_IT
} I2C_CSR_STAtes_t;

typedef enum {
  I2C_CSR_STATE_TX_IT_READY,
  I2C_CSR_STATE_TX_IT_ADDRESS,
  I2C_CSR_STATE_TX_IT_DATA,
  I2C_CSR_STATE_TX_IT_END
} i2c_int_tx_state_t;

typedef enum {
  I2C_CSR_STATE_RX_IT_READY,
  I2C_CSR_STATE_RX_IT_ADDRESS,
  I2C_CSR_STATE_RX_IT_DATA,
  I2C_CSR_STATE_RX_IT_GET_DATA,
  I2C_CSR_STATE_RX_IT_END
} i2c_int_rx_state_t;

typedef struct {
  volatile uint32_t PRER_LO; /* Low byte clock prescaler register  */
  volatile uint32_t PRER_HI; /* High byte clock prescaler register */
  volatile uint32_t CTR;     /* Control register                   */
  volatile uint32_t TRXR;    /* Transmit/Receive byte register     */
  volatile uint32_t CSR;     /* Command/Status register            */
} i2c_reg_map_t;

typedef struct {
  i2c_int_tx_state_t State;
  uint8_t Address;
  uint8_t *Data;
  uint16_t Size;
} i2c_int_tx_t;

typedef struct {
  i2c_int_rx_state_t State;
  uint8_t Address;
  uint8_t *Data;
  uint16_t Size;
} i2c_int_rx_t;

typedef struct {
  volatile i2c_reg_map_t *regs;
  i2c_int_tx_t Interupt_Transmit;
  i2c_int_rx_t Interupt_Receive;
  I2C_CSR_STAtes_t State;
} i2c_handle;

void i2c_handle_init(i2c_handle *i2c, uint32_t BaseAddress, uint16_t Speed, uint8_t CPUFreq);
void i2c_master_tx(i2c_handle *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void i2c_master_rx(i2c_handle *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void i2c_master_tx_it(i2c_handle *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void i2c_master_rx_it(i2c_handle *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void i2c_irq_handler(i2c_handle *i2c);

/**
 * @brief I2C non-blocking receive is done.
 *
 * @param i2c pointer to I2C master handler.
 * @note This function Should not be modified, when the callback is needed,
 * the `i2c_master_rx_cplt_callback` could be implemented in the user file.
 */
void i2c_master_rx_cplt_callback(i2c_handle *i2c) __attribute__((weak));

/**
 * @brief I2C non-blocking transmit is done.
 *
 * @param i2c pointer to I2C master handler.
 * @note This function should not be modified, when the callback is needed, the
 * `i2c_master_tx_cplt_callback` could be implemented in the user file.
 */
void i2c_master_tx_cplt_callback(i2c_handle *i2c) __attribute__((weak));

#define I2C_ACK_INT(i2c) (i2c->regs->CSR = I2C_CSR_IACK)

#endif
