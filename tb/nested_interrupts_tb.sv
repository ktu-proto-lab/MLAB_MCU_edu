`include "project_defs.svh"
`include "../../tb/misc/tb.v"

// Nested-Interrupt parameters.
parameter program_folder="test/nested_interrupts";
// 8 GPIO outputs mean succesfull test pass.
integer expected_ext_pad_io = 12'b0000_1111_1111;
reg gpio_intrq_fired = 1'b0;

module simple_system_tb;
// Parameters
parameter GPIO_COUNT = `GPIO_IOS;
parameter CLK_PERIOD = 12.5;
// Two dirs up, because current dir is in sim/<postpnr or postsyn or rtl> (look at root/script/xrun_sim_run.sh file).
parameter MEMInitFile = {"../../sw/ibex/", program_folder, "/build/verilog_hex.v"};
`ifdef LOG_OUTPUT
// Output file of the tb info.
parameter file="../../tb/log/nested_interrupts.log";
// Output file descriptor.
int fd;
`endif

logic clk_sys, rst_sys_n, test_mode;
assign test_mode = 1'b0;

// GPIO signals
logic [GPIO_COUNT-1:0] ext_pad_i;
logic [GPIO_COUNT-1:0] ext_pad_o;
logic [GPIO_COUNT-1:0] ext_pad_oe;
wire [GPIO_COUNT-1:0] ext_pad_io;

// Testbench driven GPIO control
logic [GPIO_COUNT-1:0] input_val;
logic [GPIO_COUNT-1:0] output_value;
logic out_valid;

// I2C signals
logic i2c_int;

// I2C signals
wire SDA, SCL;

    // Instantiate DUT
    ibex_simple_system dut 
    (
        .clk_sys_Pad    (clk_sys),
        .rst_sys_n_Pad  (rst_sys_n),  
        .SDA_Pad        (SDA),
        .SCL_Pad        (SCL),
        .ext_pad        (ext_pad_io),
        .test_mode_Pad      (test_mode)
    );

// Instantiate external EEPROM
M24CS512 #(
.MEMInitFile(MEMInitFile)
) eeprom (
.A0 (1'b0),
.A1 (1'b0),
.A2 (1'b0),
.WP (1'b0), // No write protect
.SDA (SDA),
.SCL (SCL),
.RESET (1'b0) // Reset without internal function
);

// Clock generation
always begin
#(CLK_PERIOD / 2) clk_sys = ~clk_sys;
end

// GPIO inout signal control
assign input_val = ext_pad_io;
assign ext_pad_io = out_valid ? output_value : 'hZ;
// Add pull-down resistors for inout signal
genvar j;
generate
for(j=0; j<GPIO_COUNT; j++)begin
pulldown(ext_pad_io[j]);
end
endgenerate

// Pull-up on I2C lines
pullup(SDA);
pullup(SCL);

initial begin
`ifdef LOG_OUTPUT
// Open output file with write permission.
fd = $fopen ( file, "w");
if (fd)  begin
  $display("[SUCCESS]: log output file '%s' opened succesfully", file);
  $fwrite(fd, "[   FLAG]: LOG_OUT_INIT\n");
end else begin
  $display("[   FAIL]: log output file was not opened successfully: %0d", fd);
end
`endif

// Add delay to let scan_en propagate, this is so we don't get $setup timing violations for postpnr 
// SDF annotated simulation
#(CLK_PERIOD*1)

// Initial top signal values
rst_sys_n = 1'b0;
clk_sys = 1'b0;
out_valid = 0;

#(CLK_PERIOD*4)
rst_sys_n = 1'b1;

tb.wait_bootloader;
tb.memory_write_back_test;

//==================================================
// Simulated External Event
//==================================================
#5_000_000 // Wait 5 ms more
// Set GPIO0
out_valid = 1;
output_value = 1 << 0;
#1000;
// Reset GPIO0
out_valid = 0;
gpio_intrq_fired = 1;
// Wait for the nested interrupts to complete
#10_000_000;
if (ext_pad_io == expected_ext_pad_io) begin
  $display("[SUCCESS]: All 8 stages of the test are passed: expected GPIO values = %012b, received = %012b", expected_ext_pad_io, ext_pad_io);
`ifdef LOG_OUTPUT
  $fwrite(fd, "[SUCCESS]: All 8 stages of the test are passed: expected GPIO values = %012b, received = %012b\n", expected_ext_pad_io, ext_pad_io);
  $fwrite(fd, "[   FLAG]: TEST_SUCCESS\n");
`endif
end else begin
  $display("[   FAIL]: Not all stages of the test are passed expected GPIO output: %012b, received: %012b", expected_ext_pad_io, ext_pad_io);
`ifdef LOG_OUTPUT
  $fwrite(fd, "[   FAIL]: Not all stages of the test are passed expected GPIO output: %012b, received: %012b\n", expected_ext_pad_io, ext_pad_io);
  $fwrite(fd, "[   FLAG]: TEST_FAIL\n");
