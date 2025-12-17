/**
 * @file i2c_master.c
 * @author Rokas Briedis (rokas.briedis@ktu.edu)
 * @version 0.1
 * @date 2025-08-13
 */

#ifndef I2C_MASTER_H
#define I2C_MASTER_H

#include <stdint.h>

// #define I2C_BASE_ADDR 0x30000000
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

#define I2C_STA (1 << 7)  /* Generate (repeated) start condition*/
#define I2C_STO (1 << 6)  /* Generate stop condition            */
#define I2C_RD (1 << 5)   /* Read from slave                    */
#define I2C_WR (1 << 4)   /* Write to slave                     */
#define I2C_ACK (1 << 3)  /* Acknowledge from slave             */
                             /*      1 - ACK                       */
                             /*      0 - NACK                      */
#define I2C_IACK (1 << 0) /* Interrupt acknowledge              */

/* ----- Status register bits                                         */

#define I2C_RXACK (1 << 7) /* ACK received from slave            */
                              /*      1 - ACK                       */
                              /*      0 - NACK                      */
#define I2C_BUSY (1 << 6)  /* Busy bit                           */
#define I2C_TIP (1 << 1)   /* Transfer in progress               */
#define I2C_IF (1 << 0)    /* Interrupt flag                     */

/* bit testing and setting macros                                     */

#define OC_ISSET(reg, bitmask) ((reg) & (bitmask))
#define OC_ISCLEAR(reg, bitmask) (!(OC_ISSET(reg, bitmask)))
#define OC_BITSET(reg, bitmask) ((reg) | (bitmask))
#define OC_BITCLEAR(reg, bitmask) ((reg) | (~(bitmask)))
#define OC_BITTOGGLE(reg, bitmask) ((reg) ^ (bitmask))
#define OC_REGMOVE(reg, value) ((reg) = (value))

#define I2C_WAIT_BUSY(reg) while (OC_ISSET(reg->regs->CSR, I2C_BUSY))
#define I2C_WAIT_TIP(reg) while (OC_ISSET(reg->regs->CSR, I2C_TIP))

#define I2C_ENABLE(reg) reg->regs->CTR = I2C_EN
#define I2C_DISABLE(reg) reg->regs->CTR = 0x00

#define I2C_ENABLE_INT(reg) reg->regs->CTR |= I2C_IEN
#define I2C_DISABLE_INT(reg) reg->regs->CTR &= ~I2C_IEN

#define I2C_PRESCALE(CPU_Freq, I2C_Freq) (CPU_Freq * 200) / (I2C_Freq) - 1;
#define I2C_ACK_RECEIVED(reg) OC_ISCLEAR(reg->regs->CSR, I2C_RXACK)

typedef enum {
  I2C_STATE_READY,
  I2C_STATE_BUSY,
  I2C_STATE_BUSY_TX_IT,
  I2C_STATE_BUSY_RX_IT
} I2C_States_t;

typedef enum {
  I2C_STATE_TX_IT_READY,
  I2C_STATE_TX_IT_ADDRESS,
  I2C_STATE_TX_IT_DATA,
  I2C_STATE_TX_IT_END
} I2C_Interupt_Transmit_States_t;

typedef enum {
  I2C_STATE_RX_IT_READY,
  I2C_STATE_RX_IT_ADDRESS,
  I2C_STATE_RX_IT_DATA,
  I2C_STATE_RX_IT_GET_DATA,
  I2C_STATE_RX_IT_END
} I2C_Interupt_Receive_States_t;

typedef struct {
  volatile uint32_t PRER_LO; /* Low byte clock prescaler register  */
  volatile uint32_t PRER_HI; /* High byte clock prescaler register */
  volatile uint32_t CTR;     /* Control register                   */
  volatile uint32_t TRXR;    /* Transmit/Receive byte register     */
  volatile uint32_t CSR;     /* Command/Status register            */
} I2C_reg_map_t;

typedef struct {
  I2C_Interupt_Transmit_States_t State;
  uint8_t Address;
  uint8_t *Data;
  uint16_t Size;
} I2C_Interupt_Transmit_t;

typedef struct {
  I2C_Interupt_Receive_States_t State;
  uint8_t Address;
  uint8_t *Data;
  uint16_t Size;
} I2C_Interupt_Receive_t;

typedef struct {
  volatile I2C_reg_map_t *regs;
  I2C_Interupt_Transmit_t Interupt_Transmit;
  I2C_Interupt_Receive_t Interupt_Receive;
  I2C_States_t State;
} I2C_HandleTypeDef;

void I2C_Init(I2C_HandleTypeDef *i2c, uint32_t BaseAddress, uint16_t Speed,
                 uint8_t CPUFreq);
void I2C_Master_Transmit(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                            uint8_t *Data, uint16_t Size);
void I2C_Master_Receive(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                           uint8_t *Data, uint16_t Size);
void I2C_Master_Transmit_IT(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                               uint8_t *Data, uint16_t Size);
void I2C_Master_Receive_IT(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                              uint8_t *Data, uint16_t Size);
void I2C_IRQ_Handler(I2C_HandleTypeDef *i2c);

/**
 * @brief I2C non-blocking receive is done.
 *
 * @param i2c pointer to I2C master handler.
 * @note This function Should not be modified, when the callback is needed,
 * the `OC_I2C_MasterRxCpltCallback` could be implemented in the user file.
 */
void I2C_MasterRxCpltCallback(I2C_HandleTypeDef *i2c) __attribute__((weak));

/**
 * @brief I2C non-blocking transmit is done.
 *
 * @param i2c pointer to I2C master handler.
 * @note This function should not be modified, when the callback is needed, the
 * `OC_I2C_MasterTxCpltCallback` could be implemented in the user file.
 */
void I2C_MasterTxCpltCallback(I2C_HandleTypeDef *i2c) __attribute__((weak));

#endif
