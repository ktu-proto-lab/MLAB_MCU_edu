// I2C test program.
// Program writes data 0xACAD to address 0x0102 on EEPROM using blocking method,
// then sets EEPROM address pointer back
//  to 0x0102 using blocking method. Then using non-blocking (interupt driven)
//  method reads two bytes from EEPROM (should be 0xACAD), modifies received
//  data to 0xABAC and transmits it back to EEPROM using non-blockig method (see
//  OC_I2C_MasterRxCpltCallback function).

#include <stdint.h>

#include "i2c_master.h"

#define GPIO_ADDR 0x40000000
#define I2C_BASE_ADDR 0x30000000

#define I2C_SPEED 400  // kHz
#define CPUFreq 80     // MHz

// prescale=1/(12,5ns*5*400kHz)-1=39=0x27

// int i2c_write_eeprom(uint8_t dev_addr, uint16_t word_addr, uint8_t data);
// int i2c_read_eeprom(uint8_t dev_addr, uint16_t word_addr);

I2C_HandleTypeDef i2c;

// uint8_t data_to_write[4] = {0x01, 0x02, 0xBC, 0xBD};  // 2 address bytes + 2 data bytes
uint8_t eeprom_addr = 0b10100000;                      // 7-bit address + write bit = 0
uint8_t data[2];                                      // Received data


uint8_t tb_i2c_addr = 0x3c<<1;
uint8_t read_only_data_address = 0x80; 
uint8_t data_to_write[5] = {0x00, 0x00, 0x00, 0x00, 0x00}; // 1 address byte + 4 data bytes

int main() {
  // ---------------------------------------------
  // 24CS512 Byte Write operation (Datasheet p.14)

  I2C_Init(&i2c, I2C_BASE_ADDR, I2C_SPEED, CPUFreq);  // Initialize I2C core
  
  I2C_Master_Transmit(&i2c, tb_i2c_addr, (uint8_t *)&read_only_data_address, 1);  // Set pointer
  I2C_Master_Receive(&i2c, tb_i2c_addr, (uint8_t *)&data, 2);
  data_to_write[1]=data[0];
  data_to_write[2]=data[1];

  uint16_t new_number=data[0]*data[1];
  data_to_write[4]=new_number & 0xFF;
  data_to_write[3]=(new_number>>8) & 0xFF;
  I2C_Master_Transmit(&i2c, tb_i2c_addr, (uint8_t *)&data_to_write, 5);  // Write data to I2C Slave
  
  read_only_data_address+=2;
  I2C_Master_Transmit(&i2c, tb_i2c_addr, (uint8_t *)&read_only_data_address, 1);  // Set pointer
  I2C_Master_Receive_IT(&i2c, tb_i2c_addr, (uint8_t *)&data, 2);
  
  /*
  I2C_Master_Transmit(&i2c, tb_i2c_addr, (uint8_t *)&data_to_write, 1);  // Set pointer
  I2C_Master_Receive(&i2c, tb_i2c_addr, (uint8_t *)&dataa, 2);
  data_to_write[4]= dataa[0]+1;
  I2C_Master_Transmit(&i2c, tb_i2c_addr, (uint8_t *)&data_to_write, 5);
  I2C_Master_Transmit(&i2c, tb_i2c_addr, (uint8_t *)&data_to_write, 1);  // Set pointer
  I2C_Master_Receive_IT(&i2c, tb_i2c_addr, (uint8_t *)&data, 2);*/
  
  // Expected: 0xAB 0xAA 0xCC 0xAC
  /*
  I2C_Master_Transmit(&i2c, slave_addr, (uint8_t *)&data_to_write, 4);  // Write data to EEPROM

  I2C_Master_Transmit(&i2c, slave_addr, (uint8_t *)&data_to_write, 2);  // Set EEPROM pointer
  I2C_Master_Receive_IT(&i2c, slave_addr, (uint8_t *)&data,
                           2);  // Read data from EEPORM using non-blocking method (calls
                                // OC_I2C_MasterRxCpltCallback after it's done)
  while (1) {
  }

  I2C_Master_Transmit_IT(&i2c, slave_addr, (uint8_t *)&data_to_write, 4);

  I2C_Master_Receive(&i2c, slave_addr, (uint8_t *)&data, 1);
  I2C_Master_Transmit(&i2c, slave_addr, (uint8_t *)&data_to_write, 3);*/
}

void I2C_MasterTxCpltCallback(I2C_HandleTypeDef *i2c) {
  // I2C non-blocking transmit is done
}

void I2C_MasterRxCpltCallback(I2C_HandleTypeDef *i2c) {
  data_to_write[0] += 4;       // Change pointer
  data_to_write[1] = data[0];  // Change data to write acording to received data
  data_to_write[2] = data[1];  // Change data to write acording to received data
  
  uint16_t new_number=data[0]*data[1];
  data_to_write[4]=new_number & 0xFF;
  data_to_write[3]=(new_number>>8) & 0xFF;
  I2C_Master_Transmit_IT(i2c, tb_i2c_addr, (uint8_t *)&data_to_write, 5);
  // I2C non-blocking receive is done
  // data_to_write[1] += 1;           // Change EEPROM pointer
  // data_to_write[2] = data[0] - 1;  // Change data to write acording to received data
  // data_to_write[3] = data[1] - 1;  // Change data to write acording to received data
  // I2C_Master_Transmit_IT(i2c, slave_addr, (uint8_t *)&data_to_write,
  //                           4);  // Write new data to EEPROM using non-blocking method
}
