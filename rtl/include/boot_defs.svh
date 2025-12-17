`include "project_defs.svh"

// For Bootloader FSM
`define EEPROM_ADDR_PLUS_W_BIT 32'b1010_0000
`define EEPROM_ADDR_PLUS_R_BIT 32'b1010_0001
// Sizes in bytes
`define IMEM_SIZE 32'd8192
`define DMEM_SIZE 32'd4096
`define IMEM_BASE_ADDR 32'h8000_0000
`define DMEM_BASE_ADDR 32'h9000_0000
`define EEPROM_READ_ADDR 16'h0000 // EEPROM read start address
`define EEPROM_WRITE_ADDR 16'h3000 // must be aligned with page size
`define EEPROM_PAGE_SIZE 7 // page size = 2^EEPROM_PAGE_SIZE

// R/W registers
`define I2C_CTR (`I2C_BASE_ADDR + 32'h8)
// Write only registers
`define I2C_TXR (`I2C_BASE_ADDR + 32'hC)
`define I2C_CR  (`I2C_BASE_ADDR + 32'h10)
// Read only registers
`define I2C_RXR (`I2C_BASE_ADDR + 32'hC)
`define I2C_SR  (`I2C_BASE_ADDR + 32'h10)

// Control register bits
`define I2C_EN  32'b1000_0000
// Command register bits
`define I2C_STA 32'b1000_0000
`define I2C_STO 32'b0100_0000
`define I2C_RD  32'b0010_0000
`define I2C_WR  32'b0001_0000
`define I2C_ACK 32'b0000_1000
// Status register bits
`define I2C_RXACK 32'b1000_0000
`define I2C_BUSY  32'b0100_0000
`define I2C_TIP   32'b0000_0010
