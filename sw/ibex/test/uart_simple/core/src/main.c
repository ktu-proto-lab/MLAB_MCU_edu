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

void DELAY_US(uint64_t wait){
  uint64_t cycle;
  uint32_t mcycle;
  uint32_t mcycleh;
  wait=wait*CPUFreq;
  __asm__ volatile ("csrr %0, mcycle":"=r"(mcycle));
  __asm__ volatile ("csrr %0, mcycleh":"=r"(mcycleh));
  cycle=mcycle | (uint64_t)mcycleh << 32;
  wait+=cycle;
  while (cycle < wait){
    __asm__ volatile ("csrr %0, mcycle":"=r"(mcycle));
    __asm__ volatile ("csrr %0, mcycleh":"=r"(mcycleh));
    cycle=mcycle | (uint64_t)mcycleh << 32;
  }
}

void DELAY_MS(uint64_t wait){
  DELAY_US(wait*1000);
}

uint8_t transmit[13] = "Hello World!\n";
uint8_t enter1[18]   = "\nEnter 1st number\n";
uint8_t enter2[18]   = "\nEnter 2nd number\n";
uint8_t enterop[17]  = "\nEnter operation\n";
uint8_t entered[8]   = "Entered ";
uint8_t result[8]    = "\nResult ";


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

  UART_Transmit(&huart, transmit, 13);
  
  uint8_t num1, num2;
  while (1){
    UART_Transmit(&huart, enter1, 18);
    UART_Receive(&huart, receive, 1);
    UART_Transmit(&huart, entered, 8);
    UART_Transmit(&huart, receive, 1);
    num1 = atoi(receive);
    
    UART_Transmit(&huart, enter2, 18);
    UART_Receive(&huart, receive, 1);
    UART_Transmit(&huart, entered, 8);
    UART_Transmit(&huart, receive, 1);
    num2 = atoi(receive);
    
    UART_Transmit(&huart, enterop, 17);
    UART_Receive(&huart, receive, 1);
    UART_Transmit(&huart, entered, 8);
    UART_Transmit(&huart, receive, 1);
    
    UART_Transmit(&huart, result, 8);
    
    int8_t ans=num1;
    
    if (receive[0]=="+"){
      ans=ans+num2;
    }
    else if (receive[0]=="-"){
      ans=ans-num2;;
    }
    uint8_t toPrint[3];
    itoa(ans,toPrint,10);
    UART_Transmit(&huart, toPrint, 3);
    
    
    // itoa(receive,num1,1);
    // UART_Transmit(&huart, receive, 1);
  }
  return 0;
}

void UART_TxCpltCallback(UART_HandleTypeDef *huart) {}

void UART_RxCpltCallback(UART_HandleTypeDef *huart) {}

