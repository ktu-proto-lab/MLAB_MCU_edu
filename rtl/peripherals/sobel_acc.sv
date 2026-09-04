/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
    *
    * Image Processing Accelerator - Wishbone Slave
  Description:
    * Wishbone-mapped accelerator that reads pixels one byte at a time from the
    * camera FIFO, processes them, and writes the result one byte at a time to
    * an intermediate FIFO consumed by the compression accelerator.
    *
    * Register map (word-aligned, byte offsets):
    *   0x00  CTRL        R/W  bit[0]: auto_start  - start automatically when FIFO is non-empty
    *                          bit[1]: algo_sel    - 0: inversion (default)  1: Sobel (student impl)
    *   0x04  STATUS      RO   bit[0]: busy
    *                          bit[1]: done        - High for one cycle after a frame is finished being processed
    *                          bit[2]: error       - Currently unused
    *   0x08  FRAME_COUNT RO   increments each completed frame; wraps at 2^32
    *
    *   One pixel (1 byte) is consumed from the input FIFO and one processed pixel
    *   is written to the output FIFO per clock cycle when both FIFOs are ready.
*/
module sobel_acc (
    wb_if.slave  wb,

    // Camera FIFO - source (FWFT, 8-bit, one pixel per word)
    input  logic       fifo_empty,
    input  logic [7:0] fifo_dout,
    output logic       fifo_rd_en,

    // Intermediate FIFO - destination (8-bit, one pixel per word)
    output logic       out_wr_en,
    output logic [7:0] out_din,
    input  logic       out_full
    );

    localparam int TOTAL_PIXELS = 76800; // 320 x 240

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        RUN  = 2'b01,
        DONE = 2'b10
    } state_t;

    state_t      state,           state_next;
    logic [31:0] wr_ptr,          wr_ptr_next;
    logic        ctrl_auto_start, ctrl_auto_start_next;
    logic        ctrl_algo_sel,   ctrl_algo_sel_next;
    logic        csr_busy,        csr_busy_next;
    logic        csr_done,        csr_done_next;
    logic        csr_error,       csr_error_next;
    logic [31:0] csr_frame_count, csr_frame_count_next;
    logic        wb_wr;

    // -------------------------------------------------------------------------
    // Wishbone protocol
    // -------------------------------------------------------------------------
    logic [31:0] wb_wdata;
    logic [31:0] wb_rdata;
    reg [7:0] rows [0:1][0:319]; //bitu memory triju eiliu
    reg [7:0] running [0:2];  //running window
    logic signed [11:0] Gx;
    logic signed [11:0] Gy;
    logic [31:0] kiekis;
    logic fifo_rd_en_delay;

`ifdef NO_MODPORT_EXPRESSIONS
    assign wb_wdata = wb.dat_m;
    assign wb.dat_s = wb_rdata;
`else
    assign wb_wdata = wb.dat_i;
    assign wb.dat_o = wb_rdata;
