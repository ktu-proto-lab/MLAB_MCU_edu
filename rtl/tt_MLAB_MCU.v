/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_MLAB_MCU (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:2] = 6'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};


  // Design instantiation

  reg [1:0] qspi_mod;
  reg [3:0] qspi_oe;

  ibex_simple_system #(
    ) dut (
        .clk_sys      (clk),
        .rst_async_n  (rst_n),

        .scl_pad_i    (uio_in[0]),
        .scl_pad_o    (uio_out[0]),
        .scl_padoen_o (uio_oe[0]),

        .sda_pad_i    (uio_in[1]),
        .sda_pad_o    (uio_out[1]),
        .sda_padoen_o (uio_oe[1]),

        .o_qspi_sck   (uo_out[0]),
        .o_qspi_cs_n  (uo_out[1]),
        .o_qspi_mod   (qspi_mod),
        .o_qspi_dat   (uio_out[5:2]),
        .i_qspi_dat   (uio_in[5:2]),

        .ext_pad_i    (uio_in[7:6]),
        .gpio_o       (uio_out[7:6]),
        .gpio_oe      (uio_oe[7:6])
    );

  always @(*)begin
    if(qspi_mod == 2'b10) begin // QUAD_WRITE 
        qspi_oe = 4'b1111; // Set to output
    end else if(qspi_mod == 2'b11) begin // QUAD_READ
        qspi_oe = 4'b0000; // Set to input
    end else begin // NORMAL_SPI
        qspi_oe = 4'b0001; // `dat[0]` is MOSI output, `dat[1]` is MISO input two MSB - don't care (could be reused)
    end
  end

  assign uio_oe[5:2] = qspi_oe;
endmodule


