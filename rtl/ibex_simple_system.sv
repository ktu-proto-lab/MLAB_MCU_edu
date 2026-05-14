`include "project_defs.svh"

module ibex_simple_system #(

    parameter bit ICache        = 1'b0,    // 0:prefetch buffer, 1:instruction cache
    parameter IMEM_1_InitFile = "",
    parameter IMEM_2_InitFile = "",
    parameter DMEM_InitFile = ""
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
  output  logic [`GPIO_IOS-1:0] gpio_oe

  // input   logic   scan_en,
  // input   logic   scan_in,
  // output  logic   scan_out
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
  localparam int NUM_SLAVES         = 7;

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

  localparam [31:0] sobel_base_addr = `SOBEL_BASE_ADDR;
  localparam [31:0] sobel_size      = 'h0C; // CTRL, STATUS, FRAME_COUNT

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

  // Instruction and Data memories
  wb_sram_2048x32 #(
`ifdef BOOT_SKIP
    .MEMInitFile_1(IMEM_1_InitFile),
    .MEMInitFile_2(IMEM_2_InitFile)
`endif
    ) imem (
    .wb(wbs[0])
  );

  wb_sram_1024x32 #(
`ifdef BOOT_SKIP
    .MEMInitFile(DMEM_InitFile)
`endif
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
      .wb(wbs[4]),

      .pit_irq_o  (pit_irq)
  );

  // Camera FIFO signals
  logic        fifo_wr_en, fifo_rd_en;
  logic        fifo_full,  fifo_empty;
  logic [31:0] fifo_din,   fifo_dout;

  // Frame BRAM B port wires
  logic        sobel_dst_en, sobel_dst_we;
  logic [14:0] sobel_dst_addr;
  logic [31:0] sobel_dst_wdata, sobel_dst_rdata;

  // Input FIFO: camera interface writes, sobel_acc reads
  fifo_fwft #(.DATA_WIDTH(32), .DEPTH_WIDTH(10)) u_camera_fifo (
      .clk   (clk_sys),
      .rst   (~rst_sync_n),
      .din   (fifo_din),
      .wr_en (fifo_wr_en),
      .rd_en (fifo_rd_en),
      .dout  (fifo_dout),
      .full  (fifo_full),
      .empty (fifo_empty)
  );

  // Tie camera-side inputs low until camera interface is integrated TODO: Connect camera interface here
  assign fifo_din   = 32'h0;
  assign fifo_wr_en = 1'b0;

  // Frame BRAM B - processed frame (destination for edge detection)
  bram u_frame_bram_b (
      .clk   (clk_sys),
      .en    (sobel_dst_en),
      .we    (sobel_dst_we),
      .addr  (sobel_dst_addr),
      .wdata (sobel_dst_wdata),
      .rdata ()
  );

  // Edge detection accelerator
  sobel_acc u_sobel_acc (
      .wb            (wbs[6]),

      .fifo_empty    (fifo_empty),
      .fifo_dout     (fifo_dout),
      .fifo_rd_en    (fifo_rd_en),

      .dst_en    (sobel_dst_en),
      .dst_we    (sobel_dst_we),
      .dst_addr  (sobel_dst_addr),
      .dst_wdata (sobel_dst_wdata)
  );

  //==================================================
  // Shared or crossbar interconnect
  //==================================================
    // For now only sharedbus is functional
       wb_interconnect_sharedbus
         #(.numm      (NUM_MASTERS),
           .nums      (NUM_SLAVES),
           .base_addr ('{imem_base_addr, dmem_base_addr, gpio_base_addr, i2c_base_addr, pit_base_addr, uart_base_addr, sobel_base_addr}),
           .size      ('{imem_size, dmem_size, gpio_size, i2c_size, pit_size, uart_size, sobel_size}))
       u_wb_interconnect
         (.wbm, .wbs);
endmodule
