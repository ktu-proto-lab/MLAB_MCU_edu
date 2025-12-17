#include <stdint.h>

#include "uart.h"

UART_HandleTypeDef huart;

int main () {

}

void UART_Init(UART_HandleTypeDef *huart) {

  if (huart == NULL) {
      return 0 // in STM32 HAL this returns HAL_ERROR (specific define can be found in stm32xxx_hal_def.h)
  }

  // SETUP register shouldn't be edited anywhere else except in this function
  huart.Instance->SETUP = (huart.Init.BaudRate << 0)
	  		| (huart.Init.ParityMode << 24)
			| (huart.Init.ParityLock << 25)
			| (huart.Init.Parity << 26)
			| (huart.Init.StopBits << 27)
			| (huart.Init.WordLength << 28)
			| (huart.Init.HwFlowCtrl << 30);
}
