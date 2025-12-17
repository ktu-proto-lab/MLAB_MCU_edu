// I2C test program.
// Program writes data 0xACAD to address 0x0102 on EEPROM using blocking method,
// then sets EEPROM address pointer back
//  to 0x0102 using blocking method. Then using non-blocking (interupt driven)
//  method reads two bytes from EEPROM (should be 0xACAD), modifies received
//  data to 0xABAC and transmits it back to EEPROM using non-blockig method (see
//  OC_I2C_MasterRxCpltCallback function).

#include <stdint.h>

#include "i2c_master.h"
#include "I2C_LCD.h"
#include "I2C_LCD_cfg.h"


#define GPIO_ADDR               0x40000000
#define I2C_BASE_ADDR           0x30000000

#define I2C_SPEED               400  // kHz
#define CPUFreq                 80   // MHz

#define MyI2C_LCD I2C_LCD_1




I2C_HandleTypeDef i2c;


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



uint8_t data_to_write[3] = {0x00, 0x30, 0x20};  // 2 address bytes + 2 data bytes
uint8_t eeprom_i2c_addr = 0b10100000;                 // 7-bit address + write bit = 0
// uint8_t lcd_i2cm_addr = 0x27;                          // 7-bit address + write bit = 0
uint8_t data[2];                    // Received data
uint64_t counter=9;

int main() {
  I2C_Init(&i2c, I2C_BASE_ADDR, I2C_SPEED, CPUFreq);  // Initialize I2C core
  
  I2C_LCD_Init(MyI2C_LCD);
  I2C_LCD_SetCursor(MyI2C_LCD, 0, 0);
  I2C_LCD_WriteString(MyI2C_LCD, "KTU MLAB IBEX RISCV");
  
}



