#ifndef OC_I2C_MASTER_H
#define OC_I2C_MASTER_H

#include <stdint.h>

#define I2C_BASE_ADDR 0x30000000
#define I2C_SPEED 400  // kHz

/* ----- Bits definition                                              */

/* ----- Control register                                             */

#define OC_I2C_EN (1 << 7)  /* Core enable bit:                   */
                            /*      1 - core is enabled           */
                            /*      0 - core is disabled          */
#define OC_I2C_IEN (1 << 6) /* Interrupt enable bit               */
                            /*      1 - Interrupt enabled         */
                            /*      0 - Interrupt disabled        */
                            /* Other bits in CR are reserved      */

/* ----- Command register bits                                        */

#define OC_I2C_STA (1 << 7)  /* Generate (repeated) start condition*/
#define OC_I2C_STO (1 << 6)  /* Generate stop condition            */
#define OC_I2C_RD (1 << 5)   /* Read from slave                    */
#define OC_I2C_WR (1 << 4)   /* Write to slave                     */
#define OC_I2C_ACK (1 << 3)  /* Acknowledge from slave             */
                             /*      1 - ACK                       */
                             /*      0 - NACK                      */
#define OC_I2C_IACK (1 << 0) /* Interrupt acknowledge              */

/* ----- Status register bits                                         */

#define OC_I2C_RXACK (1 << 7) /* ACK received from slave            */
                              /*      1 - ACK                       */
                              /*      0 - NACK                      */
#define OC_I2C_BUSY (1 << 6)  /* Busy bit                           */
#define OC_I2C_TIP (1 << 1)   /* Transfer in progress               */
#define OC_I2C_IF (1 << 0)    /* Interrupt flag                     */

/* bit testing and setting macros                                     */

#define OC_ISSET(reg, bitmask) ((reg) & (bitmask))
#define OC_ISCLEAR(reg, bitmask) (!(OC_ISSET(reg, bitmask)))
#define OC_BITSET(reg, bitmask) ((reg) | (bitmask))
#define OC_BITCLEAR(reg, bitmask) ((reg) | (~(bitmask)))
#define OC_BITTOGGLE(reg, bitmask) ((reg) ^ (bitmask))
#define OC_REGMOVE(reg, value) ((reg) = (value))

#define OC_I2C_WAIT_BUSY(reg) while (OC_ISSET(reg->regs->CSR, OC_I2C_BUSY))
#define OC_I2C_WAIT_TIP(reg) while (OC_ISSET(reg->regs->CSR, OC_I2C_TIP))

#define OC_I2C_ENABLE(reg) reg->regs->CTR = OC_I2C_EN
#define OC_I2C_DISABLE(reg) reg->regs->CTR = 0x00

#define OC_I2C_ENABLE_INT(reg) reg->regs->CTR |= OC_I2C_IEN
#define OC_I2C_DISABLE_INT(reg) reg->regs->CTR &= ~OC_I2C_IEN

#define OC_I2C_PRESCALE(CPU_Freq, I2C_Freq) (CPU_Freq * 200) / (I2C_Freq) - 1;
#define OC_I2C_ACK_RECEIVED(reg) OC_ISCLEAR(reg->regs->CSR, OC_I2C_RXACK)

typedef enum {
  OC_I2C_STATE_READY,
  OC_I2C_STATE_BUSY,
  OC_I2C_STATE_BUSY_TX_IT,
  OC_I2C_STATE_BUSY_RX_IT
} OC_I2C_States_t;

typedef enum {
  OC_I2C_STATE_TX_IT_READY,
  OC_I2C_STATE_TX_IT_ADDRESS,
  OC_I2C_STATE_TX_IT_DATA,
  OC_I2C_STATE_TX_IT_END
} OC_I2C_Interupt_Transmit_States_t;

typedef enum {
  OC_I2C_STATE_RX_IT_READY,
  OC_I2C_STATE_RX_IT_ADDRESS,
  OC_I2C_STATE_RX_IT_DATA,
  OC_I2C_STATE_RX_IT_GET_DATA,
  OC_I2C_STATE_RX_IT_END
} OC_I2C_Interupt_Receive_States_t;

typedef struct {
  volatile uint32_t PRER_LO; /* Low byte clock prescaler register  */
  volatile uint32_t PRER_HI; /* High byte clock prescaler register */
  volatile uint32_t CTR;     /* Control register                   */
  volatile uint32_t TRXR;    /* Transmit/Receive byte register     */
  volatile uint32_t CSR;     /* Command/Status register            */
} OC_I2C_reg_map_t;

typedef struct {
  OC_I2C_Interupt_Transmit_States_t State;
  uint8_t Address;
  uint8_t *Data;
  uint16_t Size;
} OC_I2C_Interupt_Transmit_t;

typedef struct {
  OC_I2C_Interupt_Receive_States_t State;
  uint8_t Address;
  uint8_t *Data;
  uint16_t Size;
} OC_I2C_Interupt_Receive_t;

typedef struct {
  volatile OC_I2C_reg_map_t *regs;
  OC_I2C_Interupt_Transmit_t Interupt_Transmit;
  OC_I2C_Interupt_Receive_t Interupt_Receive;
  OC_I2C_States_t State;
} I2C_HandleTypeDef;

void OC_I2C_Init(I2C_HandleTypeDef *i2c, uint32_t BaseAddress, uint16_t Speed, uint8_t CPUFreq);
void OC_I2C_Master_Transmit(I2C_HandleTypeDef *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void OC_I2C_Master_Receive(I2C_HandleTypeDef *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void OC_I2C_Master_Transmit_IT(I2C_HandleTypeDef *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void OC_I2C_Master_Receive_IT(I2C_HandleTypeDef *i2c, uint8_t DevAddress, uint8_t *Data, uint16_t Size);
void OC_I2C_IRQHandler(I2C_HandleTypeDef *i2c);

/**
 * @brief I2C non-blocking receive is done.
 *
 * @param i2c pointer to I2C master handler.
 * @note This function Should not be modified, when the callback is needed,
 * the `OC_I2C_MasterRxCpltCallback` could be implemented in the user file.
 */
void OC_I2C_MasterRxCpltCallback(I2C_HandleTypeDef *i2c) __attribute__((weak));

/**
 * @brief I2C non-blocking transmit is done.
 *
 * @param i2c pointer to I2C master handler.
 * @note This function should not be modified, when the callback is needed, the
 * `OC_I2C_MasterTxCpltCallback` could be implemented in the user file.
 */
void OC_I2C_MasterTxCpltCallback(I2C_HandleTypeDef *i2c) __attribute__((weak));

#endif