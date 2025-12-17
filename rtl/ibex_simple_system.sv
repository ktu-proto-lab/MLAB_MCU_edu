`include "project_defs.svh"

module ibex_simple_system (
  input   logic   clk_sys_Pad,
  input   logic   rst_sys_n_Pad,
  inout   logic   SDA_Pad,
  inout   logic   SCL_Pad,     
  inout   logic [`GPIO_IOS-1:0] ext_pad,  // GPIOS_IOS macro in gpio_defines.v

  input   logic   test_mode_Pad
);

  //==================================================
  // Signals connecting to intermediate top
  //==================================================
  logic clk_sys, rst_async_n;
  logic scl_pad_i, scl_pad_o, scl_padoen_o;
  logic sda_pad_i, sda_pad_o, sda_padoen_o;

  logic [`GPIO_IOS-1:0] ext_pad_i;
  logic [`GPIO_IOS-1:0] ext_pad_o;
  logic [`GPIO_IOS-1:0] ext_pad_oe;

  logic [`GPIO_IOS-1:0] gpio_o;
  logic [`GPIO_IOS-1:0] gpio_oe;

  logic scan_en, scan_in, scan_out, test_mode;

  //==================================================
  // Instantiate intermediate top without pads
  //==================================================
  ibex_simple_system_int #(
    .ICache(0)   // 0:prefetch buffer, 1:instruction cache
  ) u_ibex_simple_system_int (
  .clk_sys(clk_sys),
  .rst_async_n(rst_async_n),
  .scl_pad_i(scl_pad_i),
  .scl_pad_o(scl_pad_o),
  .scl_padoen_o(scl_padoen_o),
  .sda_pad_i(sda_pad_i),
  .sda_pad_o(sda_pad_o),
  .sda_padoen_o(sda_padoen_o),
  .ext_pad_i(ext_pad_i),
  .gpio_o(gpio_o),
  .gpio_oe(gpio_oe),
  .scan_en(scan_en),
  .scan_in(scan_in),
  .scan_out(scan_out)
);

  //==================================================
  // Instantiate PADS
  //==================================================

  // Generate GPIOs
  genvar i;

  generate
    for(i = 0; i<`GPIO_IOS; i++)begin : GPIO
`ifdef FPGA_Implementation
// Use ext_pad as output only
  // assign ext_pad[i] = ext_pad_o[i];

// Use ext_pad as inout
    IOBUF #(
    .DRIVE(12), // Specify the output drive strength
    .IBUF_LOW_PWR("FALSE"),  // Low Power - "TRUE", High Performance = "FALSE"
    .IOSTANDARD("LVCMOS33"), // Specify the I/O standard
    .SLEW("SLOW") // Specify the output slew rate
  ) pad_io (
    .O(ext_pad_i[i]),     // Buffer output
    .IO(ext_pad[i]),   // Buffer inout port (connect directly to top-level port)
    .I(ext_pad_o[i]),     // Buffer input
    .T(~(ext_pad_oe[i]))      // 3-state enable input, high=input, low=output
  );
`else
      // DOUT is output to core
      ixc013_b16m pad_io (  .DOUT(ext_pad_i[i]), 
                            .DIN(ext_pad_o[i]), 
                            .OEN(~(ext_pad_oe[i])), 
                            .PAD(ext_pad[i]));
`endif
    end
  endgenerate
  
`ifdef FPGA_Implementation
  assign clk_sys = clk_sys_Pad;
  assign rst_async_n = rst_sys_n_Pad;
  assign test_mode = test_mode_Pad;
`else
  // Faster (200MHz) input pads for CLK and RST (faster pads)
  ixc013_i16x pad_clk_sys   (.DOUT(clk_sys),      .PAD(clk_sys_Pad));
  ixc013_i16x pad_rst_sys   (.DOUT(rst_async_n),  .PAD(rst_sys_n_Pad));
  ixc013_i16x pad_test_mode (.DOUT(test_mode),  .PAD(test_mode_Pad));
`endif

`ifdef FPGA_Implementation
  IOBUF #(
    .DRIVE(8), // Specify the output drive strength
    .IBUF_LOW_PWR("FALSE"),  // Low Power - "TRUE", High Performance = "FALSE"
    .IOSTANDARD("LVCMOS33"), // Specify the I/O standard
    .SLEW("SLOW") // Specify the output slew rate
  ) pad_SDA (
    .O(sda_pad_i),     // Buffer output
    .IO(SDA_Pad),   // Buffer inout port (connect directly to top-level port)
    .I(sda_pad_o),     // Buffer input
    .T(sda_padoen_o)      // 3-state enable input, high=input, low=output
  );
  IOBUF #(
    .DRIVE(8), // Specify the output drive strength
    .IBUF_LOW_PWR("FALSE"),  // Low Power - "TRUE", High Performance = "FALSE"
    .IOSTANDARD("LVCMOS33"), // Specify the I/O standard
    .SLEW("SLOW") // Specify the output slew rate
  ) pad_SCL (
    .O(scl_pad_i),     // Buffer output
    .IO(SCL_Pad),   // Buffer inout port (connect directly to top-level port)
    .I(scl_pad_o),     // Buffer input
    .T(scl_padoen_o)      // 3-state enable input, high=input, low=output
  );
`else

  // I2C comunication does not require to invert Output Enable (OEN) !!!
  // (See GPIO and I2C docs)
  // I2C pads
  ixc013_b16m pad_SDA (   .DOUT(sda_pad_i), 
                          .DIN(sda_pad_o), 
                          .OEN(sda_padoen_o), 
                          .PAD(SDA_Pad));

  ixc013_b16m pad_SCL (   .DOUT(scl_pad_i), 
                          .DIN(scl_pad_o), 
                          .OEN(scl_padoen_o), 
                          .PAD(SCL_Pad));
`endif

  //==================================================
  // Scan
  //==================================================

  always_comb begin
    // Default all pads to GPIO
    ext_pad_o  = gpio_o;
    ext_pad_oe = gpio_oe;

    // Default scan signals
    scan_in = 1'b0;
    scan_en = 1'b0;

    if (test_mode) begin
      // Scan_in from pad[2]
      scan_in = ext_pad_i[2];
      ext_pad_oe[2] = 1'b0; // input

      // Scan_out to pad[3]
      ext_pad_o[3]  = scan_out;
      ext_pad_oe[3] = 1'b1; // output

      // Scan_en input from pad[4]
      scan_en = ext_pad_i[4]; 
      ext_pad_oe[4] = 1'b0; // input
    end
  end
  
endmodule
module ibex_simple_system_int #(
    parameter bit ICache        = 1'b0    // 0:prefetch buffer, 1:instruction cache
  )(
  input   logic   clk_sys,
  input   logic   rst_async_n,

  input   logic      scl_pad_i,
  output  logic      scl_pad_o,
  output  logic      scl_padoen_o,
  input   logic      sda_pad_i,
  output  logic      sda_pad_o,
  output  logic      sda_padoen_o,
  
  input   logic [`GPIO_IOS-1:0] ext_pad_i,

  output  logic [`GPIO_IOS-1:0] gpio_o,
  output  logic [`GPIO_IOS-1:0] gpio_oe,

  input   logic   scan_en,
  input   logic   scan_in,
  output  logic   scan_out
);

  //==================================================
  // Signals
  //==================================================

  logic rst_sync_n, rst_core_n;
  
  // // GPIO signals
  logic gpio_int; // Interrupt signal to Core
  logic [`GPIO_IOS-1:0] gpio_aux; // Auxiliary input 
  
  // I2C signals
  logic      i2c_int; 

  // logic scl_pad_i_debounced;
  // logic sda_pad_i_debounced; 

  // UART signals
  
  `ifdef UART_NO_FIFO
  `else
  logic	     uart_ncts_i;
  logic	     uart_nrts_o;
  
  logic	     uart_rxfifo_int_o;
  logic      uart_txfifo_int_o;
  `endif
  
  logic	     uart_rx_int_o;
  logic	     uart_tx_int_o;
  

  logic      uart_rx_i;
  logic      uart_tx_o;

  // PIT signals
  logic      pit_irq;   // Interrupt Timer Request signal to Core

  //==================================================
  // Local Parameters
  //==================================================

  localparam int NUM_MASTERS        = 3;
  localparam int NUM_SLAVES         = 6;
  localparam int PIT_SLAVE_PORT_NUM = 4;

  //==================================================
  // Memory mapped device base addresses
  //==================================================
  // Size of memory spaces are in words (4 bytes)

  localparam [31:0] imem_base_addr  = `IMEM_BASE_ADDR;
  localparam [31:0] imem_size       = 'h2000; //8192 bytes

  localparam [31:0] dmem_base_addr  = `DMEM_BASE_ADDR;
  localparam [31:0] dmem_size       = 'h1000; //4096 bytes

  localparam [31:0] uart_base_addr  = `UART_BASE_ADDR;
  `ifdef UART_NO_FIFO
  localparam [31:0] uart_size	      = 'h10; // 4 register for UART + 1 register for rx line enable
  `else
  localparam [31:0] uart_size	      = 'h14; // 4 register for UART + 1 register for rx line enable
  `endif

  localparam [31:0] gpio_base_addr  = `GPIO_BASE_ADDR;
  localparam [31:0] gpio_size       = 'h40; // Round up to be divisable by 4

  localparam [31:0] i2c_base_addr   = `I2C_BASE_ADDR;
  localparam [31:0] i2c_size        = 'h14; // Round up to be divisable by 4

  localparam [31:0] pit_base_addr   = `PIT_BASE_ADDR;
  localparam [31:0] pit_size        = 'h10; // CTRL, MOD and CNT regs

  //==================================================
  // Instantiate modules
  //==================================================

  // Reset synchronizer
  areset_sync #(
    .NumRegs(4)
  ) u_areset_sync (
   .clk_i           (clk_sys),
   .i_rst_async     (rst_async_n),       // Asynchronous reset
   .o_rst_sync      (rst_sync_n)         // Asynchronous Reset with de-assertion synchronized
);
  // WB interfaces
  wb_if wbm[NUM_MASTERS] (.rst(rst_sync_n), .clk(clk_sys));  // Masters
  wb_if wbs[NUM_SLAVES] (.rst(rst_sync_n), .clk(clk_sys));  // Slaves

  // Bootloader as wishbone master with top priority
  bootloader_top u_bootloader(
        .wb(wbm[0]),
        .clk(clk_sys),
        .rst_core_n(rst_core_n) // rst for Ibex only
  );

  // Wishbone wrapped Ibex Core
  wb_ibex_top #( 
    .ICache  (ICache)
    )
   u_wb_ibex_top
     (.clk                  (clk_sys),
      .rst_n                (rst_core_n),
      .instr_wb             (wbm[2]),
      .data_wb              (wbm[1]),

      .test_en              (1'b0),
      .ram_cfg              ('0),

      .hart_id              (32'h00000000),
      .boot_addr            (32'h80000000),

      .irq_software         (1'b0),
      .irq_timer            (pit_irq),  // Connect PIT's Interrupt Request signal
      .irq_external         (gpio_int),
      `ifdef UART_NO_FIFO
      .irq_fast             ({9'b0, uart_tx_int_o, uart_rx_int_o, 2'b0, i2c_int, 1'b0}),
      // .irq_fast             ({9'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
      `else
      .irq_fast             ({9'b0, uart_tx_int_o, uart_rx_int_o, uart_txfifo_int_o, uart_rxfifo_int_o, i2c_int, 1'b0}),
      `endif
      
      .irq_nm               (1'b0),

      .scramble_key_valid   (1'b0),
      .scramble_key         ('0),
      .scramble_nonce       ('0),
      .scramble_req         (),

      .debug_req            (1'b0),
      .crash_dump           (),
      .double_fault_seen    (),

      .fetch_enable         (ibex_pkg::IbexMuBiOn),
      .alert_minor          (),
      .alert_major_internal (),
      .alert_major_bus      (),
      .core_sleep           (),

      .scan_rst_n           (1'b0));

  // Instruction and Data memories TODO switch to PDK SRAM when we get it
  wb_sram_2048x32 #(
    // .MEMInitFile("./sw/ibex_sw/instr_hex.mem")
    ) imem (
    .wb(wbs[0])
  );

  wb_sram_1024x32 #(
    // .MEMInitFile("./sw/ibex_sw/data_hex.mem")
  ) dmem (
    .wb(wbs[1])
  );

  // GPIO module
  wb_gpio u_gpio(
    .wb(wbs[2]),

    .int_o        (gpio_int),
    .aux_i        (gpio_aux),         // Multiplexed outputs can be connected here
    .ext_pad_i    (ext_pad_i),    
    .ext_pad_o    (gpio_o),    
    .ext_padoe_o  (gpio_oe)    
  );
  // Connect UART tx to gpio aux
  assign gpio_aux = {{(`GPIO_IOS-2){1'b0}}, uart_tx_o, 1'b0};

  // UART module
  wb_uart u_uart(
    .wb(wbs[5]),
    
    
    // .i_cts_n		(uart_ncts_i),
    `ifdef UART_NO_FIFO
    `else
    .i_cts_n    (1'b0),
    .o_rts_n		(uart_nrts_o),
    .o_uart_rxfifo_int	(uart_rxfifo_int_o),
    .o_uart_txfifo_int	(uart_txfifo_int_o),
    `endif
    
    .o_uart_rx_int	(uart_rx_int_o),
    .o_uart_tx_int	(uart_tx_int_o),  

    // .i_uart_rx		(uart_rx_i),
    // .o_uart_tx		(uart_tx_o)
    .i_uart_rx    (ext_pad_i[0]),
    .o_uart_tx    (uart_tx_o)
  );


  // I2C module debouncer
  // i2c_debouncer u_i2c_debouncer_SDA (
  //  .clk         (clk_sys),
  //  .in          (sda_pad_i),
  //  .out         (sda_pad_i_debounced)
  // );

  //  i2c_debouncer u_i2c_debouncer_SCL (
  //  .clk         (clk_sys),
  //  .in          (scl_pad_i),
  //  .out         (scl_pad_i_debounced)
  // );

  // I2C module
  wb_i2c #(
      .BOOT_I2C_PRESCALER(`BOOT_I2C_PRESCALER)
    ) u_i2c (
    .wb(wbs[3]),

    .int_o         (i2c_int),

    // .scl_pad_i     (scl_pad_i_debounced),
    .scl_pad_i     (scl_pad_i),
    .scl_pad_o     (scl_pad_o),
    .scl_padoen_o  (scl_padoen_o),
    .sda_pad_i     (sda_pad_i),
    // .sda_pad_i     (sda_pad_i_debounced),
    .sda_pad_o     (sda_pad_o),
    .sda_padoen_o  (sda_padoen_o)  
  );

  // Programmable Interrupt Timer module
  wb_pit u_pit (
      .wb(wbs[PIT_SLAVE_PORT_NUM]),

      .pit_irq_o  (pit_irq)
  );

  //==================================================
  // Shared or crossbar interconnect
  //==================================================
    // For now only sharedbus is functional
       wb_interconnect_sharedbus
         #(.numm      (NUM_MASTERS),
           .nums      (NUM_SLAVES),
           .base_addr ('{imem_base_addr, dmem_base_addr, gpio_base_addr, i2c_base_addr, pit_base_addr, uart_base_addr}),
           .size      ('{imem_size, dmem_size, gpio_size, i2c_size, pit_size, uart_size}))
       u_wb_interconnect
         (.wbm, .wbs);
endmodule
