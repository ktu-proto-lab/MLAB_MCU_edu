#ifndef UART_H
#define UART_h

#include "uart.h"

#include <stdint.h>

/**
 * @brief Base memory address of the UART peripheral.
 */

#define UART_BASE_ADDR 0x50000000

/**
 * @brief UART peripheral register map.
 */

typedef struct {
  volatile uint32_t SETUP;
  volatile uint32_t FIFO;
  volatile uint32_t RX_DATA;
  volatile uint32_t TX_DATA;
} UART_reg_map_t;

/**
 * @brief UART peripheral configuration.
 */

typedef struct {
  volatile uint32_t BaudRate;
  volatile uint32_t WordLength;
  volatile uint32_t StopBits;
  volatile uint32_t Parity;
  volatile uint32_t ParityMode;
  volatile uint32_t ParityLock;		// determins if parity is fixed or not
  volatile uint32_t HwFlowCtrl;
} UART_InitTypeDef;

/**
 * @brief UART peripheral handle
 */

typedef struct {
  UART_reg_map_t *Instance;
  UART_InitTypeDef Init;
} UART_HandleTypeDef;

// Initialize UART peripheral with specified settings defined in huart.Init struct
void UART_Init(UART_HandleTypeDef *huart);

#endif
