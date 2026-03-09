// Preprocessor defines

// `define FPGA_Implementation

`ifdef FPGA_Implementation
// Vivado needs define in file, for xrun we specify FUNCTIONAL inline with command
`define FUNCTIONAL
// I2C reset prescaler value (for boot operation)
// Prescaler = clk_sys/(5*I2C_freq)-1
// FPGA I2C clock ~400kHz
`define BOOT_I2C_PRESCALER 16'd11

`define GPIO_ADDRHH 7
`define GPIO_ADDRHL 6
`define GPIO_ADDRLH 1
`define GPIO_ADDRLL 0

`else
// Higher I2c frequency for simulation
`define BOOT_I2C_PRESCALER 16'd15       //80MHz sysclock, 1MHz i2c
// `define BOOT_I2C_PRESCALER 16'd39    //80MHz sysclock, 400kHz i2c
`endif

// Peripheral base addresses

`define IMEM_BASE_ADDR  32'hA000_0000
`define DMEM_BASE_ADDR  32'h9000_0000

`define UART_BASE_ADDR	32'h5000_0000
`define GPIO_BASE_ADDR  32'h4000_0000
`define I2C_BASE_ADDR   32'h3000_0000

`define PIT_BASE_ADDR   32'h2000_0000

`define SPI_FLASH_BASE_ADDR   32'h8000_0000


// GPIO Count
`define GPIO_IOS 10

`define UART_NO_FIFO

// Uncomment the following to disable bootloader and use MEMInit (ONLY FOR SIMULATION)
`define BOOT_SKIP

// Uncomment the following to enable bootloader writeback to eeprom after initial boot
// `define BOOT_WRITEBACK

// THE FOLLOWING IS UNUSED
// I2C debouncer register size (wait unitl full register fills with ones)
// `define I2C_DEBOUNCER_REG_SIZE 1



