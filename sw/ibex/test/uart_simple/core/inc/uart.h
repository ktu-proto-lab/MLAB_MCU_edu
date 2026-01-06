#ifndef UART_H
#define UART_h

#include <stdint.h>

/**
 * @brief Base memory address of the UART peripheral.
 */

#define UART_BASE_ADDR 0x50000000

#define UART_SETUP_BAUD_MASK 0xFFFFFF
#define UART_BAUD_INTERVAL(CPU_Freq, UART_Baudrate) (CPU_Freq * 1000000) / (UART_Baudrate);

/* ----- Bits definition                                                  */

/* ----- Setup register                                                   */

#define UART_N (1 << 28)    /*Indicates the number of data bits per word.
                              This will either be 2'b00 for an 8-bit word,
                              2'b01 for a 7-bit word, 2'b10 for a six bit
                              word, or 2'b11 for a five bit word.         */
#define UART_S (1 << 27)
#define UART_P (1 << 26)
#define UART_F (1 << 25)
#define UART_T (1 << 24)
#define UART_BAUD (1 << 0)


/* ----- Control register                                             */

#define UART_TX_RST (1 << 5)
#define UART_TX_INT_EN (1 << 4)
#define UART_TX_EN (1 << 3)
#define UART_RX_RST (1 << 2)
#define UART_RX_INT_EN (1 << 1)
#define UART_RX_EN (1 << 0)

/* ----- Receive register                                             */

#define UART_RX_C (1 << 13)
#define UART_RX_BREAK (1 << 12)
#define UART_RX_ERR (1 << 11)
#define UART_RX_FRAME_ERR (1 << 10)
#define UART_RX_PARITY_ERR (1 << 9)
#define UART_RX_EMPTY (1 << 8)
#define UART_RX_BYTE_WIDTH 8
#define UART_RX_BYTE (1 << 0)

/* ----- Transmit register                                            */

#define UART_TX_O (1 << 11)
#define UART_TX_BREAK (1 << 10)
#define UART_TX_BUSY (1 << 9)
#define UART_TX_EMPTY (1 << 8)
#define UART_TX_BYTE_WIDTH 8
#define UART_TX_BYTE (1 << 0)


/**
 * @brief UART peripheral register map.
 */

typedef struct {
  volatile uint32_t SETUP;   /* UART configuration / setup register     */
  volatile uint32_t CONTROL;  /* UART control, TX RX and int enable      */
  volatile uint32_t RX_DATA; /* Contains RX data                        */
  volatile uint32_t TX_DATA; /* Contains TX data                        */
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
  uint32_t ParityLock;
} UART_InitTypeDef;

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
 * @brief Enables UART TX port
 */

void UART_TX_Enable(UART_HandleTypeDef *huart);

/**
 * @brief Disables UART TX port
 */

void UART_TX_Disable(UART_HandleTypeDef *huart);

/**
 * @brief resets UART TX module
 */

void UART_TX_Reset(UART_HandleTypeDef *huart);

/**
 * @brief Enables UART RX port
 */

void UART_RX_Enable(UART_HandleTypeDef *huart);

/**
 * @brief Disables UART RX port
 */

void UART_RX_Disable(UART_HandleTypeDef *huart);

/**
 * @brief resets UART RX module
 */

void UART_RX_Reset(UART_HandleTypeDef *huart);

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

void UART_RX_Not_Empty_IRQHandler(UART_HandleTypeDef *huart);

/**
 * @brief TX FIFO not-full interrupt handler
 */

void UART_TX_Not_Full_IRQHandler(UART_HandleTypeDef *huart);

/**
 * @brief UART_Receive_IT complete callback
 */

void UART_RxCpltCallback(UART_HandleTypeDef *huart);

/**
 * @brief UART_Transmit_IT complete callback
 */

void UART_TxCpltCallback(UART_HandleTypeDef *huart);

#endif