`endif
end
`ifdef LOG_OUTPUT
// Close log output file.
$fclose(fd);
`endif
$finish();
end

always @(posedge ext_pad_io[0]) begin
  if (gpio_intrq_fired) begin
    if (ext_pad_io[0]) begin
      $display("[SUCCESS]: test stage 0: GPIO pad 0 interrupt request acknowledged, GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
      $fwrite(fd, "[SUCCESS]: test stage 0: GPIO pad 0 interrupt request acknowledged, GPIO_PINS = %012b\n", ext_pad_io);
`endif
    end else begin
      $display("[   FAIL]: test stage 0: GPIO interrupt acknowledgement, expected GPIO_PIN_0 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
      $fwrite(fd, "[   FAIL]: test stage 0: GPIO interrupt acknowledgement, expected GPIO_PIN_0 to be enabled, received = %012b\n", ext_pad_io);
`endif
    end
  end
end

always @(posedge ext_pad_io[1]) begin
  if (ext_pad_io[1]) begin
    $display("[SUCCESS]: test stage 1: I2C transmit to EEPROM called, GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[SUCCESS]: test stage 1: I2C transmit to EEPROM called, GPIO_PINS = %012b\n", ext_pad_io);
`endif
  end else begin
    $display("[   FAIL]: test stage 1: calling I2C transmit to EEPROM, expected GPIO_PIN_1 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[   FAIL]: test stage 1: calling I2C transmit to EEPROM, expected GPIO_PIN_1 to be enabled, received = %012b\n", ext_pad_io);
`endif
  end
end

always @(posedge ext_pad_io[2]) begin
  if (ext_pad_io[2]) begin
    $display("[SUCCESS]: test stage 2: I2C transmit to EEPROM completed, GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[SUCCESS]: test stage 2: I2C transmit to EEPROM completed, GPIO_PINS = %012b\n", ext_pad_io);
`endif
  end else begin
    $display("[   FAIL]: test stage 2: I2C transmit to EEPROM completion, expected GPIO_PIN_2 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[   FAIL]: test stage 2: I2C transmit to EEPROM completion, expected GPIO_PIN_2 to be enabled, received = %012b\n", ext_pad_io);
`endif
  end
end

always @(posedge ext_pad_io[3]) begin
  if (ext_pad_io[3]) begin
    $display("[SUCCESS]: test stage 3: I2C receive completed, GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[SUCCESS]: test stage 3: I2C receive completed, GPIO_PINS = %012b\n", ext_pad_io);
`endif
  end else begin
    $display("[   FAIL]: test stage 3: I2C receive completion, expected GPIO_PIN_3 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[   FAIL]: test stage 3: I2C receive completion, expected GPIO_PIN_3 to be enabled, received = %012b\n", ext_pad_io);
`endif
  end
end

always @(posedge ext_pad_io[4]) begin
  if (ext_pad_io[4]) begin
    $display("[SUCCESS]: test stage 4: I2C transmit-receive buffer data is matching, GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[SUCCESS]: test stage 4: I2C transmit-receive buffer data is matching, GPIO_PINS = %012b\n", ext_pad_io);
`endif
  end else begin
    $display("[   FAIL]: test stage 4: I2C transmit-receive buffer data check, expected GPIO_PIN_4 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[   FAIL]: test stage 4: I2C transmit-receive buffer data check, expected GPIO_PIN_4 to be enabled, received = %012b\n", ext_pad_io);
`endif
  end
end

always @(posedge ext_pad_io[5]) begin
  if (ext_pad_io[5]) begin
    $display("[SUCCESS]: test stage 5: GPIO handler callback exit (I2C both acknowledgements received), GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[SUCCESS]: test stage 5: GPIO handler callback exit (I2C both acknowledgements received), GPIO_PINS = %012b\n", ext_pad_io);
`endif
  end else begin
    $display("[   FAIL]: test stage 5: GPIO handler callback exit (I2C both acknowledgements received), expected GPIO_PIN_5 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[   FAIL]: test stage 5: GPIO handler callback exit (I2C both acknowledgements received), expected GPIO_PIN_5 to be enabled, received = %012b\n", ext_pad_io);
`endif
  end
end

always @(posedge ext_pad_io[6]) begin
  if (ext_pad_io[6]) begin
    $display("[SUCCESS]: test stage 6: Timer handler callback exit (GPIO acknowledgement received), GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[SUCCESS]: test stage 6: Timer handler callback exit (GPIO acknowledgement received), GPIO_PINS = %012b\n", ext_pad_io);
`endif
  end else begin
    $display("[   FAIL]: test stage 6: Timer handler callback exit (GPIO acknowledgement received), expected GPIO_PIN_6 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[   FAIL]: test stage 6: Timer handler callback exit (GPIO acknowledgement received), expected GPIO_PIN_6 to be enabled, received = %012b\n", ext_pad_io);
`endif
  end
end

always @(posedge ext_pad_io[7]) begin
  if (ext_pad_io[7]) begin
    $display("[SUCCESS]: test stage 7: all nested interrupt stages passed successfully, GPIO_PINS = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[SUCCESS]: test stage 7: all nested interrupt stages passed successfully, GPIO_PINS = %012b\n", ext_pad_io);
`endif
  end else begin
    $display("[   FAIL]: test stage 7: all nested interrupt stages passing successfully, expected GPIO_PIN_7 to be enabled, received = %012b", ext_pad_io);
`ifdef LOG_OUTPUT
    $fwrite(fd, "[   FAIL]: test stage 7: all nested interrupt stages passing successfully, expected GPIO_PIN_7 to be enabled, received = %012b\n", ext_pad_io);
`endif
  end
end

`ifdef SDF
    // SDF annotate (Add real delays) for post pnr sim
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif
endmodule
