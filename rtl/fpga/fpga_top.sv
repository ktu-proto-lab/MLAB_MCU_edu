// IOBUF skaityk cia: https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/IOBUF

module fpga_top (
    input   logic   clk_sys_Pad,
    input   logic   rst_sys_Pad,  
    inout   logic   SDA_Pad,
    inout   logic   SCL_Pad,     
    inout   logic   [`GPIO_IOS-1:0]  ext_pad
);

logic test_mode;
assign test_mode = 1'b0;

logic rst_sys_n_Pad;

// Because all buttons on BASYS3 are pull-down
assign rst_sys_n_Pad = !rst_sys_Pad;
  
logic clk_sys;

clk_div u_clk_div (
    .clk_in     (clk_sys_Pad),  // Input clock
    .rst        (rst_sys_Pad),  // Synchronous active-high reset
    .clk_out    (clk_sys)       // Output clock (clk_in divided by 2)
);


ibex_simple_system ibex_top (  // Core Top
    .clk_sys_Pad(clk_sys),
    .rst_sys_n_Pad(rst_sys_n_Pad),
    .SDA_Pad(SDA_Pad),
    .SCL_Pad(SCL_Pad),
    .ext_pad(ext_pad),
    .test_mode_Pad(test_mode)
    
);


// IBUFDS #( // Clock generavimas
//         .DIFF_TERM("FALSE"),
//         .IBUF_LOW_PWR("FALSE"),
//         .IOSTANDARD("DIFF_SSTL18_I")  
// ) sysclk_buf (
//         .O(clk_sys),
//         .I(CLOCK_P),
//         .IB(CLOCK_N)
// );

// design_1_wrapper VIO ( // RST aktyvavimas per kompa
//     .clk_0(clk_sys),
//     .probe_out0_0(rst_sys)
// );

// //assign rst_sys = RST;

endmodule
/*
Kazkodel atvirksciai
RST = 1 | VEIKIA
RST = 0 | NEVEIKIA
*/
