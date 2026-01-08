#include <stdint.h>

#include "uart.h"

#define IT_FIFO_THRESHOLD   115200
#define HALF_FIFO_LEN       8 
#define NULL                ((void *) 0)

/* If this driver ever gets updated STM32H7 series uses UART FIFOs so it's
 * a good reference.

 * Everywhere you see return HAL_* - a lot needs to change for those returns
 * to mean anything. HAL_STATUS needs to be defined and some error handling
 * implemented.                                                             */


void UART_Init(UART_HandleTypeDef *huart)
{
/*
  if (huart == NULL)
  {
      return HAL_ERROR;
  }
*/
  if (huart->gState == UART_STATE_RESET)
  {
      huart->Instance = (volatile UART_reg_map_t *)UART_BASE_ADDR;  // Initialize UART registers struct

      // SETUP register shouldn't be edited anywhere else except in this function
      // After editing huart->Init UART_Init(*huart) should always be called
      huart->Instance->SETUP = ((huart->Init.BaudRate << 0) & UART_SETUP_BAUD_MASK)
          | (huart->Init.ParityMode << 24)
          | (huart->Init.ParityLock << 25)
          | (huart->Init.Parity << 26)
          | (huart->Init.StopBits << 27)
          | (huart->Init.WordLength << 28)
          | (huart->Init.HwFlowCtrl << 30);

      huart->gState = UART_STATE_READY;
      huart->RxState = UART_STATE_READY;
  }
  else
  {
      // return HAL_ERROR
  }
}

void UART_Transmit(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size)
{
    while (Size > 0)
    {
        uint32_t free_spaces_in_fifo = ((huart->Instance->FIFO >> 18) & 0xF);

        while((free_spaces_in_fifo) > 0 && (Size > 0))
        {
            huart->Instance->TX_DATA = *pData++;
            Size--;
            free_spaces_in_fifo--;
        }
    }
}

void UART_Transmit_IT(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size)
{
    /* Check that a Tx process is not already ongoing */
    if (huart->gState == UART_STATE_READY)
    {
        if ((pData == NULL) || (Size == 0U))
        {
            // return HAL_ERROR;
        }

        huart->pTxBuffPtr = pData;
        huart->TxXferSize = Size;
        huart->TxXferCount = Size;

        huart->gState = UART_STATE_BUSY_TX;

        if(huart->Init.BaudRate > IT_FIFO_THRESHOLD)
        {
            uint32_t mie_bits = (1 << 21);
            asm volatile("csrs mie, %0" : : "r"(mie_bits));
            // Enable UART_TX_NOT_FULL_IRQHandler()
        }
        else
        {
            uint32_t mie_bits = (1 << 19);
            asm volatile("csrs mie, %0" : : "r"(mie_bits));
            // Enable UART_TX_HALF_EMTPY_IRQHandler()
        }

        // return HAL_OK;
    }
    else
    {
        // return HAL_BUSY;
    }
}


void UART_Receive(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size)
{
    while (Size > 0)
    {
        uint32_t valid_data_in_fifo = ((huart->Instance->FIFO >> 2) & 0xF);

        while(valid_data_in_fifo > 0)
        {
            *pData++ = huart->Instance->RX_DATA;
            Size--;
            valid_data_in_fifo--;
        }
    }
}

void UART_Receive_IT(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size)
{
    /* Check that a Rx process is not already ongoing */
    if (huart->RxState == UART_STATE_READY)
    {
        if ((pData == NULL) || (Size == 0U))
        {
            // return HAL_ERROR;
        }

        huart->pRxBuffPtr = pData;
        huart->RxXferSize = Size;
        huart->RxXferCount = Size;

        huart->RxState = UART_STATE_BUSY_RX;

        if(huart->Init.BaudRate > IT_FIFO_THRESHOLD)
        {
            uint32_t mie_bits = (1 << 20);
            asm volatile("csrs mie, %0" : : "r"(mie_bits));
            // Enable UART_RX_NOT_EMPTY_IRQHandler()
        }
        else
        {
            uint32_t mie_bits = (1 << 18);
            asm volatile("csrs mie, %0" : : "r"(mie_bits));
            // Enable UART_RX_HALF_FULL_IRQHandler()
        }

        // return HAL_OK;
    }
    else
    {
        // return HAL_BUSY;
    }
}

