//********************************************
//               GPIO Module
//********************************************
//
// - On reset, all GPIOs are configured as inputs, interrupts disabled, int trigger on posedge
// - Maximum GPIOs: 32
//
// GPIO Register Map:
// ┌──────────────┬─────────────┬──────────────────────────────────────────┐
// │ Address      │ Register    │ Description                              │
// ├──────────────┼─────────────┼──────────────────────────────────────────┤
// │ 0x40000000   │ rgpio_out   │ Set/reset GPIO when used as output       │
// │ 0x40000004   │ rgpio_oe    │ Enable GPIO as output                    │
// │ 0x40000008   │ rgpio_inte  │ Enable interrupts on specific GPIOs      │
// │ 0x4000000C   │ rgpio_ptrig │ Set interrupt trigger edge (1 = posedge) │
// │ 0x40000010   │ rgpio_ints  │ Interrupt status (must be cleared by SW) │
// │ 0x40000014   │ rgpio_in    │ Read GPIO value when used as input(Read-only)      
// └──────────────┴─────────────┴──────────────────────────────────────────┘

module gpio #(
    parameter gw = 32  // Number of GPIOs
)(
    input  logic            clk_i,
    input  logic            rst_ni,
    // Same interface as generic ram
    input  logic            req_i,      
    input  logic            we_i,       // Enable writing to GPIO module
    input  logic   [31:0]   addr_i,     // Register address
    input  logic   [31:0]   wdata_i,    // Write to register
    output logic   [31:0]   rdata_o,    // Read from register
    output logic            r_valid_o,  // Data ready for read
    
    input  logic   [gw-1:0] ext_pad_i,  // GPIO inputs
    output logic   [gw-1:0] ext_pad_o,  // GPIO outputs
    output logic   [gw-1:0] ext_pad_oe, // OE for bidirectional PAD
    
    output logic            int_o       // Int signal to core
);


    // GPIO registers
    reg     [gw-1:0]    rgpio_in;       // Store GPIO inputs READ ONLY reg
    reg     [gw-1:0]    rgpio_out;      // Store GPIO outputs
    reg     [gw-1:0]    rgpio_oe;       // GPIO output enable
    reg     [gw-1:0]    rgpio_inte;     // Interrupt enable
    reg     [gw-1:0]    rgpio_ptrig;    // 1 - interrupt on posedge, 0 - on negedge
    reg     [gw-1:0]    rgpio_ints;         // Interrupt status register 

    // Synchronization flops for input signals
    reg     [gw-1:0]    sync, ext_pad_s;

    // Interrupt signals
    wire    [gw-1:0]    edge_detect;
    reg     [gw-1:0]    new_interrupts;
    wire                write_to_ints;

    // Interrupt detection logic
    assign edge_detect = ((ext_pad_s^rgpio_in) &    // There was a change
                         ~(ext_pad_s^rgpio_ptrig)); // The change matches trigger edge

    // Check if request to write into rgpio_ints
    assign write_to_ints = req_i && we_i && addr_i == 32'h40000010;
    assign int_o = |rgpio_ints; // If at least one bit in rgpio_ints is high set interrupt signal for Core

    // Connect to I/O pads
    assign ext_pad_o  = rgpio_out; // Connect output register to pad output
    assign ext_pad_oe = rgpio_oe;  // Connect OE register to pad OE

    always @(posedge clk_i)begin
        if(!rst_ni)begin
            rgpio_in        <= '0;          // Reset GPIO in register
            rgpio_out       <= '0;          // Reset GPIO out reg
            rgpio_oe        <= '0;          // Set all GPIOs to Input except the last two to Out for scan chain
            rgpio_inte      <= '0;          // Disable all interrupts
            rgpio_ptrig     <= {gw{1'b1}};  // Set posedge as int trigger for all GPIOs
            rgpio_ints      <= '0;          // Reset interrupt status

            new_interrupts  <= '0;
            r_valid_o       <= 1'b0;          // Interface signal  
            rdata_o         <= '0;

            sync      <= {gw{1'b0}}; 
            ext_pad_s <= {gw{1'b0}};
        end
        else begin
            // Generate read valid signal
            r_valid_o <= req_i;

            // Input synchronization
            sync        <= ext_pad_i; 
            ext_pad_s   <= sync; 
            rgpio_in    <= ext_pad_s;

            // Interrupt status update (sticky bits, clear-on-write)
            new_interrupts  <=  rgpio_inte & edge_detect;
            rgpio_ints      <= (rgpio_ints | new_interrupts) & (write_to_ints ? wdata_i[gw-1:0] : {gw{1'b1}});

            // Bus handling
            if(req_i)begin
                if(we_i)begin
                // Write to GPIO register
                    case(addr_i)
                        32'h40000000: rgpio_out     <= wdata_i[gw-1:0];
                        32'h40000004: rgpio_oe      <= wdata_i[gw-1:0];
                        32'h40000008: rgpio_inte    <= wdata_i[gw-1:0];
                        32'h4000000C: rgpio_ptrig   <= wdata_i[gw-1:0];
                        32'h40000010:  ;// Clearing done above
                    endcase
                end
                else begin
                // Read GPIO register
                    case(addr_i)
                        32'h40000000: rdata_o <= {{(32-gw){1'b0}},  rgpio_out};
                        32'h40000004: rdata_o <= {{(32-gw){1'b0}},   rgpio_oe};
                        32'h40000008: rdata_o <= {{(32-gw){1'b0}}, rgpio_inte};
                        32'h4000000C: rdata_o <= {{(32-gw){1'b0}},rgpio_ptrig};
                        32'h40000010: rdata_o <= {{(32-gw){1'b0}}, rgpio_ints};
                        32'h40000014: rdata_o <= {{(32-gw){1'b0}},   rgpio_in};
                        default:      rdata_o <= 32'h00000000;
                    endcase
                end
            end
        end
    end
endmodule