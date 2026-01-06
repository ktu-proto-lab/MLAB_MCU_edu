#include <stdint.h>
#include <stdlib.h>
#include "uart.h"
#include "gpio.h"

#define I2C_BASE_ADDR   0x30000000
#define GPIO_BASE_ADDR  0x40000000
#define UART_BASE_ADDR	0x50000000

#define UART_BAUDRATE   115200
#define CPUFreq 80     // MHz


GPIO_HandleTypeDef gpio;
UART_HandleTypeDef huart;


uint8_t transmit[13] = "Hello World!\n";
uint8_t receive[2];

int main() {
  GPIO_Init(&gpio);  // Initialize GPIO core

  // Set UART parameters
  huart.Init.BaudRate = UART_BAUD_INTERVAL(CPUFreq, UART_BAUDRATE);
  huart.Init.WordLength = 0;
  huart.Init.StopBits = 0;
  huart.Init.Parity = 0;
  huart.Init.ParityMode = 0;
  huart.Init.ParityLock = 0;
  
  UART_Init(&huart);  // Initialize UART core
  UART_TX_Enable(&huart);
  UART_RX_Enable(&huart);

  gpio.regs->AUX |= GPIO_PIN_1; // Set GPIO pin 1 to output auxilary signal (UART TX)
  gpio.regs->OE |= GPIO_PIN_1; // Enable output on GPIO pin 1

  UART_Transmit(&huart, transmit, 13); // Transmit "Hello World!" message
  
  uint8_t num1, num2;
  
  // Jumps into forever loop  
  while (1){
    UART_Transmit(&huart, "\nEnter 1st number\n", 18);
    UART_Receive(&huart, receive, 1);
    UART_Transmit(&huart, "Entered ", 8);
    UART_Transmit(&huart, receive, 1);
    
    // Converts a string to an number. For exmaple number '4' in ASCII format is 52 in decimal value. So for procesor to get a 4 in in decimal, we must either substract 48 or use this function
    num1 = atoi(receive);
    
    UART_Transmit(&huart, "\nEnter 2nd number\n", 18);
    UART_Receive(&huart, receive, 1);
    UART_Transmit(&huart, "Entered ", 8);
    UART_Transmit(&huart, receive, 1);
    num2 = atoi(receive);
    
    UART_Transmit(&huart, "\nEnter operation\n", 17);
    UART_Receive(&huart, receive, 1);
    UART_Transmit(&huart, "Entered ", 8);
    UART_Transmit(&huart, receive, 1);
    
    UART_Transmit(&huart, "\nResult ", 8);
    
    int8_t ans;
    
    if (receive[0]=='+'){
      ans=num1+num2;
    }
    else if (receive[0]=='-'){
      ans=num1-num2;
    }
    uint8_t toPrint[3];
    
    // Just like atoi, itoa functions does the oposite, it converts a decimal number to ASCII.
    // First argument (ans) is a decimal number, 2nd argument (toPrint) is output in ASCII, and 3rd argument (10) – numerical base. 
    itoa(ans,toPrint,10);
    
    UART_Transmit(&huart, toPrint, 3);
    
    
    // itoa(receive,num1,1);
    // UART_Transmit(&huart, receive, 1);
  }
  return 0;
}

void UART_TxCpltCallback(UART_HandleTypeDef *huart) {}

void UART_RxCpltCallback(UART_HandleTypeDef *huart) {}