`endif

    assign wb.stall = 1'b0;
    assign wb.err   = 1'b0;

    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst)
            wb.ack <= 1'b0;
        else
            wb.ack <= wb.cyc & wb.stb & ~wb.stall;
    end

    // -------------------------------------------------------------------------
    // Combinational helpers
    // -------------------------------------------------------------------------

    assign wb_wr = wb.cyc & wb.stb & wb.we & ~wb.stall;

    // Consume from input FIFO only when we can simultaneously write to output FIFO.
    assign fifo_rd_en = (state == RUN) && !fifo_empty && !out_full;

    // -------------------------------------------------------------------------
    // Wishbone read mux (purely combinational)
    // -------------------------------------------------------------------------
    always_comb begin
        case (wb.adr[3:2])
            2'h0:    wb_rdata = {30'h0, ctrl_algo_sel, ctrl_auto_start};
            2'h1:    wb_rdata = {29'h0, csr_error, csr_done, csr_busy};
            2'h2:    wb_rdata = csr_frame_count;
            default: wb_rdata = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM registers
    // -------------------------------------------------------------------------
    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) begin
            state           <= IDLE;
            wr_ptr          <= 32'h0;
            ctrl_auto_start <= 1'b0;
            ctrl_algo_sel   <= 1'b0;
            csr_busy        <= 1'b0;
            csr_done        <= 1'b0;
            csr_error       <= 1'b0;
            csr_frame_count <= 32'h0;
        end else begin
            state           <= state_next;
            wr_ptr          <= wr_ptr_next;
            ctrl_auto_start <= ctrl_auto_start_next;
            ctrl_algo_sel   <= ctrl_algo_sel_next;
            csr_busy        <= csr_busy_next;
            csr_done        <= csr_done_next;
            csr_error       <= csr_error_next;
            csr_frame_count <= csr_frame_count_next;
        end
    end



    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) begin
            kiekis <= 0;
            fifo_rd_en_delay <= 0;
        end else if(fifo_rd_en) begin
            if(kiekis <= 643) begin //buvo 640 su skewinta versija
                rows[kiekis/320][kiekis % 320] <= fifo_dout;
                running[kiekis - 641] <= fifo_dout; //bulshit bet gal veiks (sitos line nera kitoj versijoj)
                kiekis <= kiekis + 1;
            end
            //else if(kiekis <= 643) begin
            //  running[kiekis - 641] <= fifo_dout;
            //  kiekis <= kiekis + 1;
            //end
             else begin
                rows[0][kiekis%320-1] <= rows[1][kiekis%320-1]; //keiciam pikselius vviena stulpeli po kito
                //rows[1][kiekis%320-1] <= rows[2][kiekis%320-1];
                //rows[2][kiekis%320-1] <= fifo_dout;
                
                rows[1][kiekis%320-1] <= running[0];
                running[0] <= running[1];
                running[1] <= running[2];
                running[2] <= fifo_dout;
                kiekis <= kiekis+1;


            end
        end
 
    end


   
    // -------------------------------------------------------------------------
    // FSM combinational
    // -------------------------------------------------------------------------
    always_comb begin
        // Defaults
        state_next           = state;
        wr_ptr_next          = wr_ptr;
        ctrl_auto_start_next = ctrl_auto_start;
        ctrl_algo_sel_next   = ctrl_algo_sel; 
        csr_busy_next        = csr_busy;
        csr_done_next        = csr_done;
        csr_error_next       = csr_error;
        csr_frame_count_next = csr_frame_count;

        // Combinational output defaults
        out_wr_en = 1'b0;
        out_din   = 8'h0;
        
        // CPU write to CTRL register: update config bits, clear done
        if (wb_wr && wb.adr[3:2] == 2'h0) begin
            ctrl_auto_start_next = wb_wdata[0];
            ctrl_algo_sel_next   = wb_wdata[1];
            csr_done_next        = 1'b0;
        end

        case (state)
            // -----------------------------------------------------------------
            IDLE: begin
                if (ctrl_auto_start && !fifo_empty) begin
                    csr_done_next        = 1'b0;
                    csr_error_next       = 1'b0;
                    csr_busy_next        = 1'b1;
                    wr_ptr_next          = 32'h0;
                    state_next           = RUN;
                end
            end

            // -----------------------------------------------------------------
            // FWFT FIFO: fifo_dout is valid whenever fifo_empty=0.
            // Stall when either FIFO is not ready (fifo_rd_en handles both).
            RUN: begin
                if (!fifo_empty && !out_full) begin
                    out_wr_en = 1'b0;
                    // algo_sel=0: inversion   algo_sel=1: STUDENT SOBEL HERE
                    
                    if(~ctrl_algo_sel) begin //Sobelio algoritmas

                        //if(kiekis != 960)begin //ziurim ar trys eilutes uzpildyto
                            //rows[kiekis/320][kiekis % 320] = fifo_dout;
                            //kiekis = kiekis + 1;
                        //end else
                        if(kiekis%320 > 0 && kiekis%320 < 319 && kiekis > 643) begin //Pats sobelio skaiciavimas
                            
                            //Gx = rows[0][kiekis%320+1] + (rows[1][kiekis%320+1]<<1) + rows[2][kiekis%320+1] - rows[0][kiekis%320-1] - (rows[1][kiekis%320-1]<<1) - rows[2][kiekis%320-1];
                            //Gy = rows[0][kiekis%320-1] + (rows[0][kiekis%320]<<1) + rows[0][kiekis%320+1] - rows[2][kiekis%320-1] - (rows[2][kiekis%320]<<1) - rows[2][kiekis%320+1];

                            Gx = rows[0][kiekis%320+1] + (rows[1][kiekis%320+1]<<1) + running[2] - rows[0][kiekis%320-1] - (rows[1][kiekis%320-1]<<1) - running[0];
                            Gy = rows[0][kiekis%320-1] + (rows[0][kiekis%320]<<1) + rows[0][kiekis%320+1] - running[0] - (running[1]<<1) - running[2];

                            out_din = (((Gx < 0) ? -Gx : Gx) + ((Gy < 0) ? -Gy : Gy) > 255 ? 255 : ((Gx < 0) ? -Gx : Gx) + ((Gy < 0) ? -Gy : Gy));

                            out_wr_en = 1'b1;
                            

                        end else if (kiekis%320 == 0 || kiekis%320 == 319 || kiekis < 322) begin //for some reason turiu kompensuot 5 ciklus laikrodzio

                            //Gx = 0;
                            //Gy = 0;
                            
                            out_din = 100;
                            out_wr_en = 1'b1;
                            

                        end

                    end else begin 
                        out_din = fifo_dout;
                    end


                    wr_ptr_next = wr_ptr + 32'h1;



                    if (wr_ptr + 32'h1 >= TOTAL_PIXELS) begin
                        csr_busy_next        = 1'b0;
                        csr_done_next        = 1'b1;
                        csr_frame_count_next = csr_frame_count + 32'h1;
                        state_next           = DONE;
                    end
                end
            end

            // -----------------------------------------------------------------
            DONE: begin
                // If auto_start jump straight into RUN state for the next frame
                if (ctrl_auto_start && !fifo_empty) begin
                    csr_done_next        = 1'b0;
                    csr_error_next       = 1'b0;
                    csr_busy_next        = 1'b1;
                    wr_ptr_next          = 32'h0;
                    state_next           = RUN;
                end else begin
                    state_next = IDLE;
                end
            end

            default: state_next = IDLE;
        endcase
    end
endmodule
