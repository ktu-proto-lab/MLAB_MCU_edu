#include <stdint.h>

#include "uart.h"

#define NULL                ((void *) 0)

/* Everywhere you see return HAL_* - a lot needs to change for those returns
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
          | (huart->Init.WordLength << 28);

      huart->gState = UART_STATE_READY; // if TxEnable false dont set ready?
      huart->RxState = UART_STATE_READY;
  }
  else
  {
      // return HAL_ERROR
  }
}

void UART_TX_Enable(UART_HandleTypeDef *huart)
{
    if (huart->gState == UART_STATE_READY)
    {
        huart->Instance->CONTROL |= UART_TX_EN;
    }
}

void UART_TX_Disable(UART_HandleTypeDef *huart)
{
    if (huart->gState == UART_STATE_READY)
    {
        huart->Instance->CONTROL &= ~UART_TX_EN;
    }
}

void UART_TX_Reset(UART_HandleTypeDef *huart)
{
    /* State probably doesn't matter and it should be able to
     * execute whenever it's called                             */
    huart->Instance->CONTROL |= UART_TX_RST;
}

void UART_RX_Enable(UART_HandleTypeDef *huart)
{
    if (huart->RxState == UART_STATE_READY)
    {
        huart->Instance->CONTROL |= UART_RX_EN;
    }
}

void UART_RX_Disable(UART_HandleTypeDef *huart)
{
    if (huart->RxState == UART_STATE_READY)
    {
        huart->Instance->CONTROL &= ~UART_RX_EN;
    }
}

void UART_RX_Reset(UART_HandleTypeDef *huart)
{
    /* State probably doesn't matter and it should be able to
     * execute whenever it's called                             */
    huart->Instance->CONTROL |= UART_RX_RST;
}

void UART_Transmit(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size)
{
    // Check whether UART core is busy (for example interupt driven transmision is
    // in progress)
    if (huart->gState != UART_STATE_READY) {
        return;
    }
    if ((pData == NULL) || (Size == 0U))
    {
        // return HAL_ERROR;
        return;
    }
    while (Size > 0)
    {
        if (!(huart->Instance->TX_DATA & UART_TX_BUSY))
        {
            huart->Instance->TX_DATA = *pData;
            pData++;
            Size--;
        }
    }
    while (huart->Instance->TX_DATA & UART_TX_BUSY); // Wait unitl transmit ends
}

void UART_Transmit_IT(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size)
{
    /* Check that a Tx process is not already ongoing */
    if (huart->gState != UART_STATE_READY)
    {
        // return HAL_BUSY;
        return;
    }
    if ((pData == NULL) || (Size == 0U))
    {
        // return HAL_ERROR;
        return;
    }

    huart->pTxBuffPtr = pData;
    huart->TxXferSize = Size;
    huart->TxXferCount = Size;

    huart->gState = UART_STATE_BUSY_TX;

    // Enable interrupt
    huart->Instance->CONTROL |= UART_TX_INT_EN;

    // return HAL_OK;
}



void UART_Receive(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size)
{
    while (Size > 0)
    {
        uint16_t rx_data = huart->Instance->RX_DATA;
        // Interrupt automaticaly acknowledges after second read from RX_DATA register
        if (rx_data & UART_RX_EMPTY)
        {
            *pData++ = rx_data;
            Size--;
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

        // Enable interrupt
        huart->Instance->CONTROL |= (1 << 1);

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
        *(huart->pRxBuffPtr) = huart->Instance->RX_DATA;
        
        if(huart->RxXferCount == 1)
        {
            // disable interrupt
            huart->Instance->CONTROL &= ~UART_RX_INT_EN;

            // enable CpltCallback
            UART_RxCpltCallback(huart);

            huart->RxState = UART_STATE_READY;
        }
        huart->pRxBuffPtr++;
        huart->RxXferCount--;
        
        
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
        
        if(huart->TxXferCount == 0)
        {
            /* disable interrupt                                            */
            huart->Instance->CONTROL &= ~UART_TX_INT_EN;


            huart->gState = UART_STATE_READY; /* There's probably a better way
                                                 to handle this, refer to
                                                 STM32_HAL                  */
            
            /* enable CpltCallback                                          */
            UART_TxCpltCallback(huart);
                                    
        }
        else{
            huart->Instance->TX_DATA = *(huart->pTxBuffPtr);
        }
        
        huart->pTxBuffPtr++;
        huart->TxXferCount--;

        // return HAL_OK;
    }
    else
    {
        // return HAL_BUSY;
    }
}
