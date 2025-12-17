#include <stdint.h>
#include <stdio.h>
#include "gpio.h"
#include "uart.h"


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



int _write(int fd, char* ptr, int len) {
  UART_Transmit(&huart, (uint8_t*) ptr, len);
  return len;
}

int _read(int fd, char* ptr, int len){
  UART_Receive(&huart, (uint8_t *)ptr, len);
  return len;
}

int main() {
  
  uint8_t transmit[33] = "Uart non-blocking transmit 12345";
  uint8_t receive[24];

  // Set UART TX line as output through GPIO pin 1
  GPIO_Init(&gpio);  // Initialize GPIO core
  gpio.regs->AUX |= GPIO_PIN_1;
  gpio.regs->OE |= GPIO_PIN_1;
  
  gpio.regs->OE |= GPIO_PIN_7 | GPIO_PIN_6 | GPIO_PIN_5 | GPIO_PIN_4 | GPIO_PIN_3 | GPIO_PIN_2; 

  huart.Init.BaudRate = UART_BAUD_INTERVAL(CPUFreq, UART_BAUDRATE);
  huart.Init.WordLength = 0;
  huart.Init.StopBits = 0;
  huart.Init.Parity = 0;
  huart.Init.ParityMode = 0;
  huart.Init.ParityLock = 0;
  
  UART_Init(&huart);  // Initialize UART core
  huart.Instance->RX_ENABLE=1;
  // UART_Transmit(&huart, transmit, 32);
  printf("UART with FIFO\n");
  uint8_t a = 69;
  printf("-Ozzy, do you have an instagram?\n");
  printf("-A gram of what, sorry?\n");
  printf("Sis tekstas buvo parasytas naudojant newlib'o printf\n");
  printf("Cia yra integeris %d \n",a);
  // puts("");
  DELAY_MS(1);
  printf("\n\nIveskte pirma skaiciu");
  char buffer[100];
  fgets(buffer, 2, stdin);
  int number1=buffer[0]-48;
  printf("\nIvesta: %d",number1);
  printf("\nIveskte antra skaiciu");
  fgets(buffer, 2, stdin);
  int number2=buffer[0]-48;
  printf("\nIvesta: %d",number2);
  printf("\nIveskte operacija (+, -)");
  fgets(buffer, 2, stdin);
  if (buffer[0]==43){
    printf("\nSuma: %d\n", number1+number2);
  }
  else if (buffer[0]==45){
    printf("\nSkirtumas: %d\n", number1-number2);
  }

  UART_Receive(&huart, receive, 8);

  UART_Transmit(&huart, receive, 8);

  
  
  // scanf("%s", buffer);
  // puts(buffer);
  // for (int i=0; i<1024; i++){
  //   printf("Skaičius: %d \n", i);
  // }
  // UART_Transmit(&huart, transmit, 32);

  DELAY_MS(2);

  
  UART_Transmit_IT(&huart, transmit, 32);
  printf("\n");

  return 0;
}


void* _sbrk(ptrdiff_t incr) {
    extern char _end;         // Defined by the linker - start of heap
    extern char _stack_bottom; // Defined in our linker script - bottom of stack area

    static char *heap_end = &_end;
    char *prev_heap_end = heap_end;

    // Calculate safe stack limit - stack grows down from _stack_top towards _stack_bottom
    char *stack_limit = &_stack_bottom;
    
    // Check if heap would grow too close to stack
    if (heap_end + incr > stack_limit) {
        // errno = ENOMEM;
        return (void*) -1; // Return error
    }
// 
    heap_end += incr;
    return (void*) prev_heap_end;
}