void UART_RX_Half_Full_IRQHandler(UART_HandleTypeDef *huart)
{
    if(huart->RxState == UART_STATE_BUSY_RX)
    {
        uint8_t data_to_process;

        if(huart->RxXferCount < HALF_FIFO_LEN)
        {
            data_to_process = huart->RxXferCount;
        }
        else
        {
            data_to_process = HALF_FIFO_LEN;
        }

        for(uint8_t i = 0; i < data_to_process; i++)
        {
            *(huart->pRxBuffPtr++) = huart->Instance->RX_DATA;

            if(--huart->RxXferCount == 0)
            {
                uint32_t mie_bits = (1 << 18);
                asm volatile("csrc mie, %0" : : "r"(mie_bits));
                /* disable interrupt                                        */
                /* enable CpltCallback                                      */
                huart->RxState = UART_STATE_READY; /* There's a better way to
                                                     handle this, refer to
                                                     STM32_HAL              */
            }
        }

        // return HAL_OK;
    }
    else
    {
        // return HAL_BUSY;
    }
}

void UART_RX_Not_Empty_IRQHandler(UART_HandleTypeDef *huart)
{
    if(huart->RxState == UART_STATE_BUSY_RX)
    {
        *(huart->pRxBuffPtr++) = huart->Instance->RX_DATA;

        if(--huart->RxXferCount == 0)
        {
            uint32_t mie_bits = (1 << 20);
            asm volatile("csrc mie, %0" : : "r"(mie_bits));
            // disable interrupt
            // enable CpltCallback
            huart->RxState == UART_STATE_READY;
        }

        // return HAL_OK;
    }
    else
    {
        // return HAL_BUSY;
    }

}

void UART_TX_Half_Empty_IRQHandler(UART_HandleTypeDef *huart)
{
    if(huart->gState == UART_STATE_BUSY_TX)
    {
        uint8_t data_to_process;

        if(huart->TxXferCount < HALF_FIFO_LEN)
        {
            data_to_process = huart->TxXferCount;
        }
        else
        {
            data_to_process = HALF_FIFO_LEN;
        }

        for(uint8_t i = 0; i < data_to_process; i++)
        {
            huart->Instance->TX_DATA = *(huart->pTxBuffPtr++);

            if(--huart->TxXferCount == 0)
            {
                uint32_t mie_bits = (1 << 19);
                asm volatile("csrc mie, %0" : : "r"(mie_bits));
                /* disable interrupt                                        */
                /* enable CpltCallback                                      */
                huart->gState = UART_STATE_READY; /* There's a better way to
                                                     handle this, refer to
                                                     STM32_HAL              */
            }
        }

        // return HAL_OK;
    }
    else
    {
        // return HAL_BUSY;
    }
}

void UART_TX_Not_Full_IRQHandler(UART_HandleTypeDef *huart)
{
    if(huart->gState == UART_STATE_BUSY_TX)
    {
        huart->Instance->TX_DATA = *(huart->pTxBuffPtr++);

        if(--huart->TxXferCount == 0)
        {
            uint32_t mie_bits = (1 << 21);
            asm volatile("csrc mie, %0" : : "r"(mie_bits));
            /* disable interrupt                                            */
            /* enable CpltCallback                                          */
            huart->gState = UART_STATE_READY; /* There's probably a better way
                                                 to handle this, refer to
                                                 STM32_HAL                  */
        }

        // return HAL_OK;
    }
    else
    {
        // return HAL_BUSY;
    }
}
