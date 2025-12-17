#ifndef UART_H
#define UART_h

#include <stdint.h>

/**
 * @brief Base memory address of the UART peripheral.
 */

#define UART_BASE_ADDR 0x50000000

#define UART_SETUP_BAUD_MASK 0xFFFFFF
#define UART_BAUD_INTERVAL(CPU_Freq, UART_Baudrate) (CPU_Freq * 1000000) / (UART_Baudrate);


/**
 * @brief UART peripheral register map.
 */

typedef struct {
  volatile uint32_t SETUP;   /* UART configuration / setup register     */
  volatile uint32_t FIFO;    /* Returns size and status of FIFOs        */
  volatile uint32_t RX_DATA; /* Read data, reads from the UART          */
  volatile uint32_t TX_DATA; /* Transmit data: writes send out the UART */
  volatile uint32_t RX_ENABLE;
} UART_reg_map_t;


/**
 * @brief UART peripheral configuration.
 */

typedef struct {
  uint32_t BaudRate;
  uint32_t WordLength;
  uint32_t StopBits;
  uint32_t Parity;
  uint32_t ParityMode;
  uint32_t ParityLock;		// determins if parity is fixed or not
  uint32_t HwFlowCtrl;
} UART_InitTypeDef;

/**
 * @brief UART TX transfer data
 *

typedef struct {
    uint8_t *pTxBuffPtr;
    uint16_t TxXferSize;
    volatile uint16_t TxXferCount;
} UART_IntTxTypeDef

/**
 * @brief UART RX transfer data
 *

typedef struct {
    uint8_t *pRxBuffPtr;
    uint16_t RxXferSize;
    volatile uint16_t RxXferCount;
} UART_IntRxTypeDef

/**
 * @brief UART States
 */

typedef enum
{
  UART_STATE_RESET             = 0x00U,    /*!< Peripheral is not yet Initialized
                                                   Value is allowed for gState and RxState */

  UART_STATE_READY             = 0x20U,    /*!< Peripheral Initialized and ready for use
                                                   Value is allowed for gState and RxState */

  UART_STATE_BUSY              = 0x24U,    /*!< an internal process is ongoing
                                                   Value is allowed for gState only */

  UART_STATE_BUSY_TX           = 0x21U,    /*!< Data Transmission process is ongoing
                                                   Value is allowed for gState only */

  UART_STATE_BUSY_RX           = 0x22U,    /*!< Data Reception process is ongoing
                                                   Value is allowed for RxState only */

  UART_STATE_BUSY_TX_RX        = 0x23U,    /*!< Data Transmission and Reception process is ongoing
                                                   Not to be used for neither gState nor RxState.
                                                   Value is result of combination (Or) between gState and RxState values */

  UART_STATE_TIMEOUT           = 0xA0U,    /*!< Timeout state
                                                   Value is allowed for gState only */

  UART_STATE_ERROR             = 0xE0U     /*!< Error
                                                   Value is allowed for gState only */
} UART_StateTypeDef;

/**
 * @brief UART peripheral handle
 */

typedef struct {

    volatile UART_reg_map_t *Instance;      /*!< UART registers base address     */ 

    UART_InitTypeDef Init;                  /*!< UART communication parameters   */

    uint8_t *pTxBuffPtr;                 /*!< Pointer to UART Tx transfer Buffer */

    uint16_t TxXferSize;                    /*!< UART Tx Transfer size           */

    volatile uint16_t TxXferCount;          /*!< UART Tx Transfer Counter        */

    uint8_t *pRxBuffPtr;                 /*!< Pointer to UART Rx transfer Buffer */

    uint16_t RxXferSize;                    /*!< UART Rx Transfer size           */

    volatile uint16_t RxXferCount;          /*!< UART Rx Transfer Counter        */

    volatile UART_StateTypeDef gState;      /*!< UART state information related to
                                                 global Handle management and also
                                                 related to Tx operations. This
                                                 parameter can be a value of
                                                 @ref HAL_UART_StateTypeDef      */

    volatile UART_StateTypeDef RxState;     /*!< UART state information related to
                                                 Rx operations. This parameter can
                                                 be a value of @ref
                                                 HAL_UART_StateTypeDef           */
} UART_HandleTypeDef;

/**
 * @brief Initialize UART peripheral with specified settings defined in huart.Init struct
 */

void UART_Init(UART_HandleTypeDef *huart);

/**
 * @brief Blocking UART transmit
 */

void UART_Transmit(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size);

/**
 * @brief Blocking UART receive
 */

void UART_Receive(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size);

/**
 * @brief Non-Blocking UART transmit
 */

void UART_Transmit_IT(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size);

/**
 * @brief Non-Blocking UART receive
 */

void UART_Receive_IT(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size);

/**
 * @brief RX FIFO half-full interrupt handler
 */

void UART_RX_Half_Full_IRQHandler(UART_HandleTypeDef *huart);

/**
 * @brief RX FIFO not-empty interrupt handler
 */

void UART_RX_Not_Empty_IRQHandler(UART_HandleTypeDef *huart);

/**
 * @brief TX FIFO half-empty interrupt handler
 */

void UART_TX_Half_Empty_IRQHandler(UART_HandleTypeDef *huart);

/**
 * @brief TX FIFO not-full interrupt handler
 */

void UART_TX_Not_Full_IRQHandler(UART_HandleTypeDef *huart);

/**
 * @brief UART_Receive_IT complete callback
 */

void UART_RXCpltCallback(UART_HandleTypeDef *huart);

/**
 * @brief UART_Transmit_IT complete callback
 */

void UART_TXCpltCallback(UART_HandleTypeDef *huart);

#endif
