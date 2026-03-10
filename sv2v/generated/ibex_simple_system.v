module prim_buf (
	in_i,
	out_o
);
	parameter signed [31:0] Width = 1;
	input [Width - 1:0] in_i;
	output wire [Width - 1:0] out_o;
	generate
		if (1) begin : gen_generic
			prim_generic_buf #(.Width(Width)) u_impl_generic(
				.in_i(in_i),
				.out_o(out_o)
			);
		end
	endgenerate
endmodule
module prim_generic_buf (
	in_i,
	out_o
);
	parameter signed [31:0] Width = 1;
	input [Width - 1:0] in_i;
	output wire [Width - 1:0] out_o;
	wire [Width - 1:0] inv;
	assign inv = ~in_i;
	assign out_o = ~inv;
endmodule
module ibex_wb_stage (
	clk_i,
	rst_ni,
	en_wb_i,
	instr_type_wb_i,
	pc_id_i,
	instr_is_compressed_id_i,
	instr_perf_count_id_i,
	ready_wb_o,
	rf_write_wb_o,
	outstanding_load_wb_o,
	outstanding_store_wb_o,
	pc_wb_o,
	perf_instr_ret_wb_o,
	perf_instr_ret_compressed_wb_o,
	perf_instr_ret_wb_spec_o,
	perf_instr_ret_compressed_wb_spec_o,
	rf_waddr_id_i,
	rf_wdata_id_i,
	rf_we_id_i,
	dummy_instr_id_i,
	rf_wdata_lsu_i,
	rf_we_lsu_i,
	rf_wdata_fwd_wb_o,
	rf_waddr_wb_o,
	rf_wdata_wb_o,
	rf_we_wb_o,
	dummy_instr_wb_o,
	lsu_resp_valid_i,
	lsu_resp_err_i,
	instr_done_wb_o
);
	parameter [0:0] ResetAll = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire en_wb_i;
	input wire [1:0] instr_type_wb_i;
	input wire [31:0] pc_id_i;
	input wire instr_is_compressed_id_i;
	input wire instr_perf_count_id_i;
	output wire ready_wb_o;
	output wire rf_write_wb_o;
	output wire outstanding_load_wb_o;
	output wire outstanding_store_wb_o;
	output wire [31:0] pc_wb_o;
	output wire perf_instr_ret_wb_o;
	output wire perf_instr_ret_compressed_wb_o;
	output wire perf_instr_ret_wb_spec_o;
	output wire perf_instr_ret_compressed_wb_spec_o;
	input wire [4:0] rf_waddr_id_i;
	input wire [31:0] rf_wdata_id_i;
	input wire rf_we_id_i;
	input wire dummy_instr_id_i;
	input wire [31:0] rf_wdata_lsu_i;
	input wire rf_we_lsu_i;
	output wire [31:0] rf_wdata_fwd_wb_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire [31:0] rf_wdata_wb_o;
	output wire rf_we_wb_o;
	output wire dummy_instr_wb_o;
	input wire lsu_resp_valid_i;
	input wire lsu_resp_err_i;
	output wire instr_done_wb_o;
	wire [31:0] rf_wdata_wb_mux [0:1];
	wire [1:0] rf_wdata_wb_mux_we;
	generate
		if (WritebackStage) begin : g_writeback_stage
			reg [31:0] rf_wdata_wb_q;
			reg rf_we_wb_q;
			reg [4:0] rf_waddr_wb_q;
			wire wb_done;
			reg wb_valid_q;
			reg [31:0] wb_pc_q;
			reg wb_compressed_q;
			reg wb_count_q;
			reg [1:0] wb_instr_type_q;
			wire wb_valid_d;
			assign wb_valid_d = (en_wb_i & ready_wb_o) | (wb_valid_q & ~wb_done);
			assign wb_done = (wb_instr_type_q == 2'd2) | lsu_resp_valid_i;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					wb_valid_q <= 1'b0;
				else
					wb_valid_q <= wb_valid_d;
			if (ResetAll) begin : g_wb_regs_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						rf_we_wb_q <= 1'sb0;
						rf_waddr_wb_q <= 1'sb0;
						rf_wdata_wb_q <= 1'sb0;
						wb_instr_type_q <= 2'd0;
						wb_pc_q <= 1'sb0;
						wb_compressed_q <= 1'sb0;
						wb_count_q <= 1'sb0;
					end
					else if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
					end
			end
			else begin : g_wb_regs_nr
				always @(posedge clk_i)
					if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
					end
			end
			assign rf_waddr_wb_o = rf_waddr_wb_q;
			assign rf_wdata_wb_mux[0] = rf_wdata_wb_q;
			assign rf_wdata_wb_mux_we[0] = rf_we_wb_q & wb_valid_q;
			assign ready_wb_o = ~wb_valid_q | wb_done;
			assign rf_write_wb_o = wb_valid_q & (rf_we_wb_q | (wb_instr_type_q == 2'd0));
			assign outstanding_load_wb_o = wb_valid_q & (wb_instr_type_q == 2'd0);
			assign outstanding_store_wb_o = wb_valid_q & (wb_instr_type_q == 2'd1);
			assign pc_wb_o = wb_pc_q;
			assign instr_done_wb_o = wb_valid_q & wb_done;
			assign perf_instr_ret_wb_spec_o = wb_count_q;
			assign perf_instr_ret_compressed_wb_spec_o = perf_instr_ret_wb_spec_o & wb_compressed_q;
			assign perf_instr_ret_wb_o = (instr_done_wb_o & wb_count_q) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & wb_compressed_q;
			assign rf_wdata_fwd_wb_o = rf_wdata_wb_q;
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			if (DummyInstructions) begin : g_dummy_instr_wb
				reg dummy_instr_wb_q;
				if (ResetAll) begin : g_dummy_instr_wb_regs_ra
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							dummy_instr_wb_q <= 1'b0;
						else if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				else begin : g_dummy_instr_wb_regs_nr
					always @(posedge clk_i)
						if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				assign dummy_instr_wb_o = dummy_instr_wb_q;
			end
			else begin : g_no_dummy_instr_wb
				wire unused_dummy_instr_id;
				assign unused_dummy_instr_id = dummy_instr_id_i;
				assign dummy_instr_wb_o = 1'b0;
			end
		end
		else begin : g_bypass_wb
			assign rf_waddr_wb_o = rf_waddr_id_i;
			assign rf_wdata_wb_mux[0] = rf_wdata_id_i;
			assign rf_wdata_wb_mux_we[0] = rf_we_id_i;
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			assign dummy_instr_wb_o = dummy_instr_id_i;
			assign perf_instr_ret_wb_spec_o = 1'b0;
			assign perf_instr_ret_compressed_wb_spec_o = 1'b0;
			assign perf_instr_ret_wb_o = (instr_perf_count_id_i & en_wb_i) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & instr_is_compressed_id_i;
			assign ready_wb_o = 1'b1;
			wire unused_clk;
			wire unused_rst;
			wire [1:0] unused_instr_type_wb;
			wire [31:0] unused_pc_id;
			wire unused_dummy_instr_id;
			assign unused_clk = clk_i;
			assign unused_rst = rst_ni;
			assign unused_instr_type_wb = instr_type_wb_i;
			assign unused_pc_id = pc_id_i;
			assign unused_dummy_instr_id = dummy_instr_id_i;
			assign outstanding_load_wb_o = 1'b0;
			assign outstanding_store_wb_o = 1'b0;
			assign pc_wb_o = 1'sb0;
			assign rf_write_wb_o = 1'b0;
			assign rf_wdata_fwd_wb_o = 32'b00000000000000000000000000000000;
			assign instr_done_wb_o = 1'b0;
		end
	endgenerate
	assign rf_wdata_wb_mux[1] = rf_wdata_lsu_i;
	assign rf_wdata_wb_o = ({32 {rf_wdata_wb_mux_we[0]}} & rf_wdata_wb_mux[0]) | ({32 {rf_wdata_wb_mux_we[1]}} & rf_wdata_wb_mux[1]);
	assign rf_we_wb_o = |rf_wdata_wb_mux_we;
endmodule
module ibex_core (
	clk_i,
	rst_ni,
	hart_id_i,
	boot_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_rdata_i,
	data_err_i,
	dummy_instr_id_o,
	dummy_instr_wb_o,
	rf_raddr_a_o,
	rf_raddr_b_o,
	rf_waddr_wb_o,
	rf_we_wb_o,
	rf_wdata_wb_ecc_o,
	rf_rdata_a_ecc_i,
	rf_rdata_b_ecc_i,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	irq_pending_o,
	debug_req_i,
	crash_dump_o,
	double_fault_seen_o,
	fetch_enable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_busy_o
);
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] RegFileECC = 1'b0;
	parameter [31:0] RegFileDataWidth = 32;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_err_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_err_i;
	output wire dummy_instr_id_o;
	output wire dummy_instr_wb_o;
	output wire [4:0] rf_raddr_a_o;
	output wire [4:0] rf_raddr_b_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire rf_we_wb_o;
	output wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc_o;
	input wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_i;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output wire ic_scr_key_req_o;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	output wire irq_pending_o;
	input wire debug_req_i;
	output wire [159:0] crash_dump_o;
	output wire double_fault_seen_o;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] fetch_enable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	output wire [3:0] core_busy_o;
	localparam [31:0] PMPNumChan = 3;
	localparam [0:0] DataIndTiming = SecureIbex;
	localparam [0:0] PCIncrCheck = SecureIbex;
	localparam [0:0] ShadowCSR = 1'b0;
	wire dummy_instr_id;
	wire instr_valid_id;
	wire instr_new_id;
	wire [31:0] instr_rdata_id;
	wire [31:0] instr_rdata_alu_id;
	wire [15:0] instr_rdata_c_id;
	wire instr_is_compressed_id;
	wire instr_perf_count_id;
	wire instr_bp_taken_id;
	wire instr_fetch_err;
	wire instr_fetch_err_plus2;
	wire illegal_c_insn_id;
	wire [31:0] pc_if;
	wire [31:0] pc_id;
	wire [31:0] pc_wb;
	wire [67:0] imd_val_d_ex;
	wire [67:0] imd_val_q_ex;
	wire [1:0] imd_val_we_ex;
	wire data_ind_timing;
	wire dummy_instr_en;
	wire [2:0] dummy_instr_mask;
	wire dummy_instr_seed_en;
	wire [31:0] dummy_instr_seed;
	wire icache_enable;
	wire icache_inval;
	wire icache_ecc_error;
	wire pc_mismatch_alert;
	wire csr_shadow_err;
	wire instr_first_cycle_id;
	wire instr_valid_clear;
	wire pc_set;
	wire nt_branch_mispredict;
	wire [31:0] nt_branch_addr;
	wire [2:0] pc_mux_id;
	wire [1:0] exc_pc_mux_id;
	wire [6:0] exc_cause;
	wire instr_intg_err;
	wire lsu_load_err;
	wire lsu_load_err_raw;
	wire lsu_store_err;
	wire lsu_store_err_raw;
	wire lsu_load_resp_intg_err;
	wire lsu_store_resp_intg_err;
	wire expecting_load_resp_id;
	wire expecting_store_resp_id;
	wire lsu_addr_incr_req;
	wire [31:0] lsu_addr_last;
	wire [31:0] branch_target_ex;
	wire branch_decision;
	wire ctrl_busy;
	wire if_busy;
	wire lsu_busy;
	wire [4:0] rf_raddr_a;
	wire [31:0] rf_rdata_a;
	wire [4:0] rf_raddr_b;
	wire [31:0] rf_rdata_b;
	wire rf_ren_a;
	wire rf_ren_b;
	wire [4:0] rf_waddr_wb;
	wire [31:0] rf_wdata_wb;
	wire [31:0] rf_wdata_fwd_wb;
	wire [31:0] rf_wdata_lsu;
	wire rf_we_wb;
	wire rf_we_lsu;
	wire rf_ecc_err_comb;
	wire [4:0] rf_waddr_id;
	wire [31:0] rf_wdata_id;
	wire rf_we_id;
	wire rf_rd_a_wb_match;
	wire rf_rd_b_wb_match;
	wire [6:0] alu_operator_ex;
	wire [31:0] alu_operand_a_ex;
	wire [31:0] alu_operand_b_ex;
	wire [31:0] bt_a_operand;
	wire [31:0] bt_b_operand;
	wire [31:0] alu_adder_result_ex;
	wire [31:0] result_ex;
	wire mult_en_ex;
	wire div_en_ex;
	wire mult_sel_ex;
	wire div_sel_ex;
	wire [1:0] multdiv_operator_ex;
	wire [1:0] multdiv_signed_mode_ex;
	wire [31:0] multdiv_operand_a_ex;
	wire [31:0] multdiv_operand_b_ex;
	wire multdiv_ready_id;
	wire csr_access;
	wire [1:0] csr_op;
	wire csr_op_en;
	wire [11:0] csr_addr;
	wire [31:0] csr_rdata;
	wire [31:0] csr_wdata;
	wire illegal_csr_insn_id;
	wire lsu_we;
	wire [1:0] lsu_type;
	wire lsu_sign_ext;
	wire lsu_req;
	wire lsu_rdata_valid;
	wire [31:0] lsu_wdata;
	wire lsu_req_done;
	wire id_in_ready;
	wire ex_valid;
	wire lsu_resp_valid;
	wire lsu_resp_err;
	wire instr_req_int;
	wire instr_req_gated;
	wire instr_exec;
	wire en_wb;
	wire [1:0] instr_type_wb;
	wire ready_wb;
	wire rf_write_wb;
	wire outstanding_load_wb;
	wire outstanding_store_wb;
	wire dummy_instr_wb;
	wire nmi_mode;
	wire [17:0] irqs;
	wire csr_mstatus_mie;
	wire [31:0] csr_mepc;
	wire [31:0] csr_depc;
	wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr;
	wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg;
	wire [2:0] csr_pmp_mseccfg;
	wire [0:2] pmp_req_err;
	wire data_req_out;
	wire csr_save_if;
	wire csr_save_id;
	wire csr_save_wb;
	wire csr_restore_mret_id;
	wire csr_restore_dret_id;
	wire csr_save_cause;
	wire csr_mtvec_init;
	wire [31:0] csr_mtvec;
	wire [31:0] csr_mtval;
	wire csr_mstatus_tw;
	wire [1:0] priv_mode_id;
	wire [1:0] priv_mode_lsu;
	wire debug_mode;
	wire debug_mode_entering;
	wire [2:0] debug_cause;
	wire debug_csr_save;
	wire debug_single_step;
	wire debug_ebreakm;
	wire debug_ebreaku;
	wire trigger_match;
	wire instr_id_done;
	wire instr_done_wb;
	wire perf_instr_ret_wb;
	wire perf_instr_ret_compressed_wb;
	wire perf_instr_ret_wb_spec;
	wire perf_instr_ret_compressed_wb_spec;
	wire perf_iside_wait;
	wire perf_dside_wait;
	wire perf_mul_wait;
	wire perf_div_wait;
	wire perf_jump;
	wire perf_branch;
	wire perf_tbranch;
	wire perf_load;
	wire perf_store;
	wire illegal_insn_id;
	wire unused_illegal_insn_id;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	generate
		if (SecureIbex) begin : g_core_busy_secure
			localparam [31:0] NumBusySignals = 3;
			localparam [31:0] NumBusyBits = ibex_pkg_IbexMuBiWidth * NumBusySignals;
			wire [NumBusyBits - 1:0] busy_bits_buf;
			prim_buf #(.Width(NumBusyBits)) u_fetch_enable_buf(
				.in_i({ibex_pkg_IbexMuBiWidth {ctrl_busy, if_busy, lsu_busy}}),
				.out_o(busy_bits_buf)
			);
			genvar _gv_i_1;
			for (_gv_i_1 = 0; _gv_i_1 < ibex_pkg_IbexMuBiWidth; _gv_i_1 = _gv_i_1 + 1) begin : g_core_busy_bits
				localparam i = _gv_i_1;
				if (ibex_pkg_IbexMuBiOn[i] == 1'b1) begin : g_pos
					assign core_busy_o[i] = |busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
				else begin : g_neg
					assign core_busy_o[i] = ~|busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
			end
		end
		else begin : g_core_busy_non_secure
			assign core_busy_o = ((ctrl_busy || if_busy) || lsu_busy ? ibex_pkg_IbexMuBiOn : ibex_pkg_IbexMuBiOff);
		end
	endgenerate
	localparam [31:0] ibex_pkg_PMP_I = 0;
	localparam [31:0] ibex_pkg_PMP_I2 = 1;
	ibex_if_stage #(
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr),
		.DummyInstructions(DummyInstructions),
		.ICache(ICache),
		.ICacheECC(ICacheECC),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.PCIncrCheck(PCIncrCheck),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth)
	) if_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.boot_addr_i(boot_addr_i),
		.req_i(instr_req_gated),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.instr_bus_err_i(instr_err_i),
		.instr_intg_err_o(instr_intg_err),
		.ic_tag_req_o(ic_tag_req_o),
		.ic_tag_write_o(ic_tag_write_o),
		.ic_tag_addr_o(ic_tag_addr_o),
		.ic_tag_wdata_o(ic_tag_wdata_o),
		.ic_tag_rdata_i(ic_tag_rdata_i),
		.ic_data_req_o(ic_data_req_o),
		.ic_data_write_o(ic_data_write_o),
		.ic_data_addr_o(ic_data_addr_o),
		.ic_data_wdata_o(ic_data_wdata_o),
		.ic_data_rdata_i(ic_data_rdata_i),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.ic_scr_key_req_o(ic_scr_key_req_o),
		.instr_valid_id_o(instr_valid_id),
		.instr_new_id_o(instr_new_id),
		.instr_rdata_id_o(instr_rdata_id),
		.instr_rdata_alu_id_o(instr_rdata_alu_id),
		.instr_rdata_c_id_o(instr_rdata_c_id),
		.instr_is_compressed_id_o(instr_is_compressed_id),
		.instr_bp_taken_o(instr_bp_taken_id),
		.instr_fetch_err_o(instr_fetch_err),
		.instr_fetch_err_plus2_o(instr_fetch_err_plus2),
		.illegal_c_insn_id_o(illegal_c_insn_id),
		.dummy_instr_id_o(dummy_instr_id),
		.pc_if_o(pc_if),
		.pc_id_o(pc_id),
		.pmp_err_if_i(pmp_req_err[ibex_pkg_PMP_I]),
		.pmp_err_if_plus2_i(pmp_req_err[ibex_pkg_PMP_I2]),
		.instr_valid_clear_i(instr_valid_clear),
		.pc_set_i(pc_set),
		.pc_mux_i(pc_mux_id),
		.nt_branch_mispredict_i(nt_branch_mispredict),
		.exc_pc_mux_i(exc_pc_mux_id),
		.exc_cause(exc_cause),
		.dummy_instr_en_i(dummy_instr_en),
		.dummy_instr_mask_i(dummy_instr_mask),
		.dummy_instr_seed_en_i(dummy_instr_seed_en),
		.dummy_instr_seed_i(dummy_instr_seed),
		.icache_enable_i(icache_enable),
		.icache_inval_i(icache_inval),
		.icache_ecc_error_o(icache_ecc_error),
		.branch_target_ex_i(branch_target_ex),
		.nt_branch_addr_i(nt_branch_addr),
		.csr_mepc_i(csr_mepc),
		.csr_depc_i(csr_depc),
		.csr_mtvec_i(csr_mtvec),
		.csr_mtvec_init_o(csr_mtvec_init),
		.id_in_ready_i(id_in_ready),
		.pc_mismatch_alert_o(pc_mismatch_alert),
		.if_busy_o(if_busy)
	);
	assign perf_iside_wait = id_in_ready & ~instr_valid_id;
	generate
		if (SecureIbex) begin : g_instr_req_gated_secure
			assign instr_req_gated = instr_req_int & (fetch_enable_i == ibex_pkg_IbexMuBiOn);
			assign instr_exec = fetch_enable_i == ibex_pkg_IbexMuBiOn;
		end
		else begin : g_instr_req_gated_non_secure
			wire unused_fetch_enable;
			assign unused_fetch_enable = ^fetch_enable_i[3:1];
			assign instr_req_gated = instr_req_int & fetch_enable_i[0];
			assign instr_exec = fetch_enable_i[0];
		end
	endgenerate
	ibex_id_stage #(
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.DataIndTiming(DataIndTiming),
		.WritebackStage(WritebackStage),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC)
	) id_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.ctrl_busy_o(ctrl_busy),
		.illegal_insn_o(illegal_insn_id),
		.instr_valid_i(instr_valid_id),
		.instr_rdata_i(instr_rdata_id),
		.instr_rdata_alu_i(instr_rdata_alu_id),
		.instr_rdata_c_i(instr_rdata_c_id),
		.instr_is_compressed_i(instr_is_compressed_id),
		.instr_bp_taken_i(instr_bp_taken_id),
		.branch_decision_i(branch_decision),
		.instr_first_cycle_id_o(instr_first_cycle_id),
		.instr_valid_clear_o(instr_valid_clear),
		.id_in_ready_o(id_in_ready),
		.instr_exec_i(instr_exec),
		.instr_req_o(instr_req_int),
		.pc_set_o(pc_set),
		.pc_mux_o(pc_mux_id),
		.nt_branch_mispredict_o(nt_branch_mispredict),
		.nt_branch_addr_o(nt_branch_addr),
		.exc_pc_mux_o(exc_pc_mux_id),
		.exc_cause_o(exc_cause),
		.icache_inval_o(icache_inval),
		.instr_fetch_err_i(instr_fetch_err),
		.instr_fetch_err_plus2_i(instr_fetch_err_plus2),
		.illegal_c_insn_i(illegal_c_insn_id),
		.pc_id_i(pc_id),
		.ex_valid_i(ex_valid),
		.lsu_resp_valid_i(lsu_resp_valid),
		.alu_operator_ex_o(alu_operator_ex),
		.alu_operand_a_ex_o(alu_operand_a_ex),
		.alu_operand_b_ex_o(alu_operand_b_ex),
		.imd_val_q_ex_o(imd_val_q_ex),
		.imd_val_d_ex_i(imd_val_d_ex),
		.imd_val_we_ex_i(imd_val_we_ex),
		.bt_a_operand_o(bt_a_operand),
		.bt_b_operand_o(bt_b_operand),
		.mult_en_ex_o(mult_en_ex),
		.div_en_ex_o(div_en_ex),
		.mult_sel_ex_o(mult_sel_ex),
		.div_sel_ex_o(div_sel_ex),
		.multdiv_operator_ex_o(multdiv_operator_ex),
		.multdiv_signed_mode_ex_o(multdiv_signed_mode_ex),
		.multdiv_operand_a_ex_o(multdiv_operand_a_ex),
		.multdiv_operand_b_ex_o(multdiv_operand_b_ex),
		.multdiv_ready_id_o(multdiv_ready_id),
		.csr_access_o(csr_access),
		.csr_op_o(csr_op),
		.csr_op_en_o(csr_op_en),
		.csr_save_if_o(csr_save_if),
		.csr_save_id_o(csr_save_id),
		.csr_save_wb_o(csr_save_wb),
		.csr_restore_mret_id_o(csr_restore_mret_id),
		.csr_restore_dret_id_o(csr_restore_dret_id),
		.csr_save_cause_o(csr_save_cause),
		.csr_mtval_o(csr_mtval),
		.priv_mode_i(priv_mode_id),
		.csr_mstatus_tw_i(csr_mstatus_tw),
		.illegal_csr_insn_i(illegal_csr_insn_id),
		.data_ind_timing_i(data_ind_timing),
		.lsu_req_o(lsu_req),
		.lsu_we_o(lsu_we),
		.lsu_type_o(lsu_type),
		.lsu_sign_ext_o(lsu_sign_ext),
		.lsu_wdata_o(lsu_wdata),
		.lsu_req_done_i(lsu_req_done),
		.lsu_addr_incr_req_i(lsu_addr_incr_req),
		.lsu_addr_last_i(lsu_addr_last),
		.lsu_load_err_i(lsu_load_err),
		.lsu_load_resp_intg_err_i(lsu_load_resp_intg_err),
		.lsu_store_err_i(lsu_store_err),
		.lsu_store_resp_intg_err_i(lsu_store_resp_intg_err),
		.expecting_load_resp_o(expecting_load_resp_id),
		.expecting_store_resp_o(expecting_store_resp_id),
		.csr_mstatus_mie_i(csr_mstatus_mie),
		.irq_pending_i(irq_pending_o),
		.irqs_i(irqs),
		.irq_nm_i(irq_nm_i),
		.nmi_mode_o(nmi_mode),
		.debug_mode_o(debug_mode),
		.debug_mode_entering_o(debug_mode_entering),
		.debug_cause_o(debug_cause),
		.debug_csr_save_o(debug_csr_save),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step),
		.debug_ebreakm_i(debug_ebreakm),
		.debug_ebreaku_i(debug_ebreaku),
		.trigger_match_i(trigger_match),
		.result_ex_i(result_ex),
		.csr_rdata_i(csr_rdata),
		.rf_raddr_a_o(rf_raddr_a),
		.rf_rdata_a_i(rf_rdata_a),
		.rf_raddr_b_o(rf_raddr_b),
		.rf_rdata_b_i(rf_rdata_b),
		.rf_ren_a_o(rf_ren_a),
		.rf_ren_b_o(rf_ren_b),
		.rf_waddr_id_o(rf_waddr_id),
		.rf_wdata_id_o(rf_wdata_id),
		.rf_we_id_o(rf_we_id),
		.rf_rd_a_wb_match_o(rf_rd_a_wb_match),
		.rf_rd_b_wb_match_o(rf_rd_b_wb_match),
		.rf_waddr_wb_i(rf_waddr_wb),
		.rf_wdata_fwd_wb_i(rf_wdata_fwd_wb),
		.rf_write_wb_i(rf_write_wb),
		.en_wb_o(en_wb),
		.instr_type_wb_o(instr_type_wb),
		.instr_perf_count_id_o(instr_perf_count_id),
		.ready_wb_i(ready_wb),
		.outstanding_load_wb_i(outstanding_load_wb),
		.outstanding_store_wb_i(outstanding_store_wb),
		.perf_jump_o(perf_jump),
		.perf_branch_o(perf_branch),
		.perf_tbranch_o(perf_tbranch),
		.perf_dside_wait_o(perf_dside_wait),
		.perf_mul_wait_o(perf_mul_wait),
		.perf_div_wait_o(perf_div_wait),
		.instr_id_done_o(instr_id_done)
	);
	assign unused_illegal_insn_id = illegal_insn_id;
	ibex_ex_block #(
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU)
	) ex_block_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.alu_operator_i(alu_operator_ex),
		.alu_operand_a_i(alu_operand_a_ex),
		.alu_operand_b_i(alu_operand_b_ex),
		.alu_instr_first_cycle_i(instr_first_cycle_id),
		.bt_a_operand_i(bt_a_operand),
		.bt_b_operand_i(bt_b_operand),
		.multdiv_operator_i(multdiv_operator_ex),
		.mult_en_i(mult_en_ex),
		.div_en_i(div_en_ex),
		.mult_sel_i(mult_sel_ex),
		.div_sel_i(div_sel_ex),
		.multdiv_signed_mode_i(multdiv_signed_mode_ex),
		.multdiv_operand_a_i(multdiv_operand_a_ex),
		.multdiv_operand_b_i(multdiv_operand_b_ex),
		.multdiv_ready_id_i(multdiv_ready_id),
		.data_ind_timing_i(data_ind_timing),
		.imd_val_we_o(imd_val_we_ex),
		.imd_val_d_o(imd_val_d_ex),
		.imd_val_q_i(imd_val_q_ex),
		.alu_adder_result_ex_o(alu_adder_result_ex),
		.result_ex_o(result_ex),
		.branch_target_o(branch_target_ex),
		.branch_decision_o(branch_decision),
		.ex_valid_o(ex_valid)
	);
	localparam [31:0] ibex_pkg_PMP_D = 2;
	assign data_req_o = data_req_out & ~pmp_req_err[ibex_pkg_PMP_D];
	assign lsu_resp_err = lsu_load_err | lsu_store_err;
	ibex_load_store_unit #(
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth)
	) load_store_unit_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.data_req_o(data_req_out),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_bus_err_i(data_err_i),
		.data_pmp_err_i(pmp_req_err[ibex_pkg_PMP_D]),
		.data_addr_o(data_addr_o),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_wdata_o(data_wdata_o),
		.data_rdata_i(data_rdata_i),
		.lsu_we_i(lsu_we),
		.lsu_type_i(lsu_type),
		.lsu_wdata_i(lsu_wdata),
		.lsu_sign_ext_i(lsu_sign_ext),
		.lsu_rdata_o(rf_wdata_lsu),
		.lsu_rdata_valid_o(lsu_rdata_valid),
		.lsu_req_i(lsu_req),
		.lsu_req_done_o(lsu_req_done),
		.adder_result_ex_i(alu_adder_result_ex),
		.addr_incr_req_o(lsu_addr_incr_req),
		.addr_last_o(lsu_addr_last),
		.lsu_resp_valid_o(lsu_resp_valid),
		.load_err_o(lsu_load_err_raw),
		.load_resp_intg_err_o(lsu_load_resp_intg_err),
		.store_err_o(lsu_store_err_raw),
		.store_resp_intg_err_o(lsu_store_resp_intg_err),
		.busy_o(lsu_busy),
		.perf_load_o(perf_load),
		.perf_store_o(perf_store)
	);
	ibex_wb_stage #(
		.ResetAll(ResetAll),
		.WritebackStage(WritebackStage),
		.DummyInstructions(DummyInstructions)
	) wb_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.en_wb_i(en_wb),
		.instr_type_wb_i(instr_type_wb),
		.pc_id_i(pc_id),
		.instr_is_compressed_id_i(instr_is_compressed_id),
		.instr_perf_count_id_i(instr_perf_count_id),
		.ready_wb_o(ready_wb),
		.rf_write_wb_o(rf_write_wb),
		.outstanding_load_wb_o(outstanding_load_wb),
		.outstanding_store_wb_o(outstanding_store_wb),
		.pc_wb_o(pc_wb),
		.perf_instr_ret_wb_o(perf_instr_ret_wb),
		.perf_instr_ret_compressed_wb_o(perf_instr_ret_compressed_wb),
		.perf_instr_ret_wb_spec_o(perf_instr_ret_wb_spec),
		.perf_instr_ret_compressed_wb_spec_o(perf_instr_ret_compressed_wb_spec),
		.rf_waddr_id_i(rf_waddr_id),
		.rf_wdata_id_i(rf_wdata_id),
		.rf_we_id_i(rf_we_id),
		.dummy_instr_id_i(dummy_instr_id),
		.rf_wdata_lsu_i(rf_wdata_lsu),
		.rf_we_lsu_i(rf_we_lsu),
		.rf_wdata_fwd_wb_o(rf_wdata_fwd_wb),
		.rf_waddr_wb_o(rf_waddr_wb),
		.rf_wdata_wb_o(rf_wdata_wb),
		.rf_we_wb_o(rf_we_wb),
		.dummy_instr_wb_o(dummy_instr_wb),
		.lsu_resp_valid_i(lsu_resp_valid),
		.lsu_resp_err_i(lsu_resp_err),
		.instr_done_wb_o(instr_done_wb)
	);
	generate
		if (SecureIbex) begin : g_check_mem_response
			assign lsu_load_err = lsu_load_err_raw & (outstanding_load_wb | expecting_load_resp_id);
			assign lsu_store_err = lsu_store_err_raw & (outstanding_store_wb | expecting_store_resp_id);
			assign rf_we_lsu = lsu_rdata_valid & (outstanding_load_wb | expecting_load_resp_id);
		end
		else begin : g_no_check_mem_response
			assign lsu_load_err = lsu_load_err_raw;
			assign lsu_store_err = lsu_store_err_raw;
			assign rf_we_lsu = lsu_rdata_valid;
			wire unused_expecting_load_resp_id;
			wire unused_expecting_store_resp_id;
			assign unused_expecting_load_resp_id = expecting_load_resp_id;
			assign unused_expecting_store_resp_id = expecting_store_resp_id;
		end
	endgenerate
	assign dummy_instr_id_o = dummy_instr_id;
	assign dummy_instr_wb_o = dummy_instr_wb;
	assign rf_raddr_a_o = rf_raddr_a;
	assign rf_waddr_wb_o = rf_waddr_wb;
	assign rf_we_wb_o = rf_we_wb;
	assign rf_raddr_b_o = rf_raddr_b;
	generate
		if (RegFileECC) begin : gen_regfile_ecc
			wire [1:0] rf_ecc_err_a;
			wire [1:0] rf_ecc_err_b;
			wire rf_ecc_err_a_id;
			wire rf_ecc_err_b_id;
			prim_secded_inv_39_32_enc regfile_ecc_enc(
				.data_i(rf_wdata_wb),
				.data_o(rf_wdata_wb_ecc_o)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_a(
				.data_i(rf_rdata_a_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_a)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_b(
				.data_i(rf_rdata_b_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_b)
			);
			assign rf_rdata_a = rf_rdata_a_ecc_i[31:0];
			assign rf_rdata_b = rf_rdata_b_ecc_i[31:0];
			assign rf_ecc_err_a_id = (|rf_ecc_err_a & rf_ren_a) & ~(rf_rd_a_wb_match & rf_write_wb);
			assign rf_ecc_err_b_id = (|rf_ecc_err_b & rf_ren_b) & ~(rf_rd_b_wb_match & rf_write_wb);
			assign rf_ecc_err_comb = instr_valid_id & (rf_ecc_err_a_id | rf_ecc_err_b_id);
		end
		else begin : gen_no_regfile_ecc
			wire unused_rf_ren_a;
			wire unused_rf_ren_b;
			wire unused_rf_rd_a_wb_match;
			wire unused_rf_rd_b_wb_match;
			assign unused_rf_ren_a = rf_ren_a;
			assign unused_rf_ren_b = rf_ren_b;
			assign unused_rf_rd_a_wb_match = rf_rd_a_wb_match;
			assign unused_rf_rd_b_wb_match = rf_rd_b_wb_match;
			assign rf_wdata_wb_ecc_o = rf_wdata_wb;
			assign rf_rdata_a = rf_rdata_a_ecc_i;
			assign rf_rdata_b = rf_rdata_b_ecc_i;
			assign rf_ecc_err_comb = 1'b0;
		end
	endgenerate
	wire [31:0] crash_dump_mtval;
	assign crash_dump_o[159-:32] = pc_id;
	assign crash_dump_o[127-:32] = pc_if;
	assign crash_dump_o[95-:32] = lsu_addr_last;
	assign crash_dump_o[63-:32] = csr_mepc;
	assign crash_dump_o[31-:32] = crash_dump_mtval;
	assign alert_minor_o = icache_ecc_error;
	assign alert_major_internal_o = (rf_ecc_err_comb | pc_mismatch_alert) | csr_shadow_err;
	assign alert_major_bus_o = (lsu_load_resp_intg_err | lsu_store_resp_intg_err) | instr_intg_err;
	assign csr_wdata = alu_operand_a_ex;
	function automatic [11:0] sv2v_cast_12;
		input reg [11:0] inp;
		sv2v_cast_12 = inp;
	endfunction
	assign csr_addr = sv2v_cast_12((csr_access ? alu_operand_b_ex[11:0] : 12'b000000000000));
	ibex_cs_registers #(
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.DataIndTiming(DataIndTiming),
		.DummyInstructions(DummyInstructions),
		.ShadowCSR(ShadowCSR),
		.ICache(ICache),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B)
	) cs_registers_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.hart_id_i(hart_id_i),
		.priv_mode_id_o(priv_mode_id),
		.priv_mode_lsu_o(priv_mode_lsu),
		.csr_mtvec_o(csr_mtvec),
		.csr_mtvec_init_i(csr_mtvec_init),
		.boot_addr_i(boot_addr_i),
		.csr_access_i(csr_access),
		.csr_addr_i(csr_addr),
		.csr_wdata_i(csr_wdata),
		.csr_op_i(csr_op),
		.csr_op_en_i(csr_op_en),
		.csr_rdata_o(csr_rdata),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.nmi_mode_i(nmi_mode),
		.irq_pending_o(irq_pending_o),
		.irqs_o(irqs),
		.csr_mstatus_mie_o(csr_mstatus_mie),
		.csr_mstatus_tw_o(csr_mstatus_tw),
		.csr_mepc_o(csr_mepc),
		.csr_mtval_o(crash_dump_mtval),
		.csr_pmp_cfg_o(csr_pmp_cfg),
		.csr_pmp_addr_o(csr_pmp_addr),
		.csr_pmp_mseccfg_o(csr_pmp_mseccfg),
		.csr_depc_o(csr_depc),
		.debug_mode_i(debug_mode),
		.debug_mode_entering_i(debug_mode_entering),
		.debug_cause_i(debug_cause),
		.debug_csr_save_i(debug_csr_save),
		.debug_single_step_o(debug_single_step),
		.debug_ebreakm_o(debug_ebreakm),
		.debug_ebreaku_o(debug_ebreaku),
		.trigger_match_o(trigger_match),
		.pc_if_i(pc_if),
		.pc_id_i(pc_id),
		.pc_wb_i(pc_wb),
		.data_ind_timing_o(data_ind_timing),
		.dummy_instr_en_o(dummy_instr_en),
		.dummy_instr_mask_o(dummy_instr_mask),
		.dummy_instr_seed_en_o(dummy_instr_seed_en),
		.dummy_instr_seed_o(dummy_instr_seed),
		.icache_enable_o(icache_enable),
		.csr_shadow_err_o(csr_shadow_err),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.csr_save_if_i(csr_save_if),
		.csr_save_id_i(csr_save_id),
		.csr_save_wb_i(csr_save_wb),
		.csr_restore_mret_i(csr_restore_mret_id),
		.csr_restore_dret_i(csr_restore_dret_id),
		.csr_save_cause_i(csr_save_cause),
		.csr_mcause_i(exc_cause),
		.csr_mtval_i(csr_mtval),
		.illegal_csr_insn_o(illegal_csr_insn_id),
		.double_fault_seen_o(double_fault_seen_o),
		.instr_ret_i(perf_instr_ret_wb),
		.instr_ret_compressed_i(perf_instr_ret_compressed_wb),
		.instr_ret_spec_i(perf_instr_ret_wb_spec),
		.instr_ret_compressed_spec_i(perf_instr_ret_compressed_wb_spec),
		.iside_wait_i(perf_iside_wait),
		.jump_i(perf_jump),
		.branch_i(perf_branch),
		.branch_taken_i(perf_tbranch),
		.mem_load_i(perf_load),
		.mem_store_i(perf_store),
		.dside_wait_i(perf_dside_wait),
		.mul_wait_i(perf_mul_wait),
		.div_wait_i(perf_div_wait)
	);
	generate
		if (PMPEnable) begin : g_pmp
			wire [31:0] pc_if_inc;
			wire [101:0] pmp_req_addr;
			wire [5:0] pmp_req_type;
			wire [5:0] pmp_priv_lvl;
			assign pc_if_inc = pc_if + 32'd2;
			assign pmp_req_addr[68+:34] = {2'b00, pc_if};
			assign pmp_req_type[4+:2] = 2'b00;
			assign pmp_priv_lvl[4+:2] = priv_mode_id;
			assign pmp_req_addr[34+:34] = {2'b00, pc_if_inc};
			assign pmp_req_type[2+:2] = 2'b00;
			assign pmp_priv_lvl[2+:2] = priv_mode_id;
			assign pmp_req_addr[0+:34] = {2'b00, data_addr_o[31:0]};
			assign pmp_req_type[0+:2] = (data_we_o ? 2'b01 : 2'b10);
			assign pmp_priv_lvl[0+:2] = priv_mode_lsu;
			ibex_pmp #(
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.PMPGranularity(PMPGranularity),
				.PMPNumChan(PMPNumChan),
				.PMPNumRegions(PMPNumRegions)
			) pmp_i(
				.csr_pmp_cfg_i(csr_pmp_cfg),
				.csr_pmp_addr_i(csr_pmp_addr),
				.csr_pmp_mseccfg_i(csr_pmp_mseccfg),
				.debug_mode_i(debug_mode),
				.priv_mode_i(pmp_priv_lvl),
				.pmp_req_addr_i(pmp_req_addr),
				.pmp_req_type_i(pmp_req_type),
				.pmp_req_err_o(pmp_req_err)
			);
		end
		else begin : g_no_pmp
			wire [1:0] unused_priv_lvl_ls;
			wire [(PMPNumRegions * 34) - 1:0] unused_csr_pmp_addr;
			wire [(PMPNumRegions * 6) - 1:0] unused_csr_pmp_cfg;
			wire [2:0] unused_csr_pmp_mseccfg;
			assign unused_priv_lvl_ls = priv_mode_lsu;
			assign unused_csr_pmp_addr = csr_pmp_addr;
			assign unused_csr_pmp_cfg = csr_pmp_cfg;
			assign unused_csr_pmp_mseccfg = csr_pmp_mseccfg;
			assign pmp_req_err[ibex_pkg_PMP_I] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_I2] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_D] = 1'b0;
		end
	endgenerate
	wire unused_instr_new_id;
	wire unused_instr_id_done;
	wire unused_instr_done_wb;
	assign unused_instr_id_done = instr_id_done;
	assign unused_instr_new_id = instr_new_id;
	assign unused_instr_done_wb = instr_done_wb;
endmodule
module ibex_alu (
	operator_i,
	operand_a_i,
	operand_b_i,
	instr_first_cycle_i,
	multdiv_operand_a_i,
	multdiv_operand_b_i,
	multdiv_sel_i,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	adder_result_o,
	adder_result_ext_o,
	result_o,
	comparison_result_o,
	is_equal_result_o
);
	reg _sv2v_0;
	parameter integer RV32B = 32'sd0;
	input wire [6:0] operator_i;
	input wire [31:0] operand_a_i;
	input wire [31:0] operand_b_i;
	input wire instr_first_cycle_i;
	input wire [32:0] multdiv_operand_a_i;
	input wire [32:0] multdiv_operand_b_i;
	input wire multdiv_sel_i;
	input wire [63:0] imd_val_q_i;
	output reg [63:0] imd_val_d_o;
	output reg [1:0] imd_val_we_o;
	output wire [31:0] adder_result_o;
	output wire [33:0] adder_result_ext_o;
	output reg [31:0] result_o;
	output wire comparison_result_o;
	output wire is_equal_result_o;
	wire [31:0] operand_a_rev;
	wire [32:0] operand_b_neg;
	genvar _gv_k_1;
	generate
		for (_gv_k_1 = 0; _gv_k_1 < 32; _gv_k_1 = _gv_k_1 + 1) begin : gen_rev_operand_a
			localparam k = _gv_k_1;
			assign operand_a_rev[k] = operand_a_i[31 - k];
		end
	endgenerate
	reg adder_op_a_shift1;
	reg adder_op_a_shift2;
	reg adder_op_a_shift3;
	reg adder_op_b_negate;
	reg [32:0] adder_in_a;
	reg [32:0] adder_in_b;
	wire [31:0] adder_result;
	always @(*) begin
		if (_sv2v_0)
			;
		adder_op_a_shift1 = 1'b0;
		adder_op_a_shift2 = 1'b0;
		adder_op_a_shift3 = 1'b0;
		adder_op_b_negate = 1'b0;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd1, 7'd29, 7'd30, 7'd27, 7'd28, 7'd25, 7'd26, 7'd43, 7'd44, 7'd31, 7'd32, 7'd33, 7'd34: adder_op_b_negate = 1'b1;
			7'd22:
				if (RV32B != 32'sd0)
					adder_op_a_shift1 = 1'b1;
			7'd23:
				if (RV32B != 32'sd0)
					adder_op_a_shift2 = 1'b1;
			7'd24:
				if (RV32B != 32'sd0)
					adder_op_a_shift3 = 1'b1;
			default:
				;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			multdiv_sel_i: adder_in_a = multdiv_operand_a_i;
			adder_op_a_shift1: adder_in_a = {operand_a_i[30:0], 2'b01};
			adder_op_a_shift2: adder_in_a = {operand_a_i[29:0], 3'b001};
			adder_op_a_shift3: adder_in_a = {operand_a_i[28:0], 4'b0001};
			default: adder_in_a = {operand_a_i, 1'b1};
		endcase
	end
	assign operand_b_neg = {operand_b_i, 1'b0} ^ {33 {1'b1}};
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			multdiv_sel_i: adder_in_b = multdiv_operand_b_i;
			adder_op_b_negate: adder_in_b = operand_b_neg;
			default: adder_in_b = {operand_b_i, 1'b0};
		endcase
	end
	assign adder_result_ext_o = $unsigned(adder_in_a) + $unsigned(adder_in_b);
	assign adder_result = adder_result_ext_o[32:1];
	assign adder_result_o = adder_result;
	wire is_equal;
	reg is_greater_equal;
	reg cmp_signed;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd27, 7'd25, 7'd43, 7'd31, 7'd33: cmp_signed = 1'b1;
			default: cmp_signed = 1'b0;
		endcase
	end
	assign is_equal = adder_result == 32'b00000000000000000000000000000000;
	assign is_equal_result_o = is_equal;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((operand_a_i[31] ^ operand_b_i[31]) == 1'b0)
			is_greater_equal = adder_result[31] == 1'b0;
		else
			is_greater_equal = operand_a_i[31] ^ cmp_signed;
	end
	reg cmp_result;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd29: cmp_result = is_equal;
			7'd30: cmp_result = ~is_equal;
			7'd27, 7'd28, 7'd33, 7'd34: cmp_result = is_greater_equal;
			7'd25, 7'd26, 7'd31, 7'd32, 7'd43, 7'd44: cmp_result = ~is_greater_equal;
			default: cmp_result = is_equal;
		endcase
	end
	assign comparison_result_o = cmp_result;
	reg shift_left;
	wire shift_ones;
	wire shift_arith;
	wire shift_funnel;
	wire shift_sbmode;
	reg [5:0] shift_amt;
	wire [5:0] shift_amt_compl;
	reg [31:0] shift_operand;
	reg signed [32:0] shift_result_ext_signed;
	reg [32:0] shift_result_ext;
	reg unused_shift_result_ext;
	reg [31:0] shift_result;
	reg [31:0] shift_result_rev;
	wire bfp_op;
	wire [4:0] bfp_len;
	wire [4:0] bfp_off;
	wire [31:0] bfp_mask;
	wire [31:0] bfp_mask_rev;
	wire [31:0] bfp_result;
	assign bfp_op = (RV32B != 32'sd0 ? operator_i == 7'd55 : 1'b0);
	assign bfp_len = {~(|operand_b_i[27:24]), operand_b_i[27:24]};
	assign bfp_off = operand_b_i[20:16];
	assign bfp_mask = (RV32B != 32'sd0 ? ~(32'hffffffff << bfp_len) : {32 {1'sb0}});
	genvar _gv_i_2;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < 32; _gv_i_2 = _gv_i_2 + 1) begin : gen_rev_bfp_mask
			localparam i = _gv_i_2;
			assign bfp_mask_rev[i] = bfp_mask[31 - i];
		end
	endgenerate
	assign bfp_result = (RV32B != 32'sd0 ? (~shift_result & operand_a_i) | ((operand_b_i & bfp_mask) << bfp_off) : {32 {1'sb0}});
	wire [1:1] sv2v_tmp_BA5F8;
	assign sv2v_tmp_BA5F8 = operand_b_i[5] & shift_funnel;
	always @(*) shift_amt[5] = sv2v_tmp_BA5F8;
	assign shift_amt_compl = 32 - operand_b_i[4:0];
	always @(*) begin
		if (_sv2v_0)
			;
		if (bfp_op)
			shift_amt[4:0] = bfp_off;
		else
			shift_amt[4:0] = (instr_first_cycle_i ? (operand_b_i[5] && shift_funnel ? shift_amt_compl[4:0] : operand_b_i[4:0]) : (operand_b_i[5] && shift_funnel ? operand_b_i[4:0] : shift_amt_compl[4:0]));
	end
	assign shift_sbmode = (RV32B != 32'sd0 ? ((operator_i == 7'd49) | (operator_i == 7'd50)) | (operator_i == 7'd51) : 1'b0);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd10: shift_left = 1'b1;
			7'd12: shift_left = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b1 : 1'b0);
			7'd55: shift_left = (RV32B != 32'sd0 ? 1'b1 : 1'b0);
			7'd14: shift_left = (RV32B != 32'sd0 ? instr_first_cycle_i : 0);
			7'd13: shift_left = (RV32B != 32'sd0 ? ~instr_first_cycle_i : 0);
			7'd47: shift_left = (RV32B != 32'sd0 ? (shift_amt[5] ? ~instr_first_cycle_i : instr_first_cycle_i) : 1'b0);
			7'd48: shift_left = (RV32B != 32'sd0 ? (shift_amt[5] ? instr_first_cycle_i : ~instr_first_cycle_i) : 1'b0);
			default: shift_left = 1'b0;
		endcase
		if (shift_sbmode)
			shift_left = 1'b1;
	end
	assign shift_arith = operator_i == 7'd8;
	assign shift_ones = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? (operator_i == 7'd12) | (operator_i == 7'd11) : 1'b0);
	assign shift_funnel = (RV32B != 32'sd0 ? (operator_i == 7'd47) | (operator_i == 7'd48) : 1'b0);
	always @(*) begin
		if (_sv2v_0)
			;
		if (RV32B == 32'sd0)
			shift_operand = (shift_left ? operand_a_rev : operand_a_i);
		else
			(* full_case, parallel_case *)
			case (1'b1)
				bfp_op: shift_operand = bfp_mask_rev;
				shift_sbmode: shift_operand = 32'h80000000;
				default: shift_operand = (shift_left ? operand_a_rev : operand_a_i);
			endcase
		shift_result_ext_signed = $signed({shift_ones | (shift_arith & shift_operand[31]), shift_operand}) >>> shift_amt[4:0];
		shift_result_ext = $unsigned(shift_result_ext_signed);
		shift_result = shift_result_ext[31:0];
		unused_shift_result_ext = shift_result_ext[32];
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				shift_result_rev[i] = shift_result[31 - i];
		end
		shift_result = (shift_left ? shift_result_rev : shift_result);
	end
	wire bwlogic_or;
	wire bwlogic_and;
	wire [31:0] bwlogic_operand_b;
	wire [31:0] bwlogic_or_result;
	wire [31:0] bwlogic_and_result;
	wire [31:0] bwlogic_xor_result;
	reg [31:0] bwlogic_result;
	reg bwlogic_op_b_negate;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd5, 7'd6, 7'd7: bwlogic_op_b_negate = (RV32B != 32'sd0 ? 1'b1 : 1'b0);
			7'd46: bwlogic_op_b_negate = (RV32B != 32'sd0 ? ~instr_first_cycle_i : 1'b0);
			default: bwlogic_op_b_negate = 1'b0;
		endcase
	end
	assign bwlogic_operand_b = (bwlogic_op_b_negate ? operand_b_neg[32:1] : operand_b_i);
	assign bwlogic_or_result = operand_a_i | bwlogic_operand_b;
	assign bwlogic_and_result = operand_a_i & bwlogic_operand_b;
	assign bwlogic_xor_result = operand_a_i ^ bwlogic_operand_b;
	assign bwlogic_or = (operator_i == 7'd3) | (operator_i == 7'd6);
	assign bwlogic_and = (operator_i == 7'd4) | (operator_i == 7'd7);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			bwlogic_or: bwlogic_result = bwlogic_or_result;
			bwlogic_and: bwlogic_result = bwlogic_and_result;
			default: bwlogic_result = bwlogic_xor_result;
		endcase
	end
	wire [5:0] bitcnt_result;
	wire [31:0] minmax_result;
	reg [31:0] pack_result;
	wire [31:0] sext_result;
	reg [31:0] singlebit_result;
	reg [31:0] rev_result;
	reg [31:0] shuffle_result;
	wire [31:0] xperm_result;
	reg [31:0] butterfly_result;
	reg [31:0] invbutterfly_result;
	reg [31:0] clmul_result;
	reg [31:0] multicycle_result;
	generate
		if (RV32B != 32'sd0) begin : g_alu_rvb
			wire zbe_op;
			wire bitcnt_ctz;
			wire bitcnt_clz;
			wire bitcnt_cz;
			reg [31:0] bitcnt_bits;
			wire [31:0] bitcnt_mask_op;
			reg [31:0] bitcnt_bit_mask;
			reg [191:0] bitcnt_partial;
			wire [31:0] bitcnt_partial_lsb_d;
			wire [31:0] bitcnt_partial_msb_d;
			assign bitcnt_ctz = operator_i == 7'd41;
			assign bitcnt_clz = operator_i == 7'd40;
			assign bitcnt_cz = bitcnt_ctz | bitcnt_clz;
			assign bitcnt_result = bitcnt_partial[0+:6];
			assign bitcnt_mask_op = (bitcnt_clz ? operand_a_rev : operand_a_i);
			always @(*) begin
				if (_sv2v_0)
					;
				bitcnt_bit_mask = bitcnt_mask_op;
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 1);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 2);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 4);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 8);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 16);
				bitcnt_bit_mask = ~bitcnt_bit_mask;
			end
			assign zbe_op = (operator_i == 7'd53) | (operator_i == 7'd54);
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (1'b1)
					zbe_op: bitcnt_bits = operand_b_i;
					bitcnt_cz: bitcnt_bits = bitcnt_bit_mask & ~bitcnt_mask_op;
					default: bitcnt_bits = operand_a_i;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				bitcnt_partial = {32 {6'b000000}};
				begin : sv2v_autoblock_2
					reg [31:0] i;
					for (i = 1; i < 32; i = i + 2)
						bitcnt_partial[(31 - i) * 6+:6] = {5'h00, bitcnt_bits[i]} + {5'h00, bitcnt_bits[i - 1]};
				end
				begin : sv2v_autoblock_3
					reg [31:0] i;
					for (i = 3; i < 32; i = i + 4)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(33 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_4
					reg [31:0] i;
					for (i = 7; i < 32; i = i + 8)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(35 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_5
					reg [31:0] i;
					for (i = 15; i < 32; i = i + 16)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(39 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				bitcnt_partial[0+:6] = bitcnt_partial[96+:6] + bitcnt_partial[0+:6];
				bitcnt_partial[48+:6] = bitcnt_partial[96+:6] + bitcnt_partial[48+:6];
				begin : sv2v_autoblock_6
					reg [31:0] i;
					for (i = 11; i < 32; i = i + 8)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(35 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_7
					reg [31:0] i;
					for (i = 5; i < 32; i = i + 4)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(33 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				bitcnt_partial[186+:6] = {5'h00, bitcnt_bits[0]};
				begin : sv2v_autoblock_8
					reg [31:0] i;
					for (i = 2; i < 32; i = i + 2)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(32 - i) * 6+:6] + {5'h00, bitcnt_bits[i]};
				end
			end
			assign minmax_result = (cmp_result ? operand_a_i : operand_b_i);
			wire packu;
			wire packh;
			assign packu = operator_i == 7'd36;
			assign packh = operator_i == 7'd37;
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (1'b1)
					packu: pack_result = {operand_b_i[31:16], operand_a_i[31:16]};
					packh: pack_result = {16'h0000, operand_b_i[7:0], operand_a_i[7:0]};
					default: pack_result = {operand_b_i[15:0], operand_a_i[15:0]};
				endcase
			end
			assign sext_result = (operator_i == 7'd38 ? {{24 {operand_a_i[7]}}, operand_a_i[7:0]} : {{16 {operand_a_i[15]}}, operand_a_i[15:0]});
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (operator_i)
					7'd49: singlebit_result = operand_a_i | shift_result;
					7'd50: singlebit_result = operand_a_i & ~shift_result;
					7'd51: singlebit_result = operand_a_i ^ shift_result;
					default: singlebit_result = {31'h00000000, shift_result[0]};
				endcase
			end
			wire [4:0] zbp_shift_amt;
			wire gorc_op;
			assign gorc_op = operator_i == 7'd16;
			assign zbp_shift_amt[2:0] = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? shift_amt[2:0] : {3 {shift_amt[0]}});
			assign zbp_shift_amt[4:3] = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? shift_amt[4:3] : {2 {shift_amt[3]}});
			always @(*) begin
				if (_sv2v_0)
					;
				rev_result = operand_a_i;
				if (zbp_shift_amt[0])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h55555555) << 1)) | ((rev_result & 32'haaaaaaaa) >> 1);
				if (zbp_shift_amt[1])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h33333333) << 2)) | ((rev_result & 32'hcccccccc) >> 2);
				if (zbp_shift_amt[2])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h0f0f0f0f) << 4)) | ((rev_result & 32'hf0f0f0f0) >> 4);
				if (zbp_shift_amt[3])
					rev_result = ((((RV32B == 32'sd2) || (RV32B == 32'sd3)) && gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h00ff00ff) << 8)) | ((rev_result & 32'hff00ff00) >> 8);
				if (zbp_shift_amt[4])
					rev_result = ((((RV32B == 32'sd2) || (RV32B == 32'sd3)) && gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h0000ffff) << 16)) | ((rev_result & 32'hffff0000) >> 16);
			end
			wire crc_hmode;
			wire crc_bmode;
			wire [31:0] clmul_result_rev;
			if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin : gen_alu_rvb_otearlgrey_full
				localparam [127:0] SHUFFLE_MASK_L = 128'h00ff00000f000f003030303044444444;
				localparam [127:0] SHUFFLE_MASK_R = 128'h0000ff0000f000f00c0c0c0c22222222;
				localparam [127:0] FLIP_MASK_L = 128'h22001100004400004411000011000000;
				localparam [127:0] FLIP_MASK_R = 128'h00880044000022000000882200000088;
				wire [31:0] SHUFFLE_MASK_NOT [0:3];
				genvar _gv_i_3;
				for (_gv_i_3 = 0; _gv_i_3 < 4; _gv_i_3 = _gv_i_3 + 1) begin : gen_shuffle_mask_not
					localparam i = _gv_i_3;
					assign SHUFFLE_MASK_NOT[i] = ~(SHUFFLE_MASK_L[(3 - i) * 32+:32] | SHUFFLE_MASK_R[(3 - i) * 32+:32]);
				end
				wire shuffle_flip;
				assign shuffle_flip = operator_i == 7'd18;
				reg [3:0] shuffle_mode;
				always @(*) begin
					if (_sv2v_0)
						;
					shuffle_result = operand_a_i;
					if (shuffle_flip) begin
						shuffle_mode[3] = shift_amt[0];
						shuffle_mode[2] = shift_amt[1];
						shuffle_mode[1] = shift_amt[2];
						shuffle_mode[0] = shift_amt[3];
					end
					else
						shuffle_mode = shift_amt[3:0];
					if (shuffle_flip)
						shuffle_result = ((((((((shuffle_result & 32'h88224411) | ((shuffle_result << 6) & FLIP_MASK_L[96+:32])) | ((shuffle_result >> 6) & FLIP_MASK_R[96+:32])) | ((shuffle_result << 9) & FLIP_MASK_L[64+:32])) | ((shuffle_result >> 9) & FLIP_MASK_R[64+:32])) | ((shuffle_result << 15) & FLIP_MASK_L[32+:32])) | ((shuffle_result >> 15) & FLIP_MASK_R[32+:32])) | ((shuffle_result << 21) & FLIP_MASK_L[0+:32])) | ((shuffle_result >> 21) & FLIP_MASK_R[0+:32]);
					if (shuffle_mode[3])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[0]) | (((shuffle_result << 8) & SHUFFLE_MASK_L[96+:32]) | ((shuffle_result >> 8) & SHUFFLE_MASK_R[96+:32]));
					if (shuffle_mode[2])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[1]) | (((shuffle_result << 4) & SHUFFLE_MASK_L[64+:32]) | ((shuffle_result >> 4) & SHUFFLE_MASK_R[64+:32]));
					if (shuffle_mode[1])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[2]) | (((shuffle_result << 2) & SHUFFLE_MASK_L[32+:32]) | ((shuffle_result >> 2) & SHUFFLE_MASK_R[32+:32]));
					if (shuffle_mode[0])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[3]) | (((shuffle_result << 1) & SHUFFLE_MASK_L[0+:32]) | ((shuffle_result >> 1) & SHUFFLE_MASK_R[0+:32]));
					if (shuffle_flip)
						shuffle_result = ((((((((shuffle_result & 32'h88224411) | ((shuffle_result << 6) & FLIP_MASK_L[96+:32])) | ((shuffle_result >> 6) & FLIP_MASK_R[96+:32])) | ((shuffle_result << 9) & FLIP_MASK_L[64+:32])) | ((shuffle_result >> 9) & FLIP_MASK_R[64+:32])) | ((shuffle_result << 15) & FLIP_MASK_L[32+:32])) | ((shuffle_result >> 15) & FLIP_MASK_R[32+:32])) | ((shuffle_result << 21) & FLIP_MASK_L[0+:32])) | ((shuffle_result >> 21) & FLIP_MASK_R[0+:32]);
				end
				wire [23:0] sel_n;
				wire [7:0] vld_n;
				wire [7:0] sel_b;
				wire [3:0] vld_b;
				wire [1:0] sel_h;
				wire [1:0] vld_h;
				genvar _gv_i_4;
				for (_gv_i_4 = 0; _gv_i_4 < 8; _gv_i_4 = _gv_i_4 + 1) begin : gen_sel_vld_n
					localparam i = _gv_i_4;
					assign sel_n[i * 3+:3] = operand_b_i[i * 4+:3];
					assign vld_n[i] = ~|operand_b_i[(i * 4) + 3+:1];
				end
				genvar _gv_i_5;
				for (_gv_i_5 = 0; _gv_i_5 < 4; _gv_i_5 = _gv_i_5 + 1) begin : gen_sel_vld_b
					localparam i = _gv_i_5;
					assign sel_b[i * 2+:2] = operand_b_i[i * 8+:2];
					assign vld_b[i] = ~|operand_b_i[(i * 8) + 2+:6];
				end
				genvar _gv_i_6;
				for (_gv_i_6 = 0; _gv_i_6 < 2; _gv_i_6 = _gv_i_6 + 1) begin : gen_sel_vld_h
					localparam i = _gv_i_6;
					assign sel_h[i+:1] = operand_b_i[i * 16+:1];
					assign vld_h[i] = ~|operand_b_i[(i * 16) + 1+:15];
				end
				reg [23:0] sel;
				reg [7:0] vld;
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (operator_i)
						7'd19: begin
							sel = sel_n;
							vld = vld_n;
						end
						7'd20: begin : sv2v_autoblock_9
							reg signed [31:0] b;
							for (b = 0; b < 4; b = b + 1)
								begin
									sel[((b * 2) + 0) * 3+:3] = {sel_b[b * 2+:2], 1'b0};
									sel[((b * 2) + 1) * 3+:3] = {sel_b[b * 2+:2], 1'b1};
									vld[b * 2+:2] = {2 {vld_b[b]}};
								end
						end
						7'd21: begin : sv2v_autoblock_10
							reg signed [31:0] h;
							for (h = 0; h < 2; h = h + 1)
								begin
									sel[((h * 4) + 0) * 3+:3] = {sel_h[h+:1], 2'b00};
									sel[((h * 4) + 1) * 3+:3] = {sel_h[h+:1], 2'b01};
									sel[((h * 4) + 2) * 3+:3] = {sel_h[h+:1], 2'b10};
									sel[((h * 4) + 3) * 3+:3] = {sel_h[h+:1], 2'b11};
									vld[h * 4+:4] = {4 {vld_h[h]}};
								end
						end
						default: begin
							sel = sel_n;
							vld = 1'sb0;
						end
					endcase
				end
				wire [31:0] val_n;
				wire [31:0] xperm_n;
				assign val_n = operand_a_i;
				genvar _gv_i_7;
				for (_gv_i_7 = 0; _gv_i_7 < 8; _gv_i_7 = _gv_i_7 + 1) begin : gen_xperm_n
					localparam i = _gv_i_7;
					assign xperm_n[i * 4+:4] = (vld[i] ? val_n[sel[i * 3+:3] * 4+:4] : {4 {1'sb0}});
				end
				assign xperm_result = xperm_n;
				wire clmul_rmode;
				wire clmul_hmode;
				reg [31:0] clmul_op_a;
				reg [31:0] clmul_op_b;
				wire [31:0] operand_b_rev;
				wire [31:0] clmul_and_stage [0:31];
				wire [31:0] clmul_xor_stage1 [0:15];
				wire [31:0] clmul_xor_stage2 [0:7];
				wire [31:0] clmul_xor_stage3 [0:3];
				wire [31:0] clmul_xor_stage4 [0:1];
				wire [31:0] clmul_result_raw;
				genvar _gv_i_8;
				for (_gv_i_8 = 0; _gv_i_8 < 32; _gv_i_8 = _gv_i_8 + 1) begin : gen_rev_operand_b
					localparam i = _gv_i_8;
					assign operand_b_rev[i] = operand_b_i[31 - i];
				end
				assign clmul_rmode = operator_i == 7'd57;
				assign clmul_hmode = operator_i == 7'd58;
				localparam [31:0] CRC32_POLYNOMIAL = 32'h04c11db7;
				localparam [31:0] CRC32_MU_REV = 32'hf7011641;
				localparam [31:0] CRC32C_POLYNOMIAL = 32'h1edc6f41;
				localparam [31:0] CRC32C_MU_REV = 32'hdea713f1;
				wire crc_op;
				wire crc_cpoly;
				reg [31:0] crc_operand;
				wire [31:0] crc_poly;
				wire [31:0] crc_mu_rev;
				assign crc_op = (((((operator_i == 7'd64) | (operator_i == 7'd63)) | (operator_i == 7'd62)) | (operator_i == 7'd61)) | (operator_i == 7'd60)) | (operator_i == 7'd59);
				assign crc_cpoly = ((operator_i == 7'd64) | (operator_i == 7'd62)) | (operator_i == 7'd60);
				assign crc_hmode = (operator_i == 7'd61) | (operator_i == 7'd62);
				assign crc_bmode = (operator_i == 7'd59) | (operator_i == 7'd60);
				assign crc_poly = (crc_cpoly ? CRC32C_POLYNOMIAL : CRC32_POLYNOMIAL);
				assign crc_mu_rev = (crc_cpoly ? CRC32C_MU_REV : CRC32_MU_REV);
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (1'b1)
						crc_bmode: crc_operand = {operand_a_i[7:0], 24'h000000};
						crc_hmode: crc_operand = {operand_a_i[15:0], 16'h0000};
						default: crc_operand = operand_a_i;
					endcase
				end
				always @(*) begin
					if (_sv2v_0)
						;
					if (crc_op) begin
						clmul_op_a = (instr_first_cycle_i ? crc_operand : imd_val_q_i[32+:32]);
						clmul_op_b = (instr_first_cycle_i ? crc_mu_rev : crc_poly);
					end
					else begin
						clmul_op_a = (clmul_rmode | clmul_hmode ? operand_a_rev : operand_a_i);
						clmul_op_b = (clmul_rmode | clmul_hmode ? operand_b_rev : operand_b_i);
					end
				end
				genvar _gv_i_9;
				for (_gv_i_9 = 0; _gv_i_9 < 32; _gv_i_9 = _gv_i_9 + 1) begin : gen_clmul_and_op
					localparam i = _gv_i_9;
					assign clmul_and_stage[i] = (clmul_op_b[i] ? clmul_op_a << i : {32 {1'sb0}});
				end
				genvar _gv_i_10;
				for (_gv_i_10 = 0; _gv_i_10 < 16; _gv_i_10 = _gv_i_10 + 1) begin : gen_clmul_xor_op_l1
					localparam i = _gv_i_10;
					assign clmul_xor_stage1[i] = clmul_and_stage[2 * i] ^ clmul_and_stage[(2 * i) + 1];
				end
				genvar _gv_i_11;
				for (_gv_i_11 = 0; _gv_i_11 < 8; _gv_i_11 = _gv_i_11 + 1) begin : gen_clmul_xor_op_l2
					localparam i = _gv_i_11;
					assign clmul_xor_stage2[i] = clmul_xor_stage1[2 * i] ^ clmul_xor_stage1[(2 * i) + 1];
				end
				genvar _gv_i_12;
				for (_gv_i_12 = 0; _gv_i_12 < 4; _gv_i_12 = _gv_i_12 + 1) begin : gen_clmul_xor_op_l3
					localparam i = _gv_i_12;
					assign clmul_xor_stage3[i] = clmul_xor_stage2[2 * i] ^ clmul_xor_stage2[(2 * i) + 1];
				end
				genvar _gv_i_13;
				for (_gv_i_13 = 0; _gv_i_13 < 2; _gv_i_13 = _gv_i_13 + 1) begin : gen_clmul_xor_op_l4
					localparam i = _gv_i_13;
					assign clmul_xor_stage4[i] = clmul_xor_stage3[2 * i] ^ clmul_xor_stage3[(2 * i) + 1];
				end
				assign clmul_result_raw = clmul_xor_stage4[0] ^ clmul_xor_stage4[1];
				genvar _gv_i_14;
				for (_gv_i_14 = 0; _gv_i_14 < 32; _gv_i_14 = _gv_i_14 + 1) begin : gen_rev_clmul_result
					localparam i = _gv_i_14;
					assign clmul_result_rev[i] = clmul_result_raw[31 - i];
				end
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (1'b1)
						clmul_rmode: clmul_result = clmul_result_rev;
						clmul_hmode: clmul_result = {1'b0, clmul_result_rev[31:1]};
						default: clmul_result = clmul_result_raw;
					endcase
				end
			end
			else begin : gen_alu_rvb_not_otearlgrey_full
				wire [32:1] sv2v_tmp_4A308;
				assign sv2v_tmp_4A308 = 1'sb0;
				always @(*) shuffle_result = sv2v_tmp_4A308;
				assign xperm_result = 1'sb0;
				wire [32:1] sv2v_tmp_31DA6;
				assign sv2v_tmp_31DA6 = 1'sb0;
				always @(*) clmul_result = sv2v_tmp_31DA6;
				assign clmul_result_rev = 1'sb0;
				assign crc_bmode = 1'sb0;
				assign crc_hmode = 1'sb0;
			end
			if (RV32B == 32'sd3) begin : gen_alu_rvb_full
				reg [191:0] bitcnt_partial_q;
				genvar _gv_i_15;
				for (_gv_i_15 = 0; _gv_i_15 < 32; _gv_i_15 = _gv_i_15 + 1) begin : gen_bitcnt_reg_in_lsb
					localparam i = _gv_i_15;
					assign bitcnt_partial_lsb_d[i] = bitcnt_partial[(31 - i) * 6];
				end
				genvar _gv_i_16;
				for (_gv_i_16 = 0; _gv_i_16 < 16; _gv_i_16 = _gv_i_16 + 1) begin : gen_bitcnt_reg_in_b1
					localparam i = _gv_i_16;
					assign bitcnt_partial_msb_d[i] = bitcnt_partial[((31 - ((2 * i) + 1)) * 6) + 1];
				end
				genvar _gv_i_17;
				for (_gv_i_17 = 0; _gv_i_17 < 8; _gv_i_17 = _gv_i_17 + 1) begin : gen_bitcnt_reg_in_b2
					localparam i = _gv_i_17;
					assign bitcnt_partial_msb_d[16 + i] = bitcnt_partial[((31 - ((4 * i) + 3)) * 6) + 2];
				end
				genvar _gv_i_18;
				for (_gv_i_18 = 0; _gv_i_18 < 4; _gv_i_18 = _gv_i_18 + 1) begin : gen_bitcnt_reg_in_b3
					localparam i = _gv_i_18;
					assign bitcnt_partial_msb_d[24 + i] = bitcnt_partial[((31 - ((8 * i) + 7)) * 6) + 3];
				end
				genvar _gv_i_19;
				for (_gv_i_19 = 0; _gv_i_19 < 2; _gv_i_19 = _gv_i_19 + 1) begin : gen_bitcnt_reg_in_b4
					localparam i = _gv_i_19;
					assign bitcnt_partial_msb_d[28 + i] = bitcnt_partial[((31 - ((16 * i) + 15)) * 6) + 4];
				end
				assign bitcnt_partial_msb_d[30] = bitcnt_partial[5];
				assign bitcnt_partial_msb_d[31] = 1'b0;
				always @(*) begin
					if (_sv2v_0)
						;
					bitcnt_partial_q = {32 {6'b000000}};
					begin : sv2v_autoblock_11
						reg [31:0] i;
						for (i = 0; i < 32; i = i + 1)
							begin : gen_bitcnt_reg_out_lsb
								bitcnt_partial_q[(31 - i) * 6] = imd_val_q_i[32 + i];
							end
					end
					begin : sv2v_autoblock_12
						reg [31:0] i;
						for (i = 0; i < 16; i = i + 1)
							begin : gen_bitcnt_reg_out_b1
								bitcnt_partial_q[((31 - ((2 * i) + 1)) * 6) + 1] = imd_val_q_i[0 + i];
							end
					end
					begin : sv2v_autoblock_13
						reg [31:0] i;
						for (i = 0; i < 8; i = i + 1)
							begin : gen_bitcnt_reg_out_b2
								bitcnt_partial_q[((31 - ((4 * i) + 3)) * 6) + 2] = imd_val_q_i[16 + i];
							end
					end
					begin : sv2v_autoblock_14
						reg [31:0] i;
						for (i = 0; i < 4; i = i + 1)
							begin : gen_bitcnt_reg_out_b3
								bitcnt_partial_q[((31 - ((8 * i) + 7)) * 6) + 3] = imd_val_q_i[24 + i];
							end
					end
					begin : sv2v_autoblock_15
						reg [31:0] i;
						for (i = 0; i < 2; i = i + 1)
							begin : gen_bitcnt_reg_out_b4
								bitcnt_partial_q[((31 - ((16 * i) + 15)) * 6) + 4] = imd_val_q_i[28 + i];
							end
					end
					bitcnt_partial_q[5] = imd_val_q_i[30];
				end
				wire [31:0] butterfly_mask_l [0:4];
				wire [31:0] butterfly_mask_r [0:4];
				wire [31:0] butterfly_mask_not [0:4];
				wire [31:0] lrotc_stage [0:4];
				genvar _gv_stg_1;
				for (_gv_stg_1 = 0; _gv_stg_1 < 5; _gv_stg_1 = _gv_stg_1 + 1) begin : gen_butterfly_ctrl_stage
					localparam stg = _gv_stg_1;
					genvar _gv_seg_1;
					for (_gv_seg_1 = 0; _gv_seg_1 < (2 ** stg); _gv_seg_1 = _gv_seg_1 + 1) begin : gen_butterfly_ctrl
						localparam seg = _gv_seg_1;
						assign lrotc_stage[stg][((2 * (16 >> stg)) * (seg + 1)) - 1:(2 * (16 >> stg)) * seg] = {{16 >> stg {1'b0}}, {16 >> stg {1'b1}}} << bitcnt_partial_q[((32 - ((16 >> stg) * ((2 * seg) + 1))) * 6) + ($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) : ($clog2(16 >> stg) + ($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) + 1 : 1 - $clog2(16 >> stg))) - 1)-:($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) + 1 : 1 - $clog2(16 >> stg))];
						assign butterfly_mask_l[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)] = ~lrotc_stage[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)];
						assign butterfly_mask_r[stg][((16 >> stg) * ((2 * seg) + 1)) - 1:(16 >> stg) * (2 * seg)] = ~lrotc_stage[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)];
						assign butterfly_mask_l[stg][((16 >> stg) * ((2 * seg) + 1)) - 1:(16 >> stg) * (2 * seg)] = 1'sb0;
						assign butterfly_mask_r[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)] = 1'sb0;
					end
				end
				genvar _gv_stg_2;
				for (_gv_stg_2 = 0; _gv_stg_2 < 5; _gv_stg_2 = _gv_stg_2 + 1) begin : gen_butterfly_not
					localparam stg = _gv_stg_2;
					assign butterfly_mask_not[stg] = ~(butterfly_mask_l[stg] | butterfly_mask_r[stg]);
				end
				always @(*) begin
					if (_sv2v_0)
						;
					butterfly_result = operand_a_i;
					butterfly_result = ((butterfly_result & butterfly_mask_not[0]) | ((butterfly_result & butterfly_mask_l[0]) >> 16)) | ((butterfly_result & butterfly_mask_r[0]) << 16);
					butterfly_result = ((butterfly_result & butterfly_mask_not[1]) | ((butterfly_result & butterfly_mask_l[1]) >> 8)) | ((butterfly_result & butterfly_mask_r[1]) << 8);
					butterfly_result = ((butterfly_result & butterfly_mask_not[2]) | ((butterfly_result & butterfly_mask_l[2]) >> 4)) | ((butterfly_result & butterfly_mask_r[2]) << 4);
					butterfly_result = ((butterfly_result & butterfly_mask_not[3]) | ((butterfly_result & butterfly_mask_l[3]) >> 2)) | ((butterfly_result & butterfly_mask_r[3]) << 2);
					butterfly_result = ((butterfly_result & butterfly_mask_not[4]) | ((butterfly_result & butterfly_mask_l[4]) >> 1)) | ((butterfly_result & butterfly_mask_r[4]) << 1);
					butterfly_result = butterfly_result & operand_b_i;
				end
				always @(*) begin
					if (_sv2v_0)
						;
					invbutterfly_result = operand_a_i & operand_b_i;
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[4]) | ((invbutterfly_result & butterfly_mask_l[4]) >> 1)) | ((invbutterfly_result & butterfly_mask_r[4]) << 1);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[3]) | ((invbutterfly_result & butterfly_mask_l[3]) >> 2)) | ((invbutterfly_result & butterfly_mask_r[3]) << 2);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[2]) | ((invbutterfly_result & butterfly_mask_l[2]) >> 4)) | ((invbutterfly_result & butterfly_mask_r[2]) << 4);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[1]) | ((invbutterfly_result & butterfly_mask_l[1]) >> 8)) | ((invbutterfly_result & butterfly_mask_r[1]) << 8);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[0]) | ((invbutterfly_result & butterfly_mask_l[0]) >> 16)) | ((invbutterfly_result & butterfly_mask_r[0]) << 16);
				end
			end
			else begin : gen_alu_rvb_not_full
				wire [31:0] unused_imd_val_q_1;
				assign unused_imd_val_q_1 = imd_val_q_i[0+:32];
				wire [32:1] sv2v_tmp_98122;
				assign sv2v_tmp_98122 = 1'sb0;
				always @(*) butterfly_result = sv2v_tmp_98122;
				wire [32:1] sv2v_tmp_B39E0;
				assign sv2v_tmp_B39E0 = 1'sb0;
				always @(*) invbutterfly_result = sv2v_tmp_B39E0;
				assign bitcnt_partial_lsb_d = 1'sb0;
				assign bitcnt_partial_msb_d = 1'sb0;
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (operator_i)
					7'd45: begin
						multicycle_result = (operand_b_i == 32'h00000000 ? operand_a_i : imd_val_q_i[32+:32]);
						imd_val_d_o = {operand_a_i, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd46: begin
						multicycle_result = imd_val_q_i[32+:32] | bwlogic_and_result;
						imd_val_d_o = {bwlogic_and_result, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd48, 7'd47, 7'd14, 7'd13: begin
						if (shift_amt[4:0] == 5'h00)
							multicycle_result = (shift_amt[5] ? operand_a_i : imd_val_q_i[32+:32]);
						else
							multicycle_result = imd_val_q_i[32+:32] | shift_result;
						imd_val_d_o = {shift_result, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd63, 7'd64, 7'd61, 7'd62, 7'd59, 7'd60:
						if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
							(* full_case, parallel_case *)
							case (1'b1)
								crc_bmode: multicycle_result = clmul_result_rev ^ (operand_a_i >> 8);
								crc_hmode: multicycle_result = clmul_result_rev ^ (operand_a_i >> 16);
								default: multicycle_result = clmul_result_rev;
							endcase
							imd_val_d_o = {clmul_result_rev, 32'h00000000};
							if (instr_first_cycle_i)
								imd_val_we_o = 2'b01;
							else
								imd_val_we_o = 2'b00;
						end
						else begin
							imd_val_d_o = {operand_a_i, 32'h00000000};
							imd_val_we_o = 2'b00;
							multicycle_result = 1'sb0;
						end
					7'd53, 7'd54:
						if (RV32B == 32'sd3) begin
							multicycle_result = (operator_i == 7'd54 ? butterfly_result : invbutterfly_result);
							imd_val_d_o = {bitcnt_partial_lsb_d, bitcnt_partial_msb_d};
							if (instr_first_cycle_i)
								imd_val_we_o = 2'b11;
							else
								imd_val_we_o = 2'b00;
						end
						else begin
							imd_val_d_o = {operand_a_i, 32'h00000000};
							imd_val_we_o = 2'b00;
							multicycle_result = 1'sb0;
						end
					default: begin
						imd_val_d_o = {operand_a_i, 32'h00000000};
						imd_val_we_o = 2'b00;
						multicycle_result = 1'sb0;
					end
				endcase
			end
		end
		else begin : g_no_alu_rvb
			wire [63:0] unused_imd_val_q;
			assign unused_imd_val_q = imd_val_q_i;
			wire [31:0] unused_butterfly_result;
			assign unused_butterfly_result = butterfly_result;
			wire [31:0] unused_invbutterfly_result;
			assign unused_invbutterfly_result = invbutterfly_result;
			assign bitcnt_result = 1'sb0;
			assign minmax_result = 1'sb0;
			wire [32:1] sv2v_tmp_A0513;
			assign sv2v_tmp_A0513 = 1'sb0;
			always @(*) pack_result = sv2v_tmp_A0513;
			assign sext_result = 1'sb0;
			wire [32:1] sv2v_tmp_75CE4;
			assign sv2v_tmp_75CE4 = 1'sb0;
			always @(*) singlebit_result = sv2v_tmp_75CE4;
			wire [32:1] sv2v_tmp_FA09A;
			assign sv2v_tmp_FA09A = 1'sb0;
			always @(*) rev_result = sv2v_tmp_FA09A;
			wire [32:1] sv2v_tmp_4A308;
			assign sv2v_tmp_4A308 = 1'sb0;
			always @(*) shuffle_result = sv2v_tmp_4A308;
			assign xperm_result = 1'sb0;
			wire [32:1] sv2v_tmp_98122;
			assign sv2v_tmp_98122 = 1'sb0;
			always @(*) butterfly_result = sv2v_tmp_98122;
			wire [32:1] sv2v_tmp_B39E0;
			assign sv2v_tmp_B39E0 = 1'sb0;
			always @(*) invbutterfly_result = sv2v_tmp_B39E0;
			wire [32:1] sv2v_tmp_31DA6;
			assign sv2v_tmp_31DA6 = 1'sb0;
			always @(*) clmul_result = sv2v_tmp_31DA6;
			wire [32:1] sv2v_tmp_BC1B9;
			assign sv2v_tmp_BC1B9 = 1'sb0;
			always @(*) multicycle_result = sv2v_tmp_BC1B9;
			wire [64:1] sv2v_tmp_42A49;
			assign sv2v_tmp_42A49 = {2 {32'b00000000000000000000000000000000}};
			always @(*) imd_val_d_o = sv2v_tmp_42A49;
			wire [2:1] sv2v_tmp_0E15E;
			assign sv2v_tmp_0E15E = {2 {1'b0}};
			always @(*) imd_val_we_o = sv2v_tmp_0E15E;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		result_o = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd2, 7'd5, 7'd3, 7'd6, 7'd4, 7'd7: result_o = bwlogic_result;
			7'd0, 7'd1, 7'd22, 7'd23, 7'd24: result_o = adder_result;
			7'd10, 7'd9, 7'd8, 7'd12, 7'd11: result_o = shift_result;
			7'd17, 7'd18: result_o = shuffle_result;
			7'd19, 7'd20, 7'd21: result_o = xperm_result;
			7'd29, 7'd30, 7'd27, 7'd28, 7'd25, 7'd26, 7'd43, 7'd44: result_o = {31'h00000000, cmp_result};
			7'd31, 7'd33, 7'd32, 7'd34: result_o = minmax_result;
			7'd40, 7'd41, 7'd42: result_o = {26'h0000000, bitcnt_result};
			7'd35, 7'd37, 7'd36: result_o = pack_result;
			7'd38, 7'd39: result_o = sext_result;
			7'd46, 7'd45, 7'd47, 7'd48, 7'd14, 7'd13, 7'd63, 7'd64, 7'd61, 7'd62, 7'd59, 7'd60, 7'd53, 7'd54: result_o = multicycle_result;
			7'd49, 7'd50, 7'd51, 7'd52: result_o = singlebit_result;
			7'd15, 7'd16: result_o = rev_result;
			7'd55: result_o = bfp_result;
			7'd56, 7'd57, 7'd58: result_o = clmul_result;
			default:
				;
		endcase
	end
	wire unused_shift_amt_compl;
	assign unused_shift_amt_compl = shift_amt_compl[5];
	initial _sv2v_0 = 0;
endmodule
module ibex_branch_predict (
	clk_i,
	rst_ni,
	fetch_rdata_i,
	fetch_pc_i,
	fetch_valid_i,
	predict_branch_taken_o,
	predict_branch_pc_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] fetch_rdata_i;
	input wire [31:0] fetch_pc_i;
	input wire fetch_valid_i;
	output wire predict_branch_taken_o;
	output wire [31:0] predict_branch_pc_o;
	wire [31:0] imm_j_type;
	wire [31:0] imm_b_type;
	wire [31:0] imm_cj_type;
	wire [31:0] imm_cb_type;
	reg [31:0] branch_imm;
	wire [31:0] instr;
	wire instr_j;
	wire instr_b;
	wire instr_cj;
	wire instr_cb;
	wire instr_b_taken;
	assign instr = fetch_rdata_i;
	assign imm_j_type = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign imm_b_type = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_cj_type = {{20 {instr[12]}}, instr[12], instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};
	assign imm_cb_type = {{23 {instr[12]}}, instr[12], instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};
	assign instr_b = instr[6:0] == 7'h63;
	assign instr_j = instr[6:0] == 7'h6f;
	assign instr_cb = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b110) | (instr[15:13] == 3'b111));
	assign instr_cj = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b101) | (instr[15:13] == 3'b001));
	always @(*) begin
		if (_sv2v_0)
			;
		branch_imm = imm_b_type;
		(* full_case, parallel_case *)
		case (1'b1)
			instr_j: branch_imm = imm_j_type;
			instr_b: branch_imm = imm_b_type;
			instr_cj: branch_imm = imm_cj_type;
			instr_cb: branch_imm = imm_cb_type;
			default:
				;
		endcase
	end
	assign instr_b_taken = (instr_b & imm_b_type[31]) | (instr_cb & imm_cb_type[31]);
	assign predict_branch_taken_o = fetch_valid_i & ((instr_j | instr_cj) | instr_b_taken);
	assign predict_branch_pc_o = fetch_pc_i + branch_imm;
	initial _sv2v_0 = 0;
endmodule
module ibex_compressed_decoder (
	clk_i,
	rst_ni,
	valid_i,
	instr_i,
	instr_o,
	is_compressed_o,
	illegal_instr_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	input wire [31:0] instr_i;
	output reg [31:0] instr_o;
	output wire is_compressed_o;
	output reg illegal_instr_o;
	wire unused_valid;
	assign unused_valid = valid_i;
	always @(*) begin
		if (_sv2v_0)
			;
		instr_o = instr_i;
		illegal_instr_o = 1'b0;
		(* full_case, parallel_case *)
		case (instr_i[1:0])
			2'b00:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 12'h041, instr_i[4:2], 7'h13};
						if (instr_i[12:5] == 8'b00000000)
							illegal_instr_o = 1'b1;
					end
					3'b010: instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 4'b0001, instr_i[9:7], 5'b01001, instr_i[4:2], 7'h03};
					3'b110: instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 9'h023};
					3'b001, 3'b011, 3'b100, 3'b101, 3'b111: illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b01:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], 7'h13};
					3'b001, 3'b101: instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9 {instr_i[12]}}, 4'b0000, ~instr_i[15], 7'h6f};
					3'b010: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 8'b00000000, instr_i[11:7], 7'h13};
					3'b011: begin
						instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], 7'h37};
						if (instr_i[11:7] == 5'h02)
							instr_o = {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 24'h010113};
						if ({instr_i[12], instr_i[6:2]} == 6'b000000)
							illegal_instr_o = 1'b1;
					end
					3'b100:
						(* full_case, parallel_case *)
						case (instr_i[11:10])
							2'b00, 2'b01: begin
								instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], 7'h13};
								if (instr_i[12] == 1'b1)
									illegal_instr_o = 1'b1;
							end
							2'b10: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], 7'h13};
							2'b11:
								(* full_case, parallel_case *)
								case ({instr_i[12], instr_i[6:5]})
									3'b000: instr_o = {9'b010000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b00001, instr_i[9:7], 7'h33};
									3'b001: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b10001, instr_i[9:7], 7'h33};
									3'b010: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11001, instr_i[9:7], 7'h33};
									3'b011: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], 7'h33};
									3'b100, 3'b101, 3'b110, 3'b111: illegal_instr_o = 1'b1;
									default: illegal_instr_o = 1'b1;
								endcase
							default: illegal_instr_o = 1'b1;
						endcase
					3'b110, 3'b111: instr_o = {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 7'b0000001, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], 7'h63};
					default: illegal_instr_o = 1'b1;
				endcase
			2'b10:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], 7'h13};
						if (instr_i[12] == 1'b1)
							illegal_instr_o = 1'b1;
					end
					3'b010: begin
						instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 10'h012, instr_i[11:7], 7'h03};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
					end
					3'b100:
						if (instr_i[12] == 1'b0) begin
							if (instr_i[6:2] != 5'b00000)
								instr_o = {7'b0000000, instr_i[6:2], 8'b00000000, instr_i[11:7], 7'h33};
							else begin
								instr_o = {12'b000000000000, instr_i[11:7], 15'h0067};
								if (instr_i[11:7] == 5'b00000)
									illegal_instr_o = 1'b1;
							end
						end
						else if (instr_i[6:2] != 5'b00000)
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], 7'h33};
						else if (instr_i[11:7] == 5'b00000)
							instr_o = 32'h00100073;
						else
							instr_o = {12'b000000000000, instr_i[11:7], 15'h00e7};
					3'b110: instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 8'h12, instr_i[11:9], 9'h023};
					3'b001, 3'b011, 3'b101, 3'b111: illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b11:
				;
			default: illegal_instr_o = 1'b1;
		endcase
	end
	assign is_compressed_o = instr_i[1:0] != 2'b11;
	initial _sv2v_0 = 0;
endmodule
module ibex_controller (
	clk_i,
	rst_ni,
	ctrl_busy_o,
	illegal_insn_i,
	ecall_insn_i,
	mret_insn_i,
	dret_insn_i,
	wfi_insn_i,
	ebrk_insn_i,
	csr_pipe_flush_i,
	instr_valid_i,
	instr_i,
	instr_compressed_i,
	instr_is_compressed_i,
	instr_bp_taken_i,
	instr_fetch_err_i,
	instr_fetch_err_plus2_i,
	pc_id_i,
	instr_valid_clear_o,
	id_in_ready_o,
	controller_run_o,
	instr_exec_i,
	instr_req_o,
	pc_set_o,
	pc_mux_o,
	nt_branch_mispredict_o,
	exc_pc_mux_o,
	exc_cause_o,
	lsu_addr_last_i,
	load_err_i,
	store_err_i,
	mem_resp_intg_err_i,
	wb_exception_o,
	id_exception_o,
	branch_set_i,
	branch_not_set_i,
	jump_set_i,
	csr_mstatus_mie_i,
	irq_pending_i,
	irqs_i,
	irq_nm_ext_i,
	nmi_mode_o,
	debug_req_i,
	debug_cause_o,
	debug_csr_save_o,
	debug_mode_o,
	debug_mode_entering_o,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_wb_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	csr_mtval_o,
	priv_mode_i,
	stall_id_i,
	stall_wb_i,
	flush_id_o,
	ready_wb_i,
	perf_jump_o,
	perf_tbranch_o
);
	reg _sv2v_0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] MemECC = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	output reg ctrl_busy_o;
	input wire illegal_insn_i;
	input wire ecall_insn_i;
	input wire mret_insn_i;
	input wire dret_insn_i;
	input wire wfi_insn_i;
	input wire ebrk_insn_i;
	input wire csr_pipe_flush_i;
	input wire instr_valid_i;
	input wire [31:0] instr_i;
	input wire [15:0] instr_compressed_i;
	input wire instr_is_compressed_i;
	input wire instr_bp_taken_i;
	input wire instr_fetch_err_i;
	input wire instr_fetch_err_plus2_i;
	input wire [31:0] pc_id_i;
	output wire instr_valid_clear_o;
	output wire id_in_ready_o;
	output reg controller_run_o;
	input wire instr_exec_i;
	output reg instr_req_o;
	output reg pc_set_o;
	output reg [2:0] pc_mux_o;
	output reg nt_branch_mispredict_o;
	output reg [1:0] exc_pc_mux_o;
	output reg [6:0] exc_cause_o;
	input wire [31:0] lsu_addr_last_i;
	input wire load_err_i;
	input wire store_err_i;
	input wire mem_resp_intg_err_i;
	output wire wb_exception_o;
	output wire id_exception_o;
	input wire branch_set_i;
	input wire branch_not_set_i;
	input wire jump_set_i;
	input wire csr_mstatus_mie_i;
	input wire irq_pending_i;
	input wire [17:0] irqs_i;
	input wire irq_nm_ext_i;
	output wire nmi_mode_o;
	input wire debug_req_i;
	output wire [2:0] debug_cause_o;
	output reg debug_csr_save_o;
	output wire debug_mode_o;
	output reg debug_mode_entering_o;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	output reg csr_save_if_o;
	output reg csr_save_id_o;
	output reg csr_save_wb_o;
	output reg csr_restore_mret_id_o;
	output reg csr_restore_dret_id_o;
	output reg csr_save_cause_o;
	output reg [31:0] csr_mtval_o;
	input wire [1:0] priv_mode_i;
	input wire stall_id_i;
	input wire stall_wb_i;
	output wire flush_id_o;
	input wire ready_wb_i;
	output reg perf_jump_o;
	output reg perf_tbranch_o;
	reg [3:0] ctrl_fsm_cs;
	reg [3:0] ctrl_fsm_ns;
	reg nmi_mode_q;
	reg nmi_mode_d;
	reg debug_mode_q;
	reg debug_mode_d;
	wire [2:0] debug_cause_d;
	reg [2:0] debug_cause_q;
	reg load_err_q;
	wire load_err_d;
	reg store_err_q;
	wire store_err_d;
	reg exc_req_q;
	wire exc_req_d;
	reg illegal_insn_q;
	wire illegal_insn_d;
	reg instr_fetch_err_prio;
	reg illegal_insn_prio;
	reg ecall_insn_prio;
	reg ebrk_insn_prio;
	reg store_err_prio;
	reg load_err_prio;
	wire stall;
	reg halt_if;
	reg retain_id;
	reg flush_id;
	wire exc_req_lsu;
	wire special_req;
	wire special_req_pc_change;
	wire special_req_flush_only;
	wire do_single_step_d;
	reg do_single_step_q;
	wire enter_debug_mode_prio_d;
	reg enter_debug_mode_prio_q;
	wire enter_debug_mode;
	wire ebreak_into_debug;
	wire irq_enabled;
	wire handle_irq;
	wire id_wb_pending;
	wire irq_nm;
	wire irq_nm_int;
	wire [31:0] irq_nm_int_mtval;
	wire [4:0] irq_nm_int_cause;
	reg [3:0] mfip_id;
	wire unused_irq_timer;
	wire ecall_insn;
	wire mret_insn;
	wire dret_insn;
	wire wfi_insn;
	wire ebrk_insn;
	wire csr_pipe_flush;
	wire instr_fetch_err;
	assign load_err_d = load_err_i;
	assign store_err_d = store_err_i;
	assign ecall_insn = ecall_insn_i & instr_valid_i;
	assign mret_insn = mret_insn_i & instr_valid_i;
	assign dret_insn = dret_insn_i & instr_valid_i;
	assign wfi_insn = wfi_insn_i & instr_valid_i;
	assign ebrk_insn = ebrk_insn_i & instr_valid_i;
	assign csr_pipe_flush = csr_pipe_flush_i & instr_valid_i;
	assign instr_fetch_err = instr_fetch_err_i & instr_valid_i;
	assign illegal_insn_d = illegal_insn_i & (ctrl_fsm_cs != 4'd6);
	assign exc_req_d = (((ecall_insn | ebrk_insn) | illegal_insn_d) | instr_fetch_err) & (ctrl_fsm_cs != 4'd6);
	assign exc_req_lsu = store_err_i | load_err_i;
	assign id_exception_o = exc_req_d & ~wb_exception_o;
	assign special_req_flush_only = wfi_insn | csr_pipe_flush;
	assign special_req_pc_change = ((mret_insn | dret_insn) | exc_req_d) | exc_req_lsu;
	assign special_req = special_req_pc_change | special_req_flush_only;
	assign id_wb_pending = instr_valid_i | ~ready_wb_i;
	generate
		if (WritebackStage) begin : g_wb_exceptions
			always @(*) begin
				if (_sv2v_0)
					;
				instr_fetch_err_prio = 0;
				illegal_insn_prio = 0;
				ecall_insn_prio = 0;
				ebrk_insn_prio = 0;
				store_err_prio = 0;
				load_err_prio = 0;
				if (store_err_q)
					store_err_prio = 1'b1;
				else if (load_err_q)
					load_err_prio = 1'b1;
				else if (instr_fetch_err)
					instr_fetch_err_prio = 1'b1;
				else if (illegal_insn_q)
					illegal_insn_prio = 1'b1;
				else if (ecall_insn)
					ecall_insn_prio = 1'b1;
				else if (ebrk_insn)
					ebrk_insn_prio = 1'b1;
			end
			assign wb_exception_o = ((load_err_q | store_err_q) | load_err_i) | store_err_i;
		end
		else begin : g_no_wb_exceptions
			always @(*) begin
				if (_sv2v_0)
					;
				instr_fetch_err_prio = 0;
				illegal_insn_prio = 0;
				ecall_insn_prio = 0;
				ebrk_insn_prio = 0;
				store_err_prio = 0;
				load_err_prio = 0;
				if (instr_fetch_err)
					instr_fetch_err_prio = 1'b1;
				else if (illegal_insn_q)
					illegal_insn_prio = 1'b1;
				else if (ecall_insn)
					ecall_insn_prio = 1'b1;
				else if (ebrk_insn)
					ebrk_insn_prio = 1'b1;
				else if (store_err_q)
					store_err_prio = 1'b1;
				else if (load_err_q)
					load_err_prio = 1'b1;
			end
			assign wb_exception_o = 1'b0;
		end
		if (MemECC) begin : g_intg_irq_int
			reg mem_resp_intg_err_irq_pending_q;
			wire mem_resp_intg_err_irq_pending_d;
			reg [31:0] mem_resp_intg_err_addr_q;
			reg [31:0] mem_resp_intg_err_addr_d;
			reg mem_resp_intg_err_irq_set;
			reg mem_resp_intg_err_irq_clear;
			wire entering_nmi;
			assign entering_nmi = nmi_mode_d & ~nmi_mode_q;
			always @(*) begin
				if (_sv2v_0)
					;
				mem_resp_intg_err_addr_d = mem_resp_intg_err_addr_q;
				mem_resp_intg_err_irq_set = 1'b0;
				mem_resp_intg_err_irq_clear = 1'b0;
				if (mem_resp_intg_err_irq_pending_q) begin
					if (entering_nmi & !irq_nm_ext_i)
						mem_resp_intg_err_irq_clear = 1'b1;
				end
				else if (mem_resp_intg_err_i) begin
					mem_resp_intg_err_addr_d = lsu_addr_last_i;
					mem_resp_intg_err_irq_set = 1'b1;
				end
			end
			assign mem_resp_intg_err_irq_pending_d = (mem_resp_intg_err_irq_pending_q & ~mem_resp_intg_err_irq_clear) | mem_resp_intg_err_irq_set;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					mem_resp_intg_err_irq_pending_q <= 1'b0;
					mem_resp_intg_err_addr_q <= 1'sb0;
				end
				else begin
					mem_resp_intg_err_irq_pending_q <= mem_resp_intg_err_irq_pending_d;
					mem_resp_intg_err_addr_q <= mem_resp_intg_err_addr_d;
				end
			assign irq_nm_int = mem_resp_intg_err_irq_pending_q;
			assign irq_nm_int_cause = 5'b00000;
			assign irq_nm_int_mtval = mem_resp_intg_err_addr_q;
		end
		else begin : g_no_intg_irq_int
			wire unused_mem_resp_intg_err_i;
			assign unused_mem_resp_intg_err_i = mem_resp_intg_err_i;
			assign irq_nm_int = 1'b0;
			assign irq_nm_int_cause = 5'd0;
			assign irq_nm_int_mtval = 1'sb0;
		end
	endgenerate
	assign do_single_step_d = (instr_valid_i ? ~debug_mode_q & debug_single_step_i : do_single_step_q);
	assign enter_debug_mode_prio_d = (debug_req_i | do_single_step_d) & ~debug_mode_q;
	assign enter_debug_mode = enter_debug_mode_prio_d | (trigger_match_i & ~debug_mode_q);
	assign ebreak_into_debug = (priv_mode_i == 2'b11 ? debug_ebreakm_i : (priv_mode_i == 2'b00 ? debug_ebreaku_i : 1'b0));
	assign irq_nm = irq_nm_ext_i | irq_nm_int;
	assign irq_enabled = csr_mstatus_mie_i | (priv_mode_i == 2'b00);
	assign handle_irq = ((~debug_mode_q & ~debug_single_step_i) & ~nmi_mode_q) & (irq_nm | (irq_pending_i & irq_enabled));
	always @(*) begin : gen_mfip_id
		if (_sv2v_0)
			;
		mfip_id = 4'd0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 14; i >= 0; i = i - 1)
				if (irqs_i[0 + i])
					mfip_id = i[3:0];
		end
	end
	assign unused_irq_timer = irqs_i[16];
	assign debug_cause_d = (trigger_match_i ? 3'h2 : (ebrk_insn_prio & ebreak_into_debug ? 3'h1 : (debug_req_i ? 3'h3 : (do_single_step_d ? 3'h4 : 3'h0))));
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			debug_cause_q <= 3'h0;
		else
			debug_cause_q <= debug_cause_d;
	assign debug_cause_o = debug_cause_q;
	localparam [6:0] ibex_pkg_ExcCauseBreakpoint = 7'h03;
	localparam [6:0] ibex_pkg_ExcCauseEcallMMode = 7'h0b;
	localparam [6:0] ibex_pkg_ExcCauseEcallUMode = 7'h08;
	localparam [6:0] ibex_pkg_ExcCauseIllegalInsn = 7'h02;
	localparam [6:0] ibex_pkg_ExcCauseInsnAddrMisa = 7'h00;
	localparam [6:0] ibex_pkg_ExcCauseInstrAccessFault = 7'h01;
	localparam [6:0] ibex_pkg_ExcCauseIrqExternalM = 7'h2b;
	localparam [6:0] ibex_pkg_ExcCauseIrqNm = 7'h3f;
	localparam [6:0] ibex_pkg_ExcCauseIrqSoftwareM = 7'h23;
	localparam [6:0] ibex_pkg_ExcCauseIrqTimerM = 7'h27;
	localparam [6:0] ibex_pkg_ExcCauseLoadAccessFault = 7'h05;
	localparam [6:0] ibex_pkg_ExcCauseStoreAccessFault = 7'h07;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		instr_req_o = 1'b1;
		csr_save_if_o = 1'b0;
		csr_save_id_o = 1'b0;
		csr_save_wb_o = 1'b0;
		csr_restore_mret_id_o = 1'b0;
		csr_restore_dret_id_o = 1'b0;
		csr_save_cause_o = 1'b0;
		csr_mtval_o = 1'sb0;
		pc_mux_o = 3'd0;
		pc_set_o = 1'b0;
		nt_branch_mispredict_o = 1'b0;
		exc_pc_mux_o = 2'd1;
		exc_cause_o = ibex_pkg_ExcCauseInsnAddrMisa;
		ctrl_fsm_ns = ctrl_fsm_cs;
		ctrl_busy_o = 1'b1;
		halt_if = 1'b0;
		retain_id = 1'b0;
		flush_id = 1'b0;
		debug_csr_save_o = 1'b0;
		debug_mode_d = debug_mode_q;
		debug_mode_entering_o = 1'b0;
		nmi_mode_d = nmi_mode_q;
		perf_tbranch_o = 1'b0;
		perf_jump_o = 1'b0;
		controller_run_o = 1'b0;
		(* full_case, parallel_case *)
		case (ctrl_fsm_cs)
			4'd0: begin
				instr_req_o = 1'b0;
				pc_mux_o = 3'd0;
				pc_set_o = 1'b1;
				ctrl_fsm_ns = 4'd1;
			end
			4'd1: begin
				instr_req_o = 1'b1;
				pc_mux_o = 3'd0;
				pc_set_o = 1'b1;
				ctrl_fsm_ns = 4'd4;
			end
			4'd2: begin
				ctrl_busy_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if = 1'b1;
				flush_id = 1'b1;
				ctrl_fsm_ns = 4'd3;
			end
			4'd3: begin
				instr_req_o = 1'b0;
				halt_if = 1'b1;
				flush_id = 1'b1;
				if ((((irq_nm || irq_pending_i) || debug_req_i) || debug_mode_q) || debug_single_step_i)
					ctrl_fsm_ns = 4'd4;
				else
					ctrl_busy_o = 1'b0;
			end
			4'd4: begin
				if (id_in_ready_o)
					ctrl_fsm_ns = 4'd5;
				if (handle_irq) begin
					ctrl_fsm_ns = 4'd7;
					halt_if = 1'b1;
				end
				if (enter_debug_mode) begin
					ctrl_fsm_ns = 4'd8;
					halt_if = 1'b1;
				end
			end
			4'd5: begin
				controller_run_o = 1'b1;
				pc_mux_o = 3'd1;
				if (special_req) begin
					retain_id = 1'b1;
					if (ready_wb_i | wb_exception_o)
						ctrl_fsm_ns = 4'd6;
				end
				if (branch_set_i || jump_set_i) begin
					pc_set_o = (BranchPredictor ? ~instr_bp_taken_i : 1'b1);
					perf_tbranch_o = branch_set_i;
					perf_jump_o = jump_set_i;
				end
				if (BranchPredictor) begin
					if (instr_bp_taken_i & branch_not_set_i)
						nt_branch_mispredict_o = 1'b1;
				end
				if ((enter_debug_mode || handle_irq) && (stall || id_wb_pending))
					halt_if = 1'b1;
				if ((!stall && !special_req) && !id_wb_pending) begin
					if (enter_debug_mode) begin
						ctrl_fsm_ns = 4'd8;
						halt_if = 1'b1;
					end
					else if (handle_irq) begin
						ctrl_fsm_ns = 4'd7;
						halt_if = 1'b1;
					end
				end
			end
			4'd7: begin
				pc_mux_o = 3'd2;
				exc_pc_mux_o = 2'd1;
				if (handle_irq) begin
					pc_set_o = 1'b1;
					csr_save_if_o = 1'b1;
					csr_save_cause_o = 1'b1;
					if (irq_nm && !nmi_mode_q) begin
						exc_cause_o = (irq_nm_ext_i ? ibex_pkg_ExcCauseIrqNm : {2'b10, irq_nm_int_cause});
						if (irq_nm_int & !irq_nm_ext_i)
							csr_mtval_o = irq_nm_int_mtval;
						nmi_mode_d = 1'b1;
					end
					else if (irqs_i[14-:15] != 15'b000000000000000)
						exc_cause_o = {2'b01, sv2v_cast_5({1'b1, mfip_id})};
					else if (irqs_i[15])
						exc_cause_o = ibex_pkg_ExcCauseIrqExternalM;
					else if (irqs_i[17])
						exc_cause_o = ibex_pkg_ExcCauseIrqSoftwareM;
					else
						exc_cause_o = ibex_pkg_ExcCauseIrqTimerM;
				end
				ctrl_fsm_ns = 4'd5;
			end
			4'd8: begin
				pc_mux_o = 3'd2;
				exc_pc_mux_o = 2'd2;
				flush_id = 1'b1;
				pc_set_o = 1'b1;
				csr_save_if_o = 1'b1;
				debug_csr_save_o = 1'b1;
				csr_save_cause_o = 1'b1;
				debug_mode_d = 1'b1;
				debug_mode_entering_o = 1'b1;
				ctrl_fsm_ns = 4'd5;
			end
			4'd9: begin
				flush_id = 1'b1;
				pc_mux_o = 3'd2;
				pc_set_o = 1'b1;
				exc_pc_mux_o = 2'd2;
				if (ebreak_into_debug && !debug_mode_q) begin
					csr_save_cause_o = 1'b1;
					csr_save_id_o = 1'b1;
					debug_csr_save_o = 1'b1;
				end
				debug_mode_d = 1'b1;
				debug_mode_entering_o = 1'b1;
				ctrl_fsm_ns = 4'd5;
			end
			4'd6: begin
				halt_if = 1'b1;
				flush_id = 1'b1;
				ctrl_fsm_ns = 4'd5;
				if ((exc_req_q || store_err_q) || load_err_q) begin
					pc_set_o = 1'b1;
					pc_mux_o = 3'd2;
					exc_pc_mux_o = (debug_mode_q ? 2'd3 : 2'd0);
					if (WritebackStage) begin : g_writeback_mepc_save
						csr_save_id_o = ~(store_err_q | load_err_q);
						csr_save_wb_o = store_err_q | load_err_q;
					end
					else begin : g_no_writeback_mepc_save
						csr_save_id_o = 1'b0;
					end
					csr_save_cause_o = 1'b1;
					(* full_case, parallel_case *)
					case (1'b1)
						instr_fetch_err_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseInstrAccessFault;
							csr_mtval_o = (instr_fetch_err_plus2_i ? pc_id_i + 32'd2 : pc_id_i);
						end
						illegal_insn_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseIllegalInsn;
							csr_mtval_o = (instr_is_compressed_i ? {16'b0000000000000000, instr_compressed_i} : instr_i);
						end
						ecall_insn_prio: exc_cause_o = (priv_mode_i == 2'b11 ? ibex_pkg_ExcCauseEcallMMode : ibex_pkg_ExcCauseEcallUMode);
						ebrk_insn_prio:
							if (debug_mode_q | ebreak_into_debug) begin
								pc_set_o = 1'b0;
								csr_save_id_o = 1'b0;
								csr_save_cause_o = 1'b0;
								ctrl_fsm_ns = 4'd9;
								flush_id = 1'b0;
							end
							else
								exc_cause_o = ibex_pkg_ExcCauseBreakpoint;
						store_err_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseStoreAccessFault;
							csr_mtval_o = lsu_addr_last_i;
						end
						load_err_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseLoadAccessFault;
							csr_mtval_o = lsu_addr_last_i;
						end
						default:
							;
					endcase
				end
				else if (mret_insn) begin
					pc_mux_o = 3'd3;
					pc_set_o = 1'b1;
					csr_restore_mret_id_o = 1'b1;
					if (nmi_mode_q)
						nmi_mode_d = 1'b0;
				end
				else if (dret_insn) begin
					pc_mux_o = 3'd4;
					pc_set_o = 1'b1;
					debug_mode_d = 1'b0;
					csr_restore_dret_id_o = 1'b1;
				end
				else if (wfi_insn)
					ctrl_fsm_ns = 4'd2;
				if (enter_debug_mode_prio_q && !(ebrk_insn_prio && ebreak_into_debug))
					ctrl_fsm_ns = 4'd8;
			end
			default: begin
				instr_req_o = 1'b0;
				ctrl_fsm_ns = 4'd0;
			end
		endcase
		if (~instr_exec_i)
			halt_if = 1'b1;
	end
	assign flush_id_o = flush_id;
	assign debug_mode_o = debug_mode_q;
	assign nmi_mode_o = nmi_mode_q;
	assign stall = stall_id_i | stall_wb_i;
	assign id_in_ready_o = (~stall & ~halt_if) & ~retain_id;
	assign instr_valid_clear_o = ~(stall | retain_id) | flush_id;
	always @(posedge clk_i or negedge rst_ni) begin : update_regs
		if (!rst_ni) begin
			ctrl_fsm_cs <= 4'd0;
			nmi_mode_q <= 1'b0;
			do_single_step_q <= 1'b0;
			debug_mode_q <= 1'b0;
			enter_debug_mode_prio_q <= 1'b0;
			load_err_q <= 1'b0;
			store_err_q <= 1'b0;
			exc_req_q <= 1'b0;
			illegal_insn_q <= 1'b0;
		end
		else begin
			ctrl_fsm_cs <= ctrl_fsm_ns;
			nmi_mode_q <= nmi_mode_d;
			do_single_step_q <= do_single_step_d;
			debug_mode_q <= debug_mode_d;
			enter_debug_mode_prio_q <= enter_debug_mode_prio_d;
			load_err_q <= load_err_d;
			store_err_q <= store_err_d;
			exc_req_q <= exc_req_d;
			illegal_insn_q <= illegal_insn_d;
		end
	end
	initial _sv2v_0 = 0;
endmodule
module ibex_counter (
	clk_i,
	rst_ni,
	counter_inc_i,
	counterh_we_i,
	counter_we_i,
	counter_val_i,
	counter_val_o,
	counter_val_upd_o
);
	reg _sv2v_0;
	parameter signed [31:0] CounterWidth = 32;
	parameter [0:0] ProvideValUpd = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire counter_inc_i;
	input wire counterh_we_i;
	input wire counter_we_i;
	input wire [31:0] counter_val_i;
	output wire [63:0] counter_val_o;
	output wire [63:0] counter_val_upd_o;
	wire [63:0] counter;
	wire [CounterWidth - 1:0] counter_upd;
	reg [63:0] counter_load;
	reg we;
	reg [CounterWidth - 1:0] counter_d;
	assign counter_upd = counter[CounterWidth - 1:0] + {{CounterWidth - 1 {1'b0}}, 1'b1};
	always @(*) begin
		if (_sv2v_0)
			;
		we = counter_we_i | counterh_we_i;
		counter_load[63:32] = counter[63:32];
		counter_load[31:0] = counter_val_i;
		if (counterh_we_i) begin
			counter_load[63:32] = counter_val_i;
			counter_load[31:0] = counter[31:0];
		end
		if (we)
			counter_d = counter_load[CounterWidth - 1:0];
		else if (counter_inc_i)
			counter_d = counter_upd[CounterWidth - 1:0];
		else
			counter_d = counter[CounterWidth - 1:0];
	end
	localparam signed [31:0] UseDsp = "no";
	reg [CounterWidth - 1:0] counter_q;
	generate
		if (UseDsp == "yes") begin : g_cnt_dsp
			always @(posedge clk_i)
				if (!rst_ni)
					counter_q <= 1'sb0;
				else
					counter_q <= counter_d;
		end
		else begin : g_cnt_no_dsp
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					counter_q <= 1'sb0;
				else
					counter_q <= counter_d;
		end
		if (CounterWidth < 64) begin : g_counter_narrow
			wire [63:CounterWidth] unused_counter_load;
			assign counter[CounterWidth - 1:0] = counter_q;
			assign counter[63:CounterWidth] = 1'sb0;
			if (ProvideValUpd) begin : g_counter_val_upd_o
				assign counter_val_upd_o[CounterWidth - 1:0] = counter_upd;
			end
			else begin : g_no_counter_val_upd_o
				assign counter_val_upd_o[CounterWidth - 1:0] = 1'sb0;
			end
			assign counter_val_upd_o[63:CounterWidth] = 1'sb0;
			assign unused_counter_load = counter_load[63:CounterWidth];
		end
		else begin : g_counter_full
			assign counter = counter_q;
			if (ProvideValUpd) begin : g_counter_val_upd_o
				assign counter_val_upd_o = counter_upd;
			end
			else begin : g_no_counter_val_upd_o
				assign counter_val_upd_o = 1'sb0;
			end
		end
	endgenerate
	assign counter_val_o = counter;
	initial _sv2v_0 = 0;
endmodule
module ibex_cs_registers (
	clk_i,
	rst_ni,
	hart_id_i,
	priv_mode_id_o,
	priv_mode_lsu_o,
	csr_mstatus_tw_o,
	csr_mtvec_o,
	csr_mtvec_init_i,
	boot_addr_i,
	csr_access_i,
	csr_addr_i,
	csr_wdata_i,
	csr_op_i,
	csr_op_en_i,
	csr_rdata_o,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	nmi_mode_i,
	irq_pending_o,
	irqs_o,
	csr_mstatus_mie_o,
	csr_mepc_o,
	csr_mtval_o,
	csr_pmp_cfg_o,
	csr_pmp_addr_o,
	csr_pmp_mseccfg_o,
	debug_mode_i,
	debug_mode_entering_i,
	debug_cause_i,
	debug_csr_save_i,
	csr_depc_o,
	debug_single_step_o,
	debug_ebreakm_o,
	debug_ebreaku_o,
	trigger_match_o,
	pc_if_i,
	pc_id_i,
	pc_wb_i,
	data_ind_timing_o,
	dummy_instr_en_o,
	dummy_instr_mask_o,
	dummy_instr_seed_en_o,
	dummy_instr_seed_o,
	icache_enable_o,
	csr_shadow_err_o,
	ic_scr_key_valid_i,
	csr_save_if_i,
	csr_save_id_i,
	csr_save_wb_i,
	csr_restore_mret_i,
	csr_restore_dret_i,
	csr_save_cause_i,
	csr_mcause_i,
	csr_mtval_i,
	illegal_csr_insn_o,
	double_fault_seen_o,
	instr_ret_i,
	instr_ret_compressed_i,
	instr_ret_spec_i,
	instr_ret_compressed_spec_i,
	iside_wait_i,
	jump_i,
	branch_i,
	branch_taken_i,
	mem_load_i,
	mem_store_i,
	dside_wait_i,
	mul_wait_i,
	div_wait_i
);
	reg _sv2v_0;
	parameter [0:0] DbgTriggerEn = 0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] DataIndTiming = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] ShadowCSR = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [31:0] MHPMCounterNum = 10;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] PMPEnable = 0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	output wire [1:0] priv_mode_id_o;
	output wire [1:0] priv_mode_lsu_o;
	output wire csr_mstatus_tw_o;
	output wire [31:0] csr_mtvec_o;
	input wire csr_mtvec_init_i;
	input wire [31:0] boot_addr_i;
	input wire csr_access_i;
	input wire [11:0] csr_addr_i;
	input wire [31:0] csr_wdata_i;
	input wire [1:0] csr_op_i;
	input csr_op_en_i;
	output wire [31:0] csr_rdata_o;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire nmi_mode_i;
	output wire irq_pending_o;
	output wire [17:0] irqs_o;
	output wire csr_mstatus_mie_o;
	output wire [31:0] csr_mepc_o;
	output wire [31:0] csr_mtval_o;
	output wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg_o;
	output wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr_o;
	output wire [2:0] csr_pmp_mseccfg_o;
	input wire debug_mode_i;
	input wire debug_mode_entering_i;
	input wire [2:0] debug_cause_i;
	input wire debug_csr_save_i;
	output wire [31:0] csr_depc_o;
	output wire debug_single_step_o;
	output wire debug_ebreakm_o;
	output wire debug_ebreaku_o;
	output wire trigger_match_o;
	input wire [31:0] pc_if_i;
	input wire [31:0] pc_id_i;
	input wire [31:0] pc_wb_i;
	output wire data_ind_timing_o;
	output wire dummy_instr_en_o;
	output wire [2:0] dummy_instr_mask_o;
	output wire dummy_instr_seed_en_o;
	output wire [31:0] dummy_instr_seed_o;
	output wire icache_enable_o;
	output wire csr_shadow_err_o;
	input wire ic_scr_key_valid_i;
	input wire csr_save_if_i;
	input wire csr_save_id_i;
	input wire csr_save_wb_i;
	input wire csr_restore_mret_i;
	input wire csr_restore_dret_i;
	input wire csr_save_cause_i;
	input wire [6:0] csr_mcause_i;
	input wire [31:0] csr_mtval_i;
	output wire illegal_csr_insn_o;
	output reg double_fault_seen_o;
	input wire instr_ret_i;
	input wire instr_ret_compressed_i;
	input wire instr_ret_spec_i;
	input wire instr_ret_compressed_spec_i;
	input wire iside_wait_i;
	input wire jump_i;
	input wire branch_i;
	input wire branch_taken_i;
	input wire mem_load_i;
	input wire mem_store_i;
	input wire dside_wait_i;
	input wire mul_wait_i;
	input wire div_wait_i;
	function automatic is_mml_m_exec_cfg;
		input reg [5:0] pmp_cfg;
		reg unused_cfg;
		reg value;
		begin
			unused_cfg = ^{pmp_cfg[4-:2]};
			value = 1'b0;
			if (pmp_cfg[5])
				(* full_case, parallel_case *)
				case ({pmp_cfg[0], pmp_cfg[1], pmp_cfg[2]})
					3'b001, 3'b010, 3'b011, 3'b101: value = 1'b1;
					default: value = 1'b0;
				endcase
			is_mml_m_exec_cfg = value;
		end
	endfunction
	localparam [31:0] RV32BExtra = (RV32B != 32'sd0 ? 1 : 0);
	localparam [31:0] RV32MEnabled = (RV32M == 32'sd0 ? 0 : 1);
	localparam [31:0] PMPAddrWidth = (PMPGranularity > 0 ? 33 - PMPGranularity : 32);
	localparam [1:0] ibex_pkg_CSR_MISA_MXL = 2'd1;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	localparam [31:0] MISA_VALUE = ((((((((4 | (sv2v_cast_32(RV32E) << 4)) | 0) | (sv2v_cast_32(!RV32E) << 8)) | (RV32MEnabled << 12)) | 0) | 0) | 1048576) | (RV32BExtra << 23)) | (sv2v_cast_32(ibex_pkg_CSR_MISA_MXL) << 30);
	reg [31:0] exception_pc;
	reg [1:0] priv_lvl_q;
	reg [1:0] priv_lvl_d;
	wire [5:0] mstatus_q;
	reg [5:0] mstatus_d;
	wire mstatus_err;
	reg mstatus_en;
	wire [17:0] mie_q;
	wire [17:0] mie_d;
	reg mie_en;
	wire [31:0] mscratch_q;
	reg mscratch_en;
	wire [31:0] mepc_q;
	reg [31:0] mepc_d;
	reg mepc_en;
	wire [6:0] mcause_q;
	reg [6:0] mcause_d;
	reg mcause_en;
	wire [31:0] mtval_q;
	reg [31:0] mtval_d;
	reg mtval_en;
	wire [31:0] mtvec_q;
	reg [31:0] mtvec_d;
	wire mtvec_err;
	reg mtvec_en;
	wire [17:0] mip;
	wire [31:0] dcsr_q;
	reg [31:0] dcsr_d;
	reg dcsr_en;
	wire [31:0] depc_q;
	reg [31:0] depc_d;
	reg depc_en;
	wire [31:0] dscratch0_q;
	wire [31:0] dscratch1_q;
	reg dscratch0_en;
	reg dscratch1_en;
	wire [2:0] mstack_q;
	reg [2:0] mstack_d;
	reg mstack_en;
	wire [31:0] mstack_epc_q;
	reg [31:0] mstack_epc_d;
	wire [6:0] mstack_cause_q;
	reg [6:0] mstack_cause_d;
	localparam [31:0] ibex_pkg_PMP_MAX_REGIONS = 16;
	reg [31:0] pmp_addr_rdata [0:15];
	localparam [31:0] ibex_pkg_PMP_CFG_W = 8;
	wire [7:0] pmp_cfg_rdata [0:15];
	wire pmp_csr_err;
	wire [2:0] pmp_mseccfg;
	wire [31:0] mcountinhibit;
	reg [MHPMCounterNum + 2:0] mcountinhibit_d;
	reg [MHPMCounterNum + 2:0] mcountinhibit_q;
	reg mcountinhibit_we;
	wire [63:0] mhpmcounter [0:31];
	reg [31:0] mhpmcounter_we;
	reg [31:0] mhpmcounterh_we;
	reg [31:0] mhpmcounter_incr;
	reg [31:0] mhpmevent [0:31];
	wire [4:0] mhpmcounter_idx;
	wire unused_mhpmcounter_we_1;
	wire unused_mhpmcounterh_we_1;
	wire unused_mhpmcounter_incr_1;
	wire [63:0] minstret_next;
	wire [63:0] minstret_raw;
	wire [31:0] tselect_rdata;
	wire [31:0] tmatch_control_rdata;
	wire [31:0] tmatch_value_rdata;
	wire [7:0] cpuctrlsts_part_q;
	reg [7:0] cpuctrlsts_part_d;
	wire [7:0] cpuctrlsts_part_wdata_raw;
	wire [7:0] cpuctrlsts_part_wdata;
	reg cpuctrlsts_part_we;
	wire cpuctrlsts_part_err;
	wire cpuctrlsts_ic_scr_key_valid_q;
	wire cpuctrlsts_ic_scr_key_err;
	reg [31:0] csr_wdata_int;
	reg [31:0] csr_rdata_int;
	wire csr_we_int;
	wire csr_wr;
	reg dbg_csr;
	reg illegal_csr;
	wire illegal_csr_priv;
	wire illegal_csr_dbg;
	wire illegal_csr_write;
	wire [7:0] unused_boot_addr;
	wire [2:0] unused_csr_addr;
	assign unused_boot_addr = boot_addr_i[7:0];
	wire [11:0] csr_addr;
	assign csr_addr = {csr_addr_i};
	assign unused_csr_addr = csr_addr[7:5];
	assign mhpmcounter_idx = csr_addr[4:0];
	assign illegal_csr_dbg = dbg_csr & ~debug_mode_i;
	assign illegal_csr_priv = csr_addr[9:8] > {priv_lvl_q};
	assign illegal_csr_write = (csr_addr[11:10] == 2'b11) && csr_wr;
	assign illegal_csr_insn_o = csr_access_i & (((illegal_csr | illegal_csr_write) | illegal_csr_priv) | illegal_csr_dbg);
	assign mip[17] = irq_software_i;
	assign mip[16] = irq_timer_i;
	assign mip[15] = irq_external_i;
	assign mip[14-:15] = irq_fast_i;
	localparam [31:0] ibex_pkg_CSR_MARCHID_VALUE = 32'h00000016;
	localparam [31:0] ibex_pkg_CSR_MCONFIGPTR_VALUE = 32'b00000000000000000000000000000000;
	localparam [31:0] ibex_pkg_CSR_MEIX_BIT = 11;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_HIGH = 30;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_LOW = 16;
	localparam [31:0] ibex_pkg_CSR_MIMPID_VALUE = 32'b00000000000000000000000000000000;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MML_BIT = 0;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MMWP_BIT = 1;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_RLB_BIT = 2;
	localparam [31:0] ibex_pkg_CSR_MSIX_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MIE_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPIE_BIT = 7;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH = 12;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW = 11;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPRV_BIT = 17;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_TW_BIT = 21;
	localparam [31:0] ibex_pkg_CSR_MTIX_BIT = 7;
	localparam [31:0] ibex_pkg_CSR_MVENDORID_VALUE = 32'b00000000000000000000000000000000;
	always @(*) begin
		if (_sv2v_0)
			;
		csr_rdata_int = 1'sb0;
		illegal_csr = 1'b0;
		dbg_csr = 1'b0;
		(* full_case, parallel_case *)
		case (csr_addr_i)
			12'hf11: csr_rdata_int = ibex_pkg_CSR_MVENDORID_VALUE;
			12'hf12: csr_rdata_int = ibex_pkg_CSR_MARCHID_VALUE;
			12'hf13: csr_rdata_int = ibex_pkg_CSR_MIMPID_VALUE;
			12'hf14: csr_rdata_int = hart_id_i;
			12'hf15: csr_rdata_int = ibex_pkg_CSR_MCONFIGPTR_VALUE;
			12'h300: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT] = mstatus_q[5];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT] = mstatus_q[4];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW] = mstatus_q[3-:2];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT] = mstatus_q[1];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT] = mstatus_q[0];
			end
			12'h310: csr_rdata_int = 1'sb0;
			12'h30a, 12'h31a: csr_rdata_int = 1'sb0;
			12'h301: csr_rdata_int = MISA_VALUE;
			12'h304: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mie_q[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mie_q[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mie_q[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mie_q[14-:15];
			end
			12'h306: csr_rdata_int = 1'sb0;
			12'h340: csr_rdata_int = mscratch_q;
			12'h305: csr_rdata_int = mtvec_q;
			12'h341: csr_rdata_int = mepc_q;
			12'h342: csr_rdata_int = {mcause_q[5] | mcause_q[6], (mcause_q[6] ? {26 {1'b1}} : 26'b00000000000000000000000000), mcause_q[4:0]};
			12'h343: csr_rdata_int = mtval_q;
			12'h344: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mip[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mip[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mip[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mip[14-:15];
			end
			12'h747:
				if (PMPEnable) begin
					csr_rdata_int = 1'sb0;
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT] = pmp_mseccfg[0];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT] = pmp_mseccfg[1];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT] = pmp_mseccfg[2];
				end
				else
					illegal_csr = 1'b1;
			12'h757:
				if (PMPEnable)
					csr_rdata_int = 1'sb0;
				else
					illegal_csr = 1'b1;
			12'h3a0: csr_rdata_int = {pmp_cfg_rdata[3], pmp_cfg_rdata[2], pmp_cfg_rdata[1], pmp_cfg_rdata[0]};
			12'h3a1: csr_rdata_int = {pmp_cfg_rdata[7], pmp_cfg_rdata[6], pmp_cfg_rdata[5], pmp_cfg_rdata[4]};
			12'h3a2: csr_rdata_int = {pmp_cfg_rdata[11], pmp_cfg_rdata[10], pmp_cfg_rdata[9], pmp_cfg_rdata[8]};
			12'h3a3: csr_rdata_int = {pmp_cfg_rdata[15], pmp_cfg_rdata[14], pmp_cfg_rdata[13], pmp_cfg_rdata[12]};
			12'h3b0: csr_rdata_int = pmp_addr_rdata[0];
			12'h3b1: csr_rdata_int = pmp_addr_rdata[1];
			12'h3b2: csr_rdata_int = pmp_addr_rdata[2];
			12'h3b3: csr_rdata_int = pmp_addr_rdata[3];
			12'h3b4: csr_rdata_int = pmp_addr_rdata[4];
			12'h3b5: csr_rdata_int = pmp_addr_rdata[5];
			12'h3b6: csr_rdata_int = pmp_addr_rdata[6];
			12'h3b7: csr_rdata_int = pmp_addr_rdata[7];
			12'h3b8: csr_rdata_int = pmp_addr_rdata[8];
			12'h3b9: csr_rdata_int = pmp_addr_rdata[9];
			12'h3ba: csr_rdata_int = pmp_addr_rdata[10];
			12'h3bb: csr_rdata_int = pmp_addr_rdata[11];
			12'h3bc: csr_rdata_int = pmp_addr_rdata[12];
			12'h3bd: csr_rdata_int = pmp_addr_rdata[13];
			12'h3be: csr_rdata_int = pmp_addr_rdata[14];
			12'h3bf: csr_rdata_int = pmp_addr_rdata[15];
			12'h7b0: begin
				csr_rdata_int = dcsr_q;
				dbg_csr = 1'b1;
			end
			12'h7b1: begin
				csr_rdata_int = depc_q;
				dbg_csr = 1'b1;
			end
			12'h7b2: begin
				csr_rdata_int = dscratch0_q;
				dbg_csr = 1'b1;
			end
			12'h7b3: begin
				csr_rdata_int = dscratch1_q;
				dbg_csr = 1'b1;
			end
			12'h320: csr_rdata_int = mcountinhibit;
			12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_rdata_int = mhpmevent[mhpmcounter_idx];
			12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][31:0];
			12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][63:32];
			12'h7a0: begin
				csr_rdata_int = tselect_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a1: begin
				csr_rdata_int = tmatch_control_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a2: begin
				csr_rdata_int = tmatch_value_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a3: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h5a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7aa: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7c0: csr_rdata_int = {{23 {1'b0}}, cpuctrlsts_ic_scr_key_valid_q, cpuctrlsts_part_q};
			12'h7c1: csr_rdata_int = 1'sb0;
			default: illegal_csr = 1'b1;
		endcase
		if (!PMPEnable) begin
			if (|{csr_addr == 12'h3a0, csr_addr == 12'h3a1, csr_addr == 12'h3a2, csr_addr == 12'h3a3, csr_addr == 12'h3b0, csr_addr == 12'h3b1, csr_addr == 12'h3b2, csr_addr == 12'h3b3, csr_addr == 12'h3b4, csr_addr == 12'h3b5, csr_addr == 12'h3b6, csr_addr == 12'h3b7, csr_addr == 12'h3b8, csr_addr == 12'h3b9, csr_addr == 12'h3ba, csr_addr == 12'h3bb, csr_addr == 12'h3bc, csr_addr == 12'h3bd, csr_addr == 12'h3be, csr_addr == 12'h3bf})
				illegal_csr = 1'b1;
		end
	end
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		exception_pc = pc_id_i;
		priv_lvl_d = priv_lvl_q;
		mstatus_en = 1'b0;
		mstatus_d = mstatus_q;
		mie_en = 1'b0;
		mscratch_en = 1'b0;
		mepc_en = 1'b0;
		mepc_d = {csr_wdata_int[31:1], 1'b0};
		mcause_en = 1'b0;
		mcause_d = {csr_wdata_int[31:30] == 2'b11, csr_wdata_int[31:30] == 2'b10, csr_wdata_int[4:0]};
		mtval_en = 1'b0;
		mtval_d = csr_wdata_int;
		mtvec_en = csr_mtvec_init_i;
		mtvec_d = (csr_mtvec_init_i ? {boot_addr_i[31:8], 8'b00000001} : {csr_wdata_int[31:8], 8'b00000001});
		dcsr_en = 1'b0;
		dcsr_d = dcsr_q;
		depc_d = {csr_wdata_int[31:1], 1'b0};
		depc_en = 1'b0;
		dscratch0_en = 1'b0;
		dscratch1_en = 1'b0;
		mstack_en = 1'b0;
		mstack_d[2] = mstatus_q[4];
		mstack_d[1-:2] = mstatus_q[3-:2];
		mstack_epc_d = mepc_q;
		mstack_cause_d = mcause_q;
		mcountinhibit_we = 1'b0;
		mhpmcounter_we = 1'sb0;
		mhpmcounterh_we = 1'sb0;
		cpuctrlsts_part_we = 1'b0;
		cpuctrlsts_part_d = cpuctrlsts_part_q;
		double_fault_seen_o = 1'b0;
		if (csr_we_int)
			(* full_case, parallel_case *)
			case (csr_addr_i)
				12'h300: begin
					mstatus_en = 1'b1;
					mstatus_d = {csr_wdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT], sv2v_cast_2(csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW]), csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT]};
					if ((mstatus_d[3-:2] != 2'b11) && (mstatus_d[3-:2] != 2'b00))
						mstatus_d[3-:2] = 2'b00;
				end
				12'h304: mie_en = 1'b1;
				12'h340: mscratch_en = 1'b1;
				12'h341: mepc_en = 1'b1;
				12'h342: mcause_en = 1'b1;
				12'h343: mtval_en = 1'b1;
				12'h305: mtvec_en = 1'b1;
				12'h7b0: begin
					dcsr_d = csr_wdata_int;
					dcsr_d[31-:4] = 4'd4;
					if ((dcsr_d[1-:2] != 2'b11) && (dcsr_d[1-:2] != 2'b00))
						dcsr_d[1-:2] = 2'b00;
					dcsr_d[8-:3] = dcsr_q[8-:3];
					dcsr_d[11] = 1'b0;
					dcsr_d[3] = 1'b0;
					dcsr_d[4] = 1'b0;
					dcsr_d[10] = 1'b0;
					dcsr_d[9] = 1'b0;
					dcsr_d[5] = 1'b0;
					dcsr_d[14] = 1'b0;
					dcsr_d[27-:12] = 12'h000;
					dcsr_en = 1'b1;
				end
				12'h7b1: depc_en = 1'b1;
				12'h7b2: dscratch0_en = 1'b1;
				12'h7b3: dscratch1_en = 1'b1;
				12'h320: mcountinhibit_we = 1'b1;
				12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: mhpmcounter_we[mhpmcounter_idx] = 1'b1;
				12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: mhpmcounterh_we[mhpmcounter_idx] = 1'b1;
				12'h7c0: begin
					cpuctrlsts_part_d = cpuctrlsts_part_wdata;
					cpuctrlsts_part_we = 1'b1;
				end
				default:
					;
			endcase
		(* full_case, parallel_case *)
		case (1'b1)
			csr_save_cause_i: begin
				(* full_case, parallel_case *)
				case (1'b1)
					csr_save_if_i: exception_pc = pc_if_i;
					csr_save_id_i: exception_pc = pc_id_i;
					csr_save_wb_i: exception_pc = pc_wb_i;
					default:
						;
				endcase
				priv_lvl_d = 2'b11;
				if (debug_csr_save_i) begin
					dcsr_d[1-:2] = priv_lvl_q;
					dcsr_d[8-:3] = debug_cause_i;
					dcsr_en = 1'b1;
					depc_d = exception_pc;
					depc_en = 1'b1;
				end
				else if (!debug_mode_i) begin
					mtval_en = 1'b1;
					mtval_d = csr_mtval_i;
					mstatus_en = 1'b1;
					mstatus_d[5] = 1'b0;
					mstatus_d[4] = mstatus_q[5];
					mstatus_d[3-:2] = priv_lvl_q;
					mepc_en = 1'b1;
					mepc_d = exception_pc;
					mcause_en = 1'b1;
					mcause_d = csr_mcause_i;
					mstack_en = 1'b1;
					if (!(mcause_d[5] || mcause_d[6])) begin
						cpuctrlsts_part_we = 1'b1;
						cpuctrlsts_part_d[6] = 1'b1;
						if (cpuctrlsts_part_q[6]) begin
							double_fault_seen_o = 1'b1;
							cpuctrlsts_part_d[7] = 1'b1;
						end
					end
				end
			end
			csr_restore_dret_i: priv_lvl_d = dcsr_q[1-:2];
			csr_restore_mret_i: begin
				priv_lvl_d = mstatus_q[3-:2];
				mstatus_en = 1'b1;
				mstatus_d[5] = mstatus_q[4];
				if (mstatus_q[3-:2] != 2'b11)
					mstatus_d[1] = 1'b0;
				cpuctrlsts_part_we = 1'b1;
				cpuctrlsts_part_d[6] = 1'b0;
				if (nmi_mode_i) begin
					mstatus_d[4] = mstack_q[2];
					mstatus_d[3-:2] = mstack_q[1-:2];
					mepc_en = 1'b1;
					mepc_d = mstack_epc_q;
					mcause_en = 1'b1;
					mcause_d = mstack_cause_q;
				end
				else begin
					mstatus_d[4] = 1'b1;
					mstatus_d[3-:2] = 2'b00;
				end
			end
			default:
				;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			priv_lvl_q <= 2'b11;
		else
			priv_lvl_q <= priv_lvl_d;
	assign priv_mode_id_o = priv_lvl_q;
	assign priv_mode_lsu_o = (mstatus_q[1] ? mstatus_q[3-:2] : priv_lvl_q);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (csr_op_i)
			2'd1: csr_wdata_int = csr_wdata_i;
			2'd2: csr_wdata_int = csr_wdata_i | csr_rdata_o;
			2'd3: csr_wdata_int = ~csr_wdata_i & csr_rdata_o;
			2'd0: csr_wdata_int = csr_wdata_i;
			default: csr_wdata_int = csr_wdata_i;
		endcase
	end
	assign csr_wr = |{csr_op_i == 2'd1, csr_op_i == 2'd2, csr_op_i == 2'd3};
	assign csr_we_int = (csr_wr & csr_op_en_i) & ~illegal_csr_insn_o;
	assign csr_rdata_o = csr_rdata_int;
	assign csr_mepc_o = mepc_q;
	assign csr_depc_o = depc_q;
	assign csr_mtvec_o = mtvec_q;
	assign csr_mtval_o = mtval_q;
	assign csr_mstatus_mie_o = mstatus_q[5];
	assign csr_mstatus_tw_o = mstatus_q[0];
	assign debug_single_step_o = dcsr_q[2];
	assign debug_ebreakm_o = dcsr_q[15];
	assign debug_ebreaku_o = dcsr_q[12];
	assign irqs_o = mip & mie_q;
	assign irq_pending_o = |irqs_o;
	localparam [5:0] MSTATUS_RST_VAL = 6'b010000;
	ibex_csr #(
		.Width(6),
		.ShadowCopy(ShadowCSR),
		.ResetValue({MSTATUS_RST_VAL})
	) u_mstatus_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstatus_d}),
		.wr_en_i(mstatus_en),
		.rd_data_o(mstatus_q),
		.rd_error_o(mstatus_err)
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mepc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mepc_d),
		.wr_en_i(mepc_en),
		.rd_data_o(mepc_q),
		.rd_error_o()
	);
	assign mie_d[17] = csr_wdata_int[ibex_pkg_CSR_MSIX_BIT];
	assign mie_d[16] = csr_wdata_int[ibex_pkg_CSR_MTIX_BIT];
	assign mie_d[15] = csr_wdata_int[ibex_pkg_CSR_MEIX_BIT];
	assign mie_d[14-:15] = csr_wdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW];
	ibex_csr #(
		.Width(18),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mie_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mie_d}),
		.wr_en_i(mie_en),
		.rd_data_o(mie_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mscratch_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(mscratch_en),
		.rd_data_o(mscratch_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mcause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mcause_d}),
		.wr_en_i(mcause_en),
		.rd_data_o(mcause_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mtval_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtval_d),
		.wr_en_i(mtval_en),
		.rd_data_o(mtval_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(ShadowCSR),
		.ResetValue(32'd1)
	) u_mtvec_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtvec_d),
		.wr_en_i(mtvec_en),
		.rd_data_o(mtvec_q),
		.rd_error_o(mtvec_err)
	);
	localparam [31:0] DCSR_RESET_VAL = 32'h40000003;
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue({DCSR_RESET_VAL})
	) u_dcsr_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({dcsr_d}),
		.wr_en_i(dcsr_en),
		.rd_data_o(dcsr_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_depc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(depc_d),
		.wr_en_i(depc_en),
		.rd_data_o(depc_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch0_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(dscratch0_en),
		.rd_data_o(dscratch0_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch1_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(dscratch1_en),
		.rd_data_o(dscratch1_q),
		.rd_error_o()
	);
	localparam [2:0] MSTACK_RESET_VAL = 3'b100;
	ibex_csr #(
		.Width(3),
		.ShadowCopy(1'b0),
		.ResetValue({MSTACK_RESET_VAL})
	) u_mstack_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstack_d}),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_epc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_epc_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_epc_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_cause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_cause_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_cause_q),
		.rd_error_o()
	);
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_ADDR = 12'h3b0;
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_CFG = 12'h3a0;
	generate
		if (PMPEnable) begin : g_pmp_registers
			wire [2:0] pmp_mseccfg_q;
			wire [2:0] pmp_mseccfg_d;
			wire pmp_mseccfg_we;
			wire pmp_mseccfg_err;
			wire [5:0] pmp_cfg [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_locked;
			wire [PMPNumRegions - 1:0] pmp_cfg_wr_suppress;
			reg [5:0] pmp_cfg_wdata [0:PMPNumRegions - 1];
			wire [PMPAddrWidth - 1:0] pmp_addr [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_we;
			wire [PMPNumRegions - 1:0] pmp_cfg_err;
			wire [PMPNumRegions - 1:0] pmp_addr_we;
			wire [PMPNumRegions - 1:0] pmp_addr_err;
			wire any_pmp_entry_locked;
			genvar _gv_i_20;
			for (_gv_i_20 = 0; _gv_i_20 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_20 = _gv_i_20 + 1) begin : g_exp_rd_data
				localparam i = _gv_i_20;
				if (i < PMPNumRegions) begin : g_implemented_regions
					assign pmp_cfg_rdata[i] = {pmp_cfg[i][5], 2'b00, pmp_cfg[i][4-:2], pmp_cfg[i][2], pmp_cfg[i][1], pmp_cfg[i][0]};
					if (PMPGranularity == 0) begin : g_pmp_g0
						wire [32:1] sv2v_tmp_2683A;
						assign sv2v_tmp_2683A = pmp_addr[i];
						always @(*) pmp_addr_rdata[i] = sv2v_tmp_2683A;
					end
					else if (PMPGranularity == 1) begin : g_pmp_g1
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = pmp_addr[i];
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
					else begin : g_pmp_g2
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = {pmp_addr[i], {PMPGranularity - 1 {1'b1}}};
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
				end
				else begin : g_other_regions
					assign pmp_cfg_rdata[i] = 1'sb0;
					wire [32:1] sv2v_tmp_D50E5;
					assign sv2v_tmp_D50E5 = 1'sb0;
					always @(*) pmp_addr_rdata[i] = sv2v_tmp_D50E5;
				end
			end
			genvar _gv_i_21;
			for (_gv_i_21 = 0; _gv_i_21 < PMPNumRegions; _gv_i_21 = _gv_i_21 + 1) begin : g_pmp_csrs
				localparam i = _gv_i_21;
				assign pmp_cfg_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & ~pmp_cfg_wr_suppress[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_CFG + (i[11:0] >> 2)));
				wire [1:1] sv2v_tmp_8F287;
				assign sv2v_tmp_8F287 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 7];
				always @(*) pmp_cfg_wdata[i][5] = sv2v_tmp_8F287;
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 3+:2])
						2'b00: pmp_cfg_wdata[i][4-:2] = 2'b00;
						2'b01: pmp_cfg_wdata[i][4-:2] = 2'b01;
						2'b10: pmp_cfg_wdata[i][4-:2] = (PMPGranularity == 0 ? 2'b10 : 2'b00);
						2'b11: pmp_cfg_wdata[i][4-:2] = 2'b11;
						default: pmp_cfg_wdata[i][4-:2] = 2'b00;
					endcase
				end
				wire [1:1] sv2v_tmp_45785;
				assign sv2v_tmp_45785 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 2];
				always @(*) pmp_cfg_wdata[i][2] = sv2v_tmp_45785;
				wire [1:1] sv2v_tmp_BB30C;
				assign sv2v_tmp_BB30C = (pmp_mseccfg_q[0] ? csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 1] : &csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W+:2]);
				always @(*) pmp_cfg_wdata[i][1] = sv2v_tmp_BB30C;
				wire [1:1] sv2v_tmp_F1349;
				assign sv2v_tmp_F1349 = csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W];
				always @(*) pmp_cfg_wdata[i][0] = sv2v_tmp_F1349;
				ibex_csr #(
					.Width(6),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstCfg[(15 - i) * 6+:6])
				) u_pmp_cfg_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i({pmp_cfg_wdata[i]}),
					.wr_en_i(pmp_cfg_we[i]),
					.rd_data_o(pmp_cfg[i]),
					.rd_error_o(pmp_cfg_err[i])
				);
				assign pmp_cfg_locked[i] = pmp_cfg[i][5] & ~pmp_mseccfg_q[2];
				assign pmp_cfg_wr_suppress[i] = (pmp_mseccfg_q[0] & ~pmp_mseccfg[2]) & is_mml_m_exec_cfg(pmp_cfg_wdata[i]);
				if (i < (PMPNumRegions - 1)) begin : g_lower
					assign pmp_addr_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & (~pmp_cfg_locked[i + 1] | (pmp_cfg[i + 1][4-:2] != 2'b01))) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				else begin : g_upper
					assign pmp_addr_we[i] = (csr_we_int & ~pmp_cfg_locked[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				ibex_csr #(
					.Width(PMPAddrWidth),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstAddr[((15 - i) * 34) + 33-:PMPAddrWidth])
				) u_pmp_addr_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(csr_wdata_int[31-:PMPAddrWidth]),
					.wr_en_i(pmp_addr_we[i]),
					.rd_data_o(pmp_addr[i]),
					.rd_error_o(pmp_addr_err[i])
				);
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = pmp_cfg[i];
				assign csr_pmp_addr_o[((PMPNumRegions - 1) - i) * 34+:34] = {pmp_addr_rdata[i], 2'b00};
			end
			assign pmp_mseccfg_we = csr_we_int & (csr_addr == 12'h747);
			assign pmp_mseccfg_d[0] = (pmp_mseccfg_q[0] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT]);
			assign pmp_mseccfg_d[1] = (pmp_mseccfg_q[1] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT]);
			assign any_pmp_entry_locked = |pmp_cfg_locked;
			assign pmp_mseccfg_d[2] = (any_pmp_entry_locked ? 1'b0 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT]);
			ibex_csr #(
				.Width(3),
				.ShadowCopy(ShadowCSR),
				.ResetValue(PMPRstMsecCfg)
			) u_pmp_mseccfg(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(pmp_mseccfg_d),
				.wr_en_i(pmp_mseccfg_we),
				.rd_data_o(pmp_mseccfg_q),
				.rd_error_o(pmp_mseccfg_err)
			);
			assign pmp_csr_err = (|pmp_cfg_err | (|pmp_addr_err)) | pmp_mseccfg_err;
			assign pmp_mseccfg = pmp_mseccfg_q;
		end
		else begin : g_no_pmp_tieoffs
			genvar _gv_i_22;
			for (_gv_i_22 = 0; _gv_i_22 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_22 = _gv_i_22 + 1) begin : g_rdata
				localparam i = _gv_i_22;
				wire [32:1] sv2v_tmp_D50E5;
				assign sv2v_tmp_D50E5 = 1'sb0;
				always @(*) pmp_addr_rdata[i] = sv2v_tmp_D50E5;
				assign pmp_cfg_rdata[i] = 1'sb0;
			end
			genvar _gv_i_23;
			for (_gv_i_23 = 0; _gv_i_23 < PMPNumRegions; _gv_i_23 = _gv_i_23 + 1) begin : g_outputs
				localparam i = _gv_i_23;
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = 6'b000000;
				assign csr_pmp_addr_o[((PMPNumRegions - 1) - i) * 34+:34] = 1'sb0;
			end
			assign pmp_csr_err = 1'b0;
			assign pmp_mseccfg = 1'sb0;
		end
	endgenerate
	assign csr_pmp_mseccfg_o = pmp_mseccfg;
	always @(*) begin : mcountinhibit_update
		if (_sv2v_0)
			;
		if (mcountinhibit_we == 1'b1)
			mcountinhibit_d = {csr_wdata_int[MHPMCounterNum + 2:2], 1'b0, csr_wdata_int[0]};
		else
			mcountinhibit_d = mcountinhibit_q;
	end
	always @(*) begin : gen_mhpmcounter_incr
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmcounter_incr_inactive
					mhpmcounter_incr[i] = 1'b0;
				end
		end
		mhpmcounter_incr[0] = 1'b1;
		mhpmcounter_incr[1] = 1'b0;
		mhpmcounter_incr[2] = instr_ret_i;
		mhpmcounter_incr[3] = dside_wait_i;
		mhpmcounter_incr[4] = iside_wait_i;
		mhpmcounter_incr[5] = mem_load_i;
		mhpmcounter_incr[6] = mem_store_i;
		mhpmcounter_incr[7] = jump_i;
		mhpmcounter_incr[8] = branch_i;
		mhpmcounter_incr[9] = branch_taken_i;
		mhpmcounter_incr[10] = instr_ret_compressed_i;
		mhpmcounter_incr[11] = mul_wait_i;
		mhpmcounter_incr[12] = div_wait_i;
	end
	always @(*) begin : gen_mhpmevent
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmevent_active
					mhpmevent[i] = 1'sb0;
					if (i >= 3)
						mhpmevent[i][i - 3] = 1'b1;
				end
		end
		mhpmevent[1] = 1'sb0;
		begin : sv2v_autoblock_3
			reg [31:0] i;
			for (i = 3 + MHPMCounterNum; i < 32; i = i + 1)
				begin : gen_mhpmevent_inactive
					mhpmevent[i] = 1'sb0;
				end
		end
	end
	ibex_counter #(.CounterWidth(64)) mcycle_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[0] & ~mcountinhibit[0]),
		.counterh_we_i(mhpmcounterh_we[0]),
		.counter_we_i(mhpmcounter_we[0]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(mhpmcounter[0]),
		.counter_val_upd_o()
	);
	ibex_counter #(
		.CounterWidth(64),
		.ProvideValUpd(1)
	) minstret_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[2] & ~mcountinhibit[2]),
		.counterh_we_i(mhpmcounterh_we[2]),
		.counter_we_i(mhpmcounter_we[2]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(minstret_raw),
		.counter_val_upd_o(minstret_next)
	);
	assign mhpmcounter[2] = (instr_ret_spec_i & ~mcountinhibit[2] ? minstret_next : minstret_raw);
	assign mhpmcounter[1] = 1'sb0;
	assign unused_mhpmcounter_we_1 = mhpmcounter_we[1];
	assign unused_mhpmcounterh_we_1 = mhpmcounterh_we[1];
	assign unused_mhpmcounter_incr_1 = mhpmcounter_incr[1];
	genvar _gv_i_24;
	generate
		for (_gv_i_24 = 0; _gv_i_24 < 29; _gv_i_24 = _gv_i_24 + 1) begin : gen_cntrs
			localparam i = _gv_i_24;
			localparam signed [31:0] Cnt = i + 3;
			if (i < MHPMCounterNum) begin : gen_imp
				wire [63:0] mhpmcounter_raw;
				wire [63:0] mhpmcounter_next;
				ibex_counter #(
					.CounterWidth(MHPMCounterWidth),
					.ProvideValUpd(Cnt == 10)
				) mcounters_variable_i(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.counter_inc_i(mhpmcounter_incr[Cnt] & ~mcountinhibit[Cnt]),
					.counterh_we_i(mhpmcounterh_we[Cnt]),
					.counter_we_i(mhpmcounter_we[Cnt]),
					.counter_val_i(csr_wdata_int),
					.counter_val_o(mhpmcounter_raw),
					.counter_val_upd_o(mhpmcounter_next)
				);
				if (Cnt == 10) begin : gen_compressed_instr_cnt
					assign mhpmcounter[Cnt] = (instr_ret_compressed_spec_i & ~mcountinhibit[Cnt] ? mhpmcounter_next : mhpmcounter_raw);
				end
				else begin : gen_other_cnts
					wire [63:0] unused_mhpmcounter_next;
					assign mhpmcounter[Cnt] = mhpmcounter_raw;
					assign unused_mhpmcounter_next = mhpmcounter_next;
				end
			end
			else begin : gen_unimp
				assign mhpmcounter[Cnt] = 1'sb0;
				if (Cnt == 10) begin : gen_no_compressed_instr_cnt
					wire unused_instr_ret_compressed_spec_i;
					assign unused_instr_ret_compressed_spec_i = instr_ret_compressed_spec_i;
				end
			end
		end
		if (MHPMCounterNum < 29) begin : g_mcountinhibit_reduced
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounterh_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_incr;
			assign mcountinhibit = {{29 - MHPMCounterNum {1'b0}}, mcountinhibit_q};
			assign unused_mhphcounter_we = mhpmcounter_we[31:MHPMCounterNum + 3];
			assign unused_mhphcounterh_we = mhpmcounterh_we[31:MHPMCounterNum + 3];
			assign unused_mhphcounter_incr = mhpmcounter_incr[31:MHPMCounterNum + 3];
		end
		else begin : g_mcountinhibit_full
			assign mcountinhibit = mcountinhibit_q;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mcountinhibit_q <= 1'sb0;
		else
			mcountinhibit_q <= mcountinhibit_d;
	generate
		if (DbgTriggerEn) begin : gen_trigger_regs
			localparam [31:0] DbgHwNumLen = (DbgHwBreakNum > 1 ? $clog2(DbgHwBreakNum) : 1);
			localparam [31:0] MaxTselect = DbgHwBreakNum - 1;
			wire [DbgHwNumLen - 1:0] tselect_d;
			wire [DbgHwNumLen - 1:0] tselect_q;
			wire tmatch_control_d;
			wire [DbgHwBreakNum - 1:0] tmatch_control_q;
			wire [31:0] tmatch_value_d;
			wire [31:0] tmatch_value_q [0:DbgHwBreakNum - 1];
			wire selected_tmatch_control;
			wire [31:0] selected_tmatch_value;
			wire tselect_we;
			wire [DbgHwBreakNum - 1:0] tmatch_control_we;
			wire [DbgHwBreakNum - 1:0] tmatch_value_we;
			wire [DbgHwBreakNum - 1:0] trigger_match;
			assign tselect_we = (csr_we_int & debug_mode_i) & (csr_addr_i == 12'h7a0);
			genvar _gv_i_25;
			for (_gv_i_25 = 0; _gv_i_25 < DbgHwBreakNum; _gv_i_25 = _gv_i_25 + 1) begin : g_dbg_tmatch_we
				localparam i = _gv_i_25;
				assign tmatch_control_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a1);
				assign tmatch_value_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a2);
			end
			assign tselect_d = (csr_wdata_int < DbgHwBreakNum ? csr_wdata_int[DbgHwNumLen - 1:0] : MaxTselect[DbgHwNumLen - 1:0]);
			assign tmatch_control_d = csr_wdata_int[2];
			assign tmatch_value_d = csr_wdata_int[31:0];
			ibex_csr #(
				.Width(DbgHwNumLen),
				.ShadowCopy(1'b0),
				.ResetValue(1'sb0)
			) u_tselect_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(tselect_d),
				.wr_en_i(tselect_we),
				.rd_data_o(tselect_q),
				.rd_error_o()
			);
			genvar _gv_i_26;
			for (_gv_i_26 = 0; _gv_i_26 < DbgHwBreakNum; _gv_i_26 = _gv_i_26 + 1) begin : g_dbg_tmatch_reg
				localparam i = _gv_i_26;
				ibex_csr #(
					.Width(1),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_control_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_control_d),
					.wr_en_i(tmatch_control_we[i]),
					.rd_data_o(tmatch_control_q[i]),
					.rd_error_o()
				);
				ibex_csr #(
					.Width(32),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_value_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_value_d),
					.wr_en_i(tmatch_value_we[i]),
					.rd_data_o(tmatch_value_q[i]),
					.rd_error_o()
				);
			end
			localparam [31:0] TSelectRdataPadlen = (DbgHwNumLen >= 32 ? 0 : 32 - DbgHwNumLen);
			assign tselect_rdata = {{TSelectRdataPadlen {1'b0}}, tselect_q};
			if (DbgHwBreakNum > 1) begin : g_dbg_tmatch_multiple_select
				assign selected_tmatch_control = tmatch_control_q[tselect_q];
				assign selected_tmatch_value = tmatch_value_q[tselect_q];
			end
			else begin : g_dbg_tmatch_single_select
				assign selected_tmatch_control = tmatch_control_q[0];
				assign selected_tmatch_value = tmatch_value_q[0];
			end
			assign tmatch_control_rdata = {29'h05000209, selected_tmatch_control, 2'b00};
			assign tmatch_value_rdata = selected_tmatch_value;
			genvar _gv_i_27;
			for (_gv_i_27 = 0; _gv_i_27 < DbgHwBreakNum; _gv_i_27 = _gv_i_27 + 1) begin : g_dbg_trigger_match
				localparam i = _gv_i_27;
				assign trigger_match[i] = tmatch_control_q[i] & (pc_if_i[31:0] == tmatch_value_q[i]);
			end
			assign trigger_match_o = |trigger_match;
		end
		else begin : gen_no_trigger_regs
			assign tselect_rdata = 'b0;
			assign tmatch_control_rdata = 'b0;
			assign tmatch_value_rdata = 'b0;
			assign trigger_match_o = 'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata_raw = csr_wdata_int[7:0];
	generate
		if (DataIndTiming) begin : gen_dit
			assign cpuctrlsts_part_wdata[1] = cpuctrlsts_part_wdata_raw[1];
		end
		else begin : gen_no_dit
			wire unused_dit;
			assign unused_dit = cpuctrlsts_part_wdata_raw[1];
			assign cpuctrlsts_part_wdata[1] = 1'b0;
		end
	endgenerate
	assign data_ind_timing_o = cpuctrlsts_part_q[1];
	generate
		if (DummyInstructions) begin : gen_dummy
			assign cpuctrlsts_part_wdata[2] = cpuctrlsts_part_wdata_raw[2];
			assign cpuctrlsts_part_wdata[5-:3] = cpuctrlsts_part_wdata_raw[5-:3];
			assign dummy_instr_seed_en_o = csr_we_int && (csr_addr == 12'h7c1);
			assign dummy_instr_seed_o = csr_wdata_int;
		end
		else begin : gen_no_dummy
			wire unused_dummy_en;
			wire [2:0] unused_dummy_mask;
			assign unused_dummy_en = cpuctrlsts_part_wdata_raw[2];
			assign unused_dummy_mask = cpuctrlsts_part_wdata_raw[5-:3];
			assign cpuctrlsts_part_wdata[2] = 1'b0;
			assign cpuctrlsts_part_wdata[5-:3] = 3'b000;
			assign dummy_instr_seed_en_o = 1'b0;
			assign dummy_instr_seed_o = 1'sb0;
		end
	endgenerate
	assign dummy_instr_en_o = cpuctrlsts_part_q[2];
	assign dummy_instr_mask_o = cpuctrlsts_part_q[5-:3];
	generate
		if (ICache) begin : gen_icache_enable
			assign cpuctrlsts_part_wdata[0] = cpuctrlsts_part_wdata_raw[0];
			ibex_csr #(
				.Width(1),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'b0)
			) u_cpuctrlsts_ic_scr_key_valid_q_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(ic_scr_key_valid_i),
				.wr_en_i(1'b1),
				.rd_data_o(cpuctrlsts_ic_scr_key_valid_q),
				.rd_error_o(cpuctrlsts_ic_scr_key_err)
			);
		end
		else begin : gen_no_icache
			wire unused_icen;
			assign unused_icen = cpuctrlsts_part_wdata_raw[0];
			assign cpuctrlsts_part_wdata[0] = 1'b0;
			wire unused_ic_scr_key_valid;
			assign unused_ic_scr_key_valid = ic_scr_key_valid_i;
			assign cpuctrlsts_ic_scr_key_valid_q = 1'b0;
			assign cpuctrlsts_ic_scr_key_err = 1'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata[7] = cpuctrlsts_part_wdata_raw[7];
	assign cpuctrlsts_part_wdata[6] = cpuctrlsts_part_wdata_raw[6];
	assign icache_enable_o = cpuctrlsts_part_q[0] & ~(debug_mode_i | debug_mode_entering_i);
	ibex_csr #(
		.Width(8),
		.ShadowCopy(ShadowCSR),
		.ResetValue(1'sb0)
	) u_cpuctrlsts_part_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({cpuctrlsts_part_d}),
		.wr_en_i(cpuctrlsts_part_we),
		.rd_data_o(cpuctrlsts_part_q),
		.rd_error_o(cpuctrlsts_part_err)
	);
	assign csr_shadow_err_o = (((mstatus_err | mtvec_err) | pmp_csr_err) | cpuctrlsts_part_err) | cpuctrlsts_ic_scr_key_err;
	initial _sv2v_0 = 0;
endmodule
module ibex_csr (
	clk_i,
	rst_ni,
	wr_data_i,
	wr_en_i,
	rd_data_o,
	rd_error_o
);
	parameter [31:0] Width = 32;
	parameter [0:0] ShadowCopy = 1'b0;
	parameter [Width - 1:0] ResetValue = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire [Width - 1:0] wr_data_i;
	input wire wr_en_i;
	output wire [Width - 1:0] rd_data_o;
	output wire rd_error_o;
	reg [Width - 1:0] rdata_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rdata_q <= ResetValue;
		else if (wr_en_i)
			rdata_q <= wr_data_i;
	assign rd_data_o = rdata_q;
	generate
		if (ShadowCopy) begin : gen_shadow
			reg [Width - 1:0] shadow_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					shadow_q <= ~ResetValue;
				else if (wr_en_i)
					shadow_q <= ~wr_data_i;
			assign rd_error_o = rdata_q != ~shadow_q;
		end
		else begin : gen_no_shadow
			assign rd_error_o = 1'b0;
		end
	endgenerate
endmodule
module ibex_decoder (
	clk_i,
	rst_ni,
	illegal_insn_o,
	ebrk_insn_o,
	mret_insn_o,
	dret_insn_o,
	ecall_insn_o,
	wfi_insn_o,
	jump_set_o,
	branch_taken_i,
	icache_inval_o,
	instr_first_cycle_i,
	instr_rdata_i,
	instr_rdata_alu_i,
	illegal_c_insn_i,
	imm_a_mux_sel_o,
	imm_b_mux_sel_o,
	bt_a_mux_sel_o,
	bt_b_mux_sel_o,
	imm_i_type_o,
	imm_s_type_o,
	imm_b_type_o,
	imm_u_type_o,
	imm_j_type_o,
	zimm_rs1_type_o,
	rf_wdata_sel_o,
	rf_we_o,
	rf_raddr_a_o,
	rf_raddr_b_o,
	rf_waddr_o,
	rf_ren_a_o,
	rf_ren_b_o,
	alu_operator_o,
	alu_op_a_mux_sel_o,
	alu_op_b_mux_sel_o,
	alu_multicycle_o,
	mult_en_o,
	div_en_o,
	mult_sel_o,
	div_sel_o,
	multdiv_operator_o,
	multdiv_signed_mode_o,
	csr_access_o,
	csr_op_o,
	data_req_o,
	data_we_o,
	data_type_o,
	data_sign_extension_o,
	jump_in_dec_o,
	branch_in_dec_o
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 0;
	input wire clk_i;
	input wire rst_ni;
	output wire illegal_insn_o;
	output reg ebrk_insn_o;
	output reg mret_insn_o;
	output reg dret_insn_o;
	output reg ecall_insn_o;
	output reg wfi_insn_o;
	output reg jump_set_o;
	input wire branch_taken_i;
	output reg icache_inval_o;
	input wire instr_first_cycle_i;
	input wire [31:0] instr_rdata_i;
	input wire [31:0] instr_rdata_alu_i;
	input wire illegal_c_insn_i;
	output reg imm_a_mux_sel_o;
	output reg [2:0] imm_b_mux_sel_o;
	output reg [1:0] bt_a_mux_sel_o;
	output reg [2:0] bt_b_mux_sel_o;
	output wire [31:0] imm_i_type_o;
	output wire [31:0] imm_s_type_o;
	output wire [31:0] imm_b_type_o;
	output wire [31:0] imm_u_type_o;
	output wire [31:0] imm_j_type_o;
	output wire [31:0] zimm_rs1_type_o;
	output reg rf_wdata_sel_o;
	output wire rf_we_o;
	output wire [4:0] rf_raddr_a_o;
	output wire [4:0] rf_raddr_b_o;
	output wire [4:0] rf_waddr_o;
	output reg rf_ren_a_o;
	output reg rf_ren_b_o;
	output reg [6:0] alu_operator_o;
	output reg [1:0] alu_op_a_mux_sel_o;
	output reg alu_op_b_mux_sel_o;
	output reg alu_multicycle_o;
	output wire mult_en_o;
	output wire div_en_o;
	output reg mult_sel_o;
	output reg div_sel_o;
	output reg [1:0] multdiv_operator_o;
	output reg [1:0] multdiv_signed_mode_o;
	output reg csr_access_o;
	output reg [1:0] csr_op_o;
	output reg data_req_o;
	output reg data_we_o;
	output reg [1:0] data_type_o;
	output reg data_sign_extension_o;
	output reg jump_in_dec_o;
	output reg branch_in_dec_o;
	reg illegal_insn;
	wire illegal_reg_rv32e;
	reg csr_illegal;
	reg rf_we;
	wire [31:0] instr;
	wire [31:0] instr_alu;
	wire [9:0] unused_instr_alu;
	wire [4:0] instr_rs1;
	wire [4:0] instr_rs2;
	wire [4:0] instr_rs3;
	wire [4:0] instr_rd;
	reg use_rs3_d;
	reg use_rs3_q;
	reg [1:0] csr_op;
	reg [6:0] opcode;
	reg [6:0] opcode_alu;
	assign instr = instr_rdata_i;
	assign instr_alu = instr_rdata_alu_i;
	assign imm_i_type_o = {{20 {instr[31]}}, instr[31:20]};
	assign imm_s_type_o = {{20 {instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_b_type_o = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_u_type_o = {instr[31:12], 12'b000000000000};
	assign imm_j_type_o = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign zimm_rs1_type_o = {27'b000000000000000000000000000, instr_rs1};
	generate
		if (RV32B != 32'sd0) begin : gen_rs3_flop
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					use_rs3_q <= 1'b0;
				else
					use_rs3_q <= use_rs3_d;
		end
		else begin : gen_no_rs3_flop
			wire unused_clk;
			wire unused_rst_n;
			assign unused_clk = clk_i;
			assign unused_rst_n = rst_ni;
			wire [1:1] sv2v_tmp_12378;
			assign sv2v_tmp_12378 = use_rs3_d;
			always @(*) use_rs3_q = sv2v_tmp_12378;
		end
	endgenerate
	assign instr_rs1 = instr[19:15];
	assign instr_rs2 = instr[24:20];
	assign instr_rs3 = instr[31:27];
	assign rf_raddr_a_o = (use_rs3_q & ~instr_first_cycle_i ? instr_rs3 : instr_rs1);
	assign rf_raddr_b_o = instr_rs2;
	assign instr_rd = instr[11:7];
	assign rf_waddr_o = instr_rd;
	generate
		if (RV32E) begin : gen_rv32e_reg_check_active
			assign illegal_reg_rv32e = ((rf_raddr_a_o[4] & (alu_op_a_mux_sel_o == 2'd0)) | (rf_raddr_b_o[4] & (alu_op_b_mux_sel_o == 1'd0))) | (rf_waddr_o[4] & rf_we);
		end
		else begin : gen_rv32e_reg_check_inactive
			assign illegal_reg_rv32e = 1'b0;
		end
	endgenerate
	always @(*) begin : csr_operand_check
		if (_sv2v_0)
			;
		csr_op_o = csr_op;
		if (((csr_op == 2'd2) || (csr_op == 2'd3)) && (instr_rs1 == {5 {1'sb0}}))
			csr_op_o = 2'd0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		jump_in_dec_o = 1'b0;
		jump_set_o = 1'b0;
		branch_in_dec_o = 1'b0;
		icache_inval_o = 1'b0;
		multdiv_operator_o = 2'd0;
		multdiv_signed_mode_o = 2'b00;
		rf_wdata_sel_o = 1'd0;
		rf_we = 1'b0;
		rf_ren_a_o = 1'b0;
		rf_ren_b_o = 1'b0;
		csr_access_o = 1'b0;
		csr_illegal = 1'b0;
		csr_op = 2'd0;
		data_we_o = 1'b0;
		data_type_o = 2'b00;
		data_sign_extension_o = 1'b0;
		data_req_o = 1'b0;
		illegal_insn = 1'b0;
		ebrk_insn_o = 1'b0;
		mret_insn_o = 1'b0;
		dret_insn_o = 1'b0;
		ecall_insn_o = 1'b0;
		wfi_insn_o = 1'b0;
		opcode = instr[6:0];
		(* full_case, parallel_case *)
		case (opcode)
			7'h6f: begin
				jump_in_dec_o = 1'b1;
				if (instr_first_cycle_i) begin
					rf_we = BranchTargetALU;
					jump_set_o = 1'b1;
				end
				else
					rf_we = 1'b1;
			end
			7'h67: begin
				jump_in_dec_o = 1'b1;
				if (instr_first_cycle_i) begin
					rf_we = BranchTargetALU;
					jump_set_o = 1'b1;
				end
				else
					rf_we = 1'b1;
				if (instr[14:12] != 3'b000)
					illegal_insn = 1'b1;
				rf_ren_a_o = 1'b1;
			end
			7'h63: begin
				branch_in_dec_o = 1'b1;
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: illegal_insn = 1'b0;
					default: illegal_insn = 1'b1;
				endcase
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
			end
			7'h23: begin
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
				data_req_o = 1'b1;
				data_we_o = 1'b1;
				if (instr[14])
					illegal_insn = 1'b1;
				(* full_case, parallel_case *)
				case (instr[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: data_type_o = 2'b00;
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h03: begin
				rf_ren_a_o = 1'b1;
				data_req_o = 1'b1;
				data_type_o = 2'b00;
				data_sign_extension_o = ~instr[14];
				(* full_case, parallel_case *)
				case (instr[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: begin
						data_type_o = 2'b00;
						if (instr[14])
							illegal_insn = 1'b1;
					end
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h37: rf_we = 1'b1;
			7'h17: rf_we = 1'b1;
			7'h13: begin
				rf_ren_a_o = 1'b1;
				rf_we = 1'b1;
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000, 3'b010, 3'b011, 3'b100, 3'b110, 3'b111: illegal_insn = 1'b0;
					3'b001:
						(* full_case, parallel_case *)
						case (instr[31:27])
							5'b00000: illegal_insn = (instr[26:25] == 2'b00 ? 1'b0 : 1'b1);
							5'b00100: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
							5'b01001, 5'b00101, 5'b01101: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
							5'b00001:
								if (instr[26] == 1'b0)
									illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
								else
									illegal_insn = 1'b1;
							5'b01100:
								(* full_case, parallel_case *)
								case (instr[26:20])
									7'b0000000, 7'b0000001, 7'b0000010, 7'b0000100, 7'b0000101: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
									7'b0010000, 7'b0010001, 7'b0010010, 7'b0011000, 7'b0011001, 7'b0011010: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
									default: illegal_insn = 1'b1;
								endcase
							default: illegal_insn = 1'b1;
						endcase
					3'b101:
						if (instr[26])
							illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
						else
							(* full_case, parallel_case *)
							case (instr[31:27])
								5'b00000, 5'b01000: illegal_insn = (instr[26:25] == 2'b00 ? 1'b0 : 1'b1);
								5'b00100: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
								5'b01100, 5'b01001: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
								5'b01101:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										illegal_insn = 1'b0;
									else if (RV32B == 32'sd1)
										illegal_insn = (instr[24:20] == 5'b11000 ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								5'b00101:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										illegal_insn = 1'b0;
									else if (instr[24:20] == 5'b00111)
										illegal_insn = (RV32B == 32'sd1 ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								5'b00001:
									if (instr[26] == 1'b0)
										illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								default: illegal_insn = 1'b1;
							endcase
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h33: begin
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
				rf_we = 1'b1;
				if ({instr[26], instr[13:12]} == 3'b101)
					illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
				else
					(* full_case, parallel_case *)
					case ({instr[31:25], instr[14:12]})
						10'b0000000000, 10'b0100000000, 10'b0000000010, 10'b0000000011, 10'b0000000100, 10'b0000000110, 10'b0000000111, 10'b0000000001, 10'b0000000101, 10'b0100000101: illegal_insn = 1'b0;
						10'b0010000010, 10'b0010000100, 10'b0010000110, 10'b0100000111, 10'b0100000110, 10'b0100000100, 10'b0110000001, 10'b0110000101, 10'b0000101100, 10'b0000101110, 10'b0000101101, 10'b0000101111, 10'b0000100100, 10'b0100100100, 10'b0000100111, 10'b0100100001, 10'b0010100001, 10'b0110100001, 10'b0100100101, 10'b0100100111: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
						10'b0110100101, 10'b0010100101, 10'b0000100001, 10'b0000100101, 10'b0010100010, 10'b0010100100, 10'b0010100110, 10'b0010000001, 10'b0010000101, 10'b0000101001, 10'b0000101010, 10'b0000101011: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
						10'b0100100110, 10'b0000100110: illegal_insn = (RV32B == 32'sd3 ? 1'b0 : 1'b1);
						10'b0000001000: begin
							multdiv_operator_o = 2'd0;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001001: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001010: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b01;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001011: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001100: begin
							multdiv_operator_o = 2'd2;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001101: begin
							multdiv_operator_o = 2'd2;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001110: begin
							multdiv_operator_o = 2'd3;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001111: begin
							multdiv_operator_o = 2'd3;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						default: illegal_insn = 1'b1;
					endcase
			end
			7'h0f:
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000: rf_we = 1'b0;
					3'b001: begin
						jump_in_dec_o = 1'b1;
						rf_we = 1'b0;
						if (instr_first_cycle_i) begin
							jump_set_o = 1'b1;
							icache_inval_o = 1'b1;
						end
					end
					default: illegal_insn = 1'b1;
				endcase
			7'h73:
				if (instr[14:12] == 3'b000) begin
					(* full_case, parallel_case *)
					case (instr[31:20])
						12'h000: ecall_insn_o = 1'b1;
						12'h001: ebrk_insn_o = 1'b1;
						12'h302: mret_insn_o = 1'b1;
						12'h7b2: dret_insn_o = 1'b1;
						12'h105: wfi_insn_o = 1'b1;
						default: illegal_insn = 1'b1;
					endcase
					if ((instr_rs1 != 5'b00000) || (instr_rd != 5'b00000))
						illegal_insn = 1'b1;
				end
				else begin
					csr_access_o = 1'b1;
					rf_wdata_sel_o = 1'd1;
					rf_we = 1'b1;
					if (~instr[14])
						rf_ren_a_o = 1'b1;
					(* full_case, parallel_case *)
					case (instr[13:12])
						2'b01: csr_op = 2'd1;
						2'b10: csr_op = 2'd2;
						2'b11: csr_op = 2'd3;
						default: csr_illegal = 1'b1;
					endcase
					illegal_insn = csr_illegal;
				end
			default: illegal_insn = 1'b1;
		endcase
		if (illegal_c_insn_i)
			illegal_insn = 1'b1;
		if (illegal_insn) begin
			rf_we = 1'b0;
			data_req_o = 1'b0;
			data_we_o = 1'b0;
			jump_in_dec_o = 1'b0;
			jump_set_o = 1'b0;
			branch_in_dec_o = 1'b0;
			csr_access_o = 1'b0;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		alu_operator_o = 7'd44;
		alu_op_a_mux_sel_o = 2'd3;
		alu_op_b_mux_sel_o = 1'd1;
		imm_a_mux_sel_o = 1'd1;
		imm_b_mux_sel_o = 3'd0;
		bt_a_mux_sel_o = 2'd2;
		bt_b_mux_sel_o = 3'd0;
		opcode_alu = instr_alu[6:0];
		use_rs3_d = 1'b0;
		alu_multicycle_o = 1'b0;
		mult_sel_o = 1'b0;
		div_sel_o = 1'b0;
		(* full_case, parallel_case *)
		case (opcode_alu)
			7'h6f: begin
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd2;
					bt_b_mux_sel_o = 3'd4;
				end
				if (instr_first_cycle_i && !BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd4;
					alu_operator_o = 7'd0;
				end
				else begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd5;
					alu_operator_o = 7'd0;
				end
			end
			7'h67: begin
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd0;
					bt_b_mux_sel_o = 3'd0;
				end
				if (instr_first_cycle_i && !BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd0;
					alu_operator_o = 7'd0;
				end
				else begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd5;
					alu_operator_o = 7'd0;
				end
			end
			7'h63: begin
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: alu_operator_o = 7'd29;
					3'b001: alu_operator_o = 7'd30;
					3'b100: alu_operator_o = 7'd25;
					3'b101: alu_operator_o = 7'd27;
					3'b110: alu_operator_o = 7'd26;
					3'b111: alu_operator_o = 7'd28;
					default:
						;
				endcase
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd2;
					bt_b_mux_sel_o = (branch_taken_i ? 3'd2 : 3'd5);
				end
				if (instr_first_cycle_i) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd0;
				end
				else if (!BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = (branch_taken_i ? 3'd2 : 3'd5);
					alu_operator_o = 7'd0;
				end
			end
			7'h23: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd0;
				alu_operator_o = 7'd0;
				if (!instr_alu[14]) begin
					imm_b_mux_sel_o = 3'd1;
					alu_op_b_mux_sel_o = 1'd1;
				end
			end
			7'h03: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_operator_o = 7'd0;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd0;
			end
			7'h37: begin
				alu_op_a_mux_sel_o = 2'd3;
				alu_op_b_mux_sel_o = 1'd1;
				imm_a_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd3;
				alu_operator_o = 7'd0;
			end
			7'h17: begin
				alu_op_a_mux_sel_o = 2'd2;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd3;
				alu_operator_o = 7'd0;
			end
			7'h13: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd0;
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: alu_operator_o = 7'd0;
					3'b010: alu_operator_o = 7'd43;
					3'b011: alu_operator_o = 7'd44;
					3'b100: alu_operator_o = 7'd2;
					3'b110: alu_operator_o = 7'd3;
					3'b111: alu_operator_o = 7'd4;
					3'b001:
						if (RV32B != 32'sd0)
							(* full_case, parallel_case *)
							case (instr_alu[31:27])
								5'b00000: alu_operator_o = 7'd10;
								5'b00100:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										alu_operator_o = 7'd12;
								5'b01001: alu_operator_o = 7'd50;
								5'b00101: alu_operator_o = 7'd49;
								5'b01101: alu_operator_o = 7'd51;
								5'b00001:
									if (instr_alu[26] == 0)
										alu_operator_o = 7'd17;
								5'b01100:
									(* full_case, parallel_case *)
									case (instr_alu[26:20])
										7'b0000000: alu_operator_o = 7'd40;
										7'b0000001: alu_operator_o = 7'd41;
										7'b0000010: alu_operator_o = 7'd42;
										7'b0000100: alu_operator_o = 7'd38;
										7'b0000101: alu_operator_o = 7'd39;
										7'b0010000:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd59;
												alu_multicycle_o = 1'b1;
											end
										7'b0010001:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd61;
												alu_multicycle_o = 1'b1;
											end
										7'b0010010:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd63;
												alu_multicycle_o = 1'b1;
											end
										7'b0011000:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd60;
												alu_multicycle_o = 1'b1;
											end
										7'b0011001:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd62;
												alu_multicycle_o = 1'b1;
											end
										7'b0011010:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd64;
												alu_multicycle_o = 1'b1;
											end
										default:
											;
									endcase
								default:
									;
							endcase
						else
							alu_operator_o = 7'd10;
					3'b101:
						if (RV32B != 32'sd0) begin
							if (instr_alu[26] == 1'b1) begin
								alu_operator_o = 7'd48;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							else
								(* full_case, parallel_case *)
								case (instr_alu[31:27])
									5'b00000: alu_operator_o = 7'd9;
									5'b01000: alu_operator_o = 7'd8;
									5'b00100:
										if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
											alu_operator_o = 7'd11;
									5'b01001: alu_operator_o = 7'd52;
									5'b01100: begin
										alu_operator_o = 7'd13;
										alu_multicycle_o = 1'b1;
									end
									5'b01101: alu_operator_o = 7'd15;
									5'b00101: alu_operator_o = 7'd16;
									5'b00001:
										if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
											if (instr_alu[26] == 1'b0)
												alu_operator_o = 7'd18;
										end
									default:
										;
								endcase
						end
						else if (instr_alu[31:27] == 5'b00000)
							alu_operator_o = 7'd9;
						else if (instr_alu[31:27] == 5'b01000)
							alu_operator_o = 7'd8;
					default:
						;
				endcase
			end
			7'h33: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd0;
				if (instr_alu[26]) begin
					if (RV32B != 32'sd0)
						(* full_case, parallel_case *)
						case ({instr_alu[26:25], instr_alu[14:12]})
							5'b11001: begin
								alu_operator_o = 7'd46;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b11101: begin
								alu_operator_o = 7'd45;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b10001: begin
								alu_operator_o = 7'd47;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b10101: begin
								alu_operator_o = 7'd48;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							default:
								;
						endcase
				end
				else
					(* full_case, parallel_case *)
					case ({instr_alu[31:25], instr_alu[14:12]})
						10'b0000000000: alu_operator_o = 7'd0;
						10'b0100000000: alu_operator_o = 7'd1;
						10'b0000000010: alu_operator_o = 7'd43;
						10'b0000000011: alu_operator_o = 7'd44;
						10'b0000000100: alu_operator_o = 7'd2;
						10'b0000000110: alu_operator_o = 7'd3;
						10'b0000000111: alu_operator_o = 7'd4;
						10'b0000000001: alu_operator_o = 7'd10;
						10'b0000000101: alu_operator_o = 7'd9;
						10'b0100000101: alu_operator_o = 7'd8;
						10'b0110000001:
							if (RV32B != 32'sd0) begin
								alu_operator_o = 7'd14;
								alu_multicycle_o = 1'b1;
							end
						10'b0110000101:
							if (RV32B != 32'sd0) begin
								alu_operator_o = 7'd13;
								alu_multicycle_o = 1'b1;
							end
						10'b0000101100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd31;
						10'b0000101110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd33;
						10'b0000101101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd32;
						10'b0000101111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd34;
						10'b0000100100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd35;
						10'b0100100100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd36;
						10'b0000100111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd37;
						10'b0100000100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd5;
						10'b0100000110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd6;
						10'b0100000111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd7;
						10'b0010000010:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd22;
						10'b0010000100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd23;
						10'b0010000110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd24;
						10'b0100100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd50;
						10'b0010100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd49;
						10'b0110100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd51;
						10'b0100100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd52;
						10'b0100100111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd55;
						10'b0110100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd15;
						10'b0010100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd16;
						10'b0000100001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd17;
						10'b0000100101:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd18;
						10'b0010100010:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd19;
						10'b0010100100:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd20;
						10'b0010100110:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd21;
						10'b0010000001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd12;
						10'b0010000101:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd11;
						10'b0000101001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd56;
						10'b0000101010:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd57;
						10'b0000101011:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd58;
						10'b0100100110:
							if (RV32B == 32'sd3) begin
								alu_operator_o = 7'd54;
								alu_multicycle_o = 1'b1;
							end
						10'b0000100110:
							if (RV32B == 32'sd3) begin
								alu_operator_o = 7'd53;
								alu_multicycle_o = 1'b1;
							end
						10'b0000001000: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001001: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001010: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001011: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001100: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001101: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001110: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001111: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						default:
							;
					endcase
			end
			7'h0f:
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: begin
						alu_operator_o = 7'd0;
						alu_op_a_mux_sel_o = 2'd0;
						alu_op_b_mux_sel_o = 1'd1;
					end
					3'b001:
						if (BranchTargetALU) begin
							bt_a_mux_sel_o = 2'd2;
							bt_b_mux_sel_o = 3'd5;
						end
						else begin
							alu_op_a_mux_sel_o = 2'd2;
							alu_op_b_mux_sel_o = 1'd1;
							imm_b_mux_sel_o = 3'd5;
							alu_operator_o = 7'd0;
						end
					default:
						;
				endcase
			7'h73:
				if (instr_alu[14:12] == 3'b000) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd1;
				end
				else begin
					alu_op_b_mux_sel_o = 1'd1;
					imm_a_mux_sel_o = 1'd0;
					imm_b_mux_sel_o = 3'd0;
					if (instr_alu[14])
						alu_op_a_mux_sel_o = 2'd3;
					else
						alu_op_a_mux_sel_o = 2'd0;
				end
			default:
				;
		endcase
	end
	assign mult_en_o = (illegal_insn ? 1'b0 : mult_sel_o);
	assign div_en_o = (illegal_insn ? 1'b0 : div_sel_o);
	assign illegal_insn_o = illegal_insn | illegal_reg_rv32e;
	assign rf_we_o = rf_we & ~illegal_reg_rv32e;
	assign unused_instr_alu = {instr_alu[19:15], instr_alu[11:7]};
	initial _sv2v_0 = 0;
endmodule
module ibex_dummy_instr (
	clk_i,
	rst_ni,
	dummy_instr_en_i,
	dummy_instr_mask_i,
	dummy_instr_seed_en_i,
	dummy_instr_seed_i,
	fetch_valid_i,
	id_in_ready_i,
	insert_dummy_instr_o,
	dummy_instr_data_o
);
	reg _sv2v_0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	input wire clk_i;
	input wire rst_ni;
	input wire dummy_instr_en_i;
	input wire [2:0] dummy_instr_mask_i;
	input wire dummy_instr_seed_en_i;
	input wire [31:0] dummy_instr_seed_i;
	input wire fetch_valid_i;
	input wire id_in_ready_i;
	output wire insert_dummy_instr_o;
	output wire [31:0] dummy_instr_data_o;
	localparam [31:0] TIMEOUT_CNT_W = 5;
	localparam [31:0] OP_W = 5;
	localparam [31:0] LFSR_OUT_W = 17;
	wire [16:0] lfsr_data;
	wire [4:0] dummy_cnt_incr;
	wire [4:0] dummy_cnt_threshold;
	wire [4:0] dummy_cnt_d;
	reg [4:0] dummy_cnt_q;
	wire dummy_cnt_en;
	wire lfsr_en;
	wire [16:0] lfsr_state;
	wire insert_dummy_instr;
	reg [6:0] dummy_set;
	reg [2:0] dummy_opcode;
	wire [31:0] dummy_instr;
	reg [31:0] dummy_instr_seed_q;
	wire [31:0] dummy_instr_seed_d;
	assign lfsr_en = insert_dummy_instr & id_in_ready_i;
	assign dummy_instr_seed_d = dummy_instr_seed_q ^ dummy_instr_seed_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dummy_instr_seed_q <= 1'sb0;
		else if (dummy_instr_seed_en_i)
			dummy_instr_seed_q <= dummy_instr_seed_d;
	prim_lfsr #(
		.LfsrDw(ibex_pkg_LfsrWidth),
		.StateOutDw(LFSR_OUT_W),
		.DefaultSeed(RndCnstLfsrSeed),
		.StatePermEn(1'b1),
		.StatePerm(RndCnstLfsrPerm)
	) lfsr_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.seed_en_i(dummy_instr_seed_en_i),
		.seed_i(dummy_instr_seed_d),
		.lfsr_en_i(lfsr_en),
		.entropy_i(1'sb0),
		.state_o(lfsr_state)
	);
	function automatic [16:0] sv2v_cast_92F3A;
		input reg [16:0] inp;
		sv2v_cast_92F3A = inp;
	endfunction
	assign lfsr_data = sv2v_cast_92F3A(lfsr_state);
	assign dummy_cnt_threshold = lfsr_data[4-:TIMEOUT_CNT_W] & {dummy_instr_mask_i, {2 {1'b1}}};
	assign dummy_cnt_incr = dummy_cnt_q + {{4 {1'b0}}, 1'b1};
	assign dummy_cnt_d = (insert_dummy_instr ? {5 {1'sb0}} : dummy_cnt_incr);
	assign dummy_cnt_en = (dummy_instr_en_i & id_in_ready_i) & (fetch_valid_i | insert_dummy_instr);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dummy_cnt_q <= 1'sb0;
		else if (dummy_cnt_en)
			dummy_cnt_q <= dummy_cnt_d;
	assign insert_dummy_instr = dummy_instr_en_i & (dummy_cnt_q == dummy_cnt_threshold);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (lfsr_data[16-:2])
			2'b00: begin
				dummy_set = 7'b0000000;
				dummy_opcode = 3'b000;
			end
			2'b01: begin
				dummy_set = 7'b0000001;
				dummy_opcode = 3'b000;
			end
			2'b10: begin
				dummy_set = 7'b0000001;
				dummy_opcode = 3'b100;
			end
			2'b11: begin
				dummy_set = 7'b0000000;
				dummy_opcode = 3'b111;
			end
			default: begin
				dummy_set = 7'b0000000;
				dummy_opcode = 3'b000;
			end
		endcase
	end
	assign dummy_instr = {dummy_set, lfsr_data[14-:5], lfsr_data[9-:5], dummy_opcode, 12'h033};
	assign insert_dummy_instr_o = insert_dummy_instr;
	assign dummy_instr_data_o = dummy_instr;
	initial _sv2v_0 = 0;
endmodule
module ibex_ex_block (
	clk_i,
	rst_ni,
	alu_operator_i,
	alu_operand_a_i,
	alu_operand_b_i,
	alu_instr_first_cycle_i,
	bt_a_operand_i,
	bt_b_operand_i,
	multdiv_operator_i,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	multdiv_signed_mode_i,
	multdiv_operand_a_i,
	multdiv_operand_b_i,
	multdiv_ready_id_i,
	data_ind_timing_i,
	imd_val_we_o,
	imd_val_d_o,
	imd_val_q_i,
	alu_adder_result_ex_o,
	result_ex_o,
	branch_target_o,
	branch_decision_o,
	ex_valid_o
);
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire [6:0] alu_operator_i;
	input wire [31:0] alu_operand_a_i;
	input wire [31:0] alu_operand_b_i;
	input wire alu_instr_first_cycle_i;
	input wire [31:0] bt_a_operand_i;
	input wire [31:0] bt_b_operand_i;
	input wire [1:0] multdiv_operator_i;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] multdiv_signed_mode_i;
	input wire [31:0] multdiv_operand_a_i;
	input wire [31:0] multdiv_operand_b_i;
	input wire multdiv_ready_id_i;
	input wire data_ind_timing_i;
	output wire [1:0] imd_val_we_o;
	output wire [67:0] imd_val_d_o;
	input wire [67:0] imd_val_q_i;
	output wire [31:0] alu_adder_result_ex_o;
	output wire [31:0] result_ex_o;
	output wire [31:0] branch_target_o;
	output wire branch_decision_o;
	output wire ex_valid_o;
	wire [31:0] alu_result;
	wire [31:0] multdiv_result;
	wire [32:0] multdiv_alu_operand_b;
	wire [32:0] multdiv_alu_operand_a;
	wire [33:0] alu_adder_result_ext;
	wire alu_cmp_result;
	wire alu_is_equal_result;
	wire multdiv_valid;
	wire multdiv_sel;
	wire [63:0] alu_imd_val_q;
	wire [63:0] alu_imd_val_d;
	wire [1:0] alu_imd_val_we;
	wire [67:0] multdiv_imd_val_d;
	wire [1:0] multdiv_imd_val_we;
	generate
		if (RV32M != 32'sd0) begin : gen_multdiv_m
			assign multdiv_sel = mult_sel_i | div_sel_i;
		end
		else begin : gen_multdiv_no_m
			assign multdiv_sel = 1'b0;
		end
	endgenerate
	assign imd_val_d_o[34+:34] = (multdiv_sel ? multdiv_imd_val_d[34+:34] : {2'b00, alu_imd_val_d[32+:32]});
	assign imd_val_d_o[0+:34] = (multdiv_sel ? multdiv_imd_val_d[0+:34] : {2'b00, alu_imd_val_d[0+:32]});
	assign imd_val_we_o = (multdiv_sel ? multdiv_imd_val_we : alu_imd_val_we);
	assign alu_imd_val_q = {imd_val_q_i[65-:32], imd_val_q_i[31-:32]};
	assign result_ex_o = (multdiv_sel ? multdiv_result : alu_result);
	assign branch_decision_o = alu_cmp_result;
	generate
		if (BranchTargetALU) begin : g_branch_target_alu
			wire [32:0] bt_alu_result;
			wire unused_bt_carry;
			assign bt_alu_result = bt_a_operand_i + bt_b_operand_i;
			assign unused_bt_carry = bt_alu_result[32];
			assign branch_target_o = bt_alu_result[31:0];
		end
		else begin : g_no_branch_target_alu
			wire [31:0] unused_bt_a_operand;
			wire [31:0] unused_bt_b_operand;
			assign unused_bt_a_operand = bt_a_operand_i;
			assign unused_bt_b_operand = bt_b_operand_i;
			assign branch_target_o = alu_adder_result_ex_o;
		end
	endgenerate
	ibex_alu #(.RV32B(RV32B)) alu_i(
		.operator_i(alu_operator_i),
		.operand_a_i(alu_operand_a_i),
		.operand_b_i(alu_operand_b_i),
		.instr_first_cycle_i(alu_instr_first_cycle_i),
		.imd_val_q_i(alu_imd_val_q),
		.imd_val_we_o(alu_imd_val_we),
		.imd_val_d_o(alu_imd_val_d),
		.multdiv_operand_a_i(multdiv_alu_operand_a),
		.multdiv_operand_b_i(multdiv_alu_operand_b),
		.multdiv_sel_i(multdiv_sel),
		.adder_result_o(alu_adder_result_ex_o),
		.adder_result_ext_o(alu_adder_result_ext),
		.result_o(alu_result),
		.comparison_result_o(alu_cmp_result),
		.is_equal_result_o(alu_is_equal_result)
	);
	generate
		if (RV32M == 32'sd1) begin : gen_multdiv_slow
			ibex_multdiv_slow multdiv_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.mult_en_i(mult_en_i),
				.div_en_i(div_en_i),
				.mult_sel_i(mult_sel_i),
				.div_sel_i(div_sel_i),
				.operator_i(multdiv_operator_i),
				.signed_mode_i(multdiv_signed_mode_i),
				.op_a_i(multdiv_operand_a_i),
				.op_b_i(multdiv_operand_b_i),
				.alu_adder_ext_i(alu_adder_result_ext),
				.alu_adder_i(alu_adder_result_ex_o),
				.equal_to_zero_i(alu_is_equal_result),
				.data_ind_timing_i(data_ind_timing_i),
				.valid_o(multdiv_valid),
				.alu_operand_a_o(multdiv_alu_operand_a),
				.alu_operand_b_o(multdiv_alu_operand_b),
				.imd_val_q_i(imd_val_q_i),
				.imd_val_d_o(multdiv_imd_val_d),
				.imd_val_we_o(multdiv_imd_val_we),
				.multdiv_ready_id_i(multdiv_ready_id_i),
				.multdiv_result_o(multdiv_result)
			);
		end
		else if ((RV32M == 32'sd2) || (RV32M == 32'sd3)) begin : gen_multdiv_fast
			ibex_multdiv_fast #(.RV32M(RV32M)) multdiv_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.mult_en_i(mult_en_i),
				.div_en_i(div_en_i),
				.mult_sel_i(mult_sel_i),
				.div_sel_i(div_sel_i),
				.operator_i(multdiv_operator_i),
				.signed_mode_i(multdiv_signed_mode_i),
				.op_a_i(multdiv_operand_a_i),
				.op_b_i(multdiv_operand_b_i),
				.alu_operand_a_o(multdiv_alu_operand_a),
				.alu_operand_b_o(multdiv_alu_operand_b),
				.alu_adder_ext_i(alu_adder_result_ext),
				.alu_adder_i(alu_adder_result_ex_o),
				.equal_to_zero_i(alu_is_equal_result),
				.data_ind_timing_i(data_ind_timing_i),
				.imd_val_q_i(imd_val_q_i),
				.imd_val_d_o(multdiv_imd_val_d),
				.imd_val_we_o(multdiv_imd_val_we),
				.multdiv_ready_id_i(multdiv_ready_id_i),
				.valid_o(multdiv_valid),
				.multdiv_result_o(multdiv_result)
			);
		end
	endgenerate
	assign ex_valid_o = (multdiv_sel ? multdiv_valid : ~(|alu_imd_val_we));
endmodule
module ibex_fetch_fifo (
	clk_i,
	rst_ni,
	clear_i,
	busy_o,
	in_valid_i,
	in_addr_i,
	in_rdata_i,
	in_err_i,
	out_valid_o,
	out_ready_i,
	out_addr_o,
	out_rdata_o,
	out_err_o,
	out_err_plus2_o
);
	reg _sv2v_0;
	parameter [31:0] NUM_REQS = 2;
	parameter [0:0] ResetAll = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire clear_i;
	output wire [NUM_REQS - 1:0] busy_o;
	input wire in_valid_i;
	input wire [31:0] in_addr_i;
	input wire [31:0] in_rdata_i;
	input wire in_err_i;
	output reg out_valid_o;
	input wire out_ready_i;
	output wire [31:0] out_addr_o;
	output reg [31:0] out_rdata_o;
	output reg out_err_o;
	output reg out_err_plus2_o;
	localparam [31:0] DEPTH = NUM_REQS + 1;
	wire [(DEPTH * 32) - 1:0] rdata_d;
	reg [(DEPTH * 32) - 1:0] rdata_q;
	wire [DEPTH - 1:0] err_d;
	reg [DEPTH - 1:0] err_q;
	wire [DEPTH - 1:0] valid_d;
	reg [DEPTH - 1:0] valid_q;
	wire [DEPTH - 1:0] lowest_free_entry;
	wire [DEPTH - 1:0] valid_pushed;
	wire [DEPTH - 1:0] valid_popped;
	wire [DEPTH - 1:0] entry_en;
	wire pop_fifo;
	wire [31:0] rdata;
	wire [31:0] rdata_unaligned;
	wire err;
	wire err_unaligned;
	wire err_plus2;
	wire valid;
	wire valid_unaligned;
	wire aligned_is_compressed;
	wire unaligned_is_compressed;
	wire addr_incr_two;
	wire [31:1] instr_addr_next;
	wire [31:1] instr_addr_d;
	reg [31:1] instr_addr_q;
	wire instr_addr_en;
	wire unused_addr_in;
	assign rdata = (valid_q[0] ? rdata_q[0+:32] : in_rdata_i);
	assign err = (valid_q[0] ? err_q[0] : in_err_i);
	assign valid = valid_q[0] | in_valid_i;
	assign rdata_unaligned = (valid_q[1] ? {rdata_q[47-:16], rdata[31:16]} : {in_rdata_i[15:0], rdata[31:16]});
	assign err_unaligned = (valid_q[1] ? (err_q[1] & ~unaligned_is_compressed) | err_q[0] : (valid_q[0] & err_q[0]) | (in_err_i & (~valid_q[0] | ~unaligned_is_compressed)));
	assign err_plus2 = (valid_q[1] ? err_q[1] & ~err_q[0] : (in_err_i & valid_q[0]) & ~err_q[0]);
	assign valid_unaligned = (valid_q[1] ? 1'b1 : valid_q[0] & in_valid_i);
	assign unaligned_is_compressed = (rdata[17:16] != 2'b11) & ~err;
	assign aligned_is_compressed = (rdata[1:0] != 2'b11) & ~err;
	always @(*) begin
		if (_sv2v_0)
			;
		if (out_addr_o[1]) begin
			out_rdata_o = rdata_unaligned;
			out_err_o = err_unaligned;
			out_err_plus2_o = err_plus2;
			if (unaligned_is_compressed)
				out_valid_o = valid;
			else
				out_valid_o = valid_unaligned;
		end
		else begin
			out_rdata_o = rdata;
			out_err_o = err;
			out_err_plus2_o = 1'b0;
			out_valid_o = valid;
		end
	end
	assign instr_addr_en = clear_i | (out_ready_i & out_valid_o);
	assign addr_incr_two = (instr_addr_q[1] ? unaligned_is_compressed : aligned_is_compressed);
	assign instr_addr_next = instr_addr_q[31:1] + {29'd0, ~addr_incr_two, addr_incr_two};
	assign instr_addr_d = (clear_i ? in_addr_i[31:1] : instr_addr_next);
	generate
		if (ResetAll) begin : g_instr_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					instr_addr_q <= 1'sb0;
				else if (instr_addr_en)
					instr_addr_q <= instr_addr_d;
		end
		else begin : g_instr_addr_nr
			always @(posedge clk_i)
				if (instr_addr_en)
					instr_addr_q <= instr_addr_d;
		end
	endgenerate
	assign out_addr_o = {instr_addr_q, 1'b0};
	assign unused_addr_in = in_addr_i[0];
	assign busy_o = valid_q[DEPTH - 1:DEPTH - NUM_REQS];
	assign pop_fifo = (out_ready_i & out_valid_o) & (~aligned_is_compressed | out_addr_o[1]);
	genvar _gv_i_28;
	generate
		for (_gv_i_28 = 0; _gv_i_28 < (DEPTH - 1); _gv_i_28 = _gv_i_28 + 1) begin : g_fifo_next
			localparam i = _gv_i_28;
			if (i == 0) begin : g_ent0
				assign lowest_free_entry[i] = ~valid_q[i];
			end
			else begin : g_ent_others
				assign lowest_free_entry[i] = ~valid_q[i] & valid_q[i - 1];
			end
			assign valid_pushed[i] = (in_valid_i & lowest_free_entry[i]) | valid_q[i];
			assign valid_popped[i] = (pop_fifo ? valid_pushed[i + 1] : valid_pushed[i]);
			assign valid_d[i] = valid_popped[i] & ~clear_i;
			assign entry_en[i] = (valid_pushed[i + 1] & pop_fifo) | ((in_valid_i & lowest_free_entry[i]) & ~pop_fifo);
			assign rdata_d[i * 32+:32] = (valid_q[i + 1] ? rdata_q[(i + 1) * 32+:32] : in_rdata_i);
			assign err_d[i] = (valid_q[i + 1] ? err_q[i + 1] : in_err_i);
		end
	endgenerate
	assign lowest_free_entry[DEPTH - 1] = ~valid_q[DEPTH - 1] & valid_q[DEPTH - 2];
	assign valid_pushed[DEPTH - 1] = valid_q[DEPTH - 1] | (in_valid_i & lowest_free_entry[DEPTH - 1]);
	assign valid_popped[DEPTH - 1] = (pop_fifo ? 1'b0 : valid_pushed[DEPTH - 1]);
	assign valid_d[DEPTH - 1] = valid_popped[DEPTH - 1] & ~clear_i;
	assign entry_en[DEPTH - 1] = in_valid_i & lowest_free_entry[DEPTH - 1];
	assign rdata_d[(DEPTH - 1) * 32+:32] = in_rdata_i;
	assign err_d[DEPTH - 1] = in_err_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			valid_q <= 1'sb0;
		else
			valid_q <= valid_d;
	genvar _gv_i_29;
	generate
		for (_gv_i_29 = 0; _gv_i_29 < DEPTH; _gv_i_29 = _gv_i_29 + 1) begin : g_fifo_regs
			localparam i = _gv_i_29;
			if (ResetAll) begin : g_rdata_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						rdata_q[i * 32+:32] <= 1'sb0;
						err_q[i] <= 1'sb0;
					end
					else if (entry_en[i]) begin
						rdata_q[i * 32+:32] <= rdata_d[i * 32+:32];
						err_q[i] <= err_d[i];
					end
			end
			else begin : g_rdata_nr
				always @(posedge clk_i)
					if (entry_en[i]) begin
						rdata_q[i * 32+:32] <= rdata_d[i * 32+:32];
						err_q[i] <= err_d[i];
					end
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_icache (
	clk_i,
	rst_ni,
	req_i,
	branch_i,
	addr_i,
	ready_i,
	valid_o,
	rdata_o,
	addr_o,
	err_o,
	err_plus2_o,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	instr_rvalid_i,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	icache_enable_i,
	icache_inval_i,
	busy_o,
	ecc_error_o
);
	reg _sv2v_0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] ResetAll = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchCache = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] addr_i;
	input wire ready_i;
	output wire valid_o;
	output wire [31:0] rdata_o;
	output wire [31:0] addr_o;
	output wire err_o;
	output wire err_plus2_o;
	output wire instr_req_o;
	input wire instr_gnt_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_err_i;
	input wire instr_rvalid_i;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output reg ic_scr_key_req_o;
	input wire icache_enable_i;
	input wire icache_inval_i;
	output wire busy_o;
	output wire ecc_error_o;
	localparam [31:0] NUM_FB = 4;
	localparam [31:0] FB_THRESHOLD = 2;
	wire [31:0] lookup_addr_aligned;
	wire [31:0] prefetch_addr_d;
	reg [31:0] prefetch_addr_q;
	wire prefetch_addr_en;
	wire lookup_throttle;
	wire lookup_req_ic0;
	wire [31:0] lookup_addr_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] lookup_index_ic0;
	wire fill_req_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] fill_index_ic0;
	wire [ibex_pkg_IC_TAG_SIZE - 1:0] fill_tag_ic0;
	wire [63:0] fill_wdata_ic0;
	wire lookup_grant_ic0;
	wire lookup_actual_ic0;
	wire fill_grant_ic0;
	wire tag_req_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] tag_index_ic0;
	wire [1:0] tag_banks_ic0;
	wire tag_write_ic0;
	wire [TagSizeECC - 1:0] tag_wdata_ic0;
	wire data_req_ic0;
	wire [ibex_pkg_IC_INDEX_W - 1:0] data_index_ic0;
	wire [1:0] data_banks_ic0;
	wire data_write_ic0;
	wire [LineSizeECC - 1:0] data_wdata_ic0;
	wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] tag_rdata_ic1;
	wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] data_rdata_ic1;
	reg [LineSizeECC - 1:0] hit_data_ecc_ic1;
	wire [63:0] hit_data_ic1;
	reg lookup_valid_ic1;
	localparam [31:0] ibex_pkg_IC_INDEX_HI = (ibex_pkg_IC_INDEX_W + ibex_pkg_IC_LINE_W) - 1;
	reg [31:ibex_pkg_IC_INDEX_HI + 1] lookup_addr_ic1;
	wire [1:0] tag_match_ic1;
	wire tag_hit_ic1;
	wire [1:0] tag_invalid_ic1;
	wire [1:0] lowest_invalid_way_ic1;
	wire [1:0] round_robin_way_ic1;
	reg [1:0] round_robin_way_q;
	wire [1:0] sel_way_ic1;
	wire ecc_err_ic1;
	wire ecc_write_req;
	wire [1:0] ecc_write_ways;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ecc_write_index;
	reg [1:0] fb_fill_level;
	wire fill_cache_new;
	wire fill_new_alloc;
	wire fill_spec_req;
	wire fill_spec_done;
	wire fill_spec_hold;
	wire [(NUM_FB * NUM_FB) - 1:0] fill_older_d;
	reg [(NUM_FB * NUM_FB) - 1:0] fill_older_q;
	wire [3:0] fill_alloc_sel;
	wire [3:0] fill_alloc;
	wire [3:0] fill_busy_d;
	reg [3:0] fill_busy_q;
	wire [3:0] fill_done;
	reg [3:0] fill_in_ic1;
	wire [3:0] fill_stale_d;
	reg [3:0] fill_stale_q;
	wire [3:0] fill_cache_d;
	reg [3:0] fill_cache_q;
	wire [3:0] fill_hit_ic1;
	wire [3:0] fill_hit_d;
	reg [3:0] fill_hit_q;
	localparam [31:0] ibex_pkg_BUS_BYTES = 4;
	localparam [31:0] ibex_pkg_IC_LINE_BEATS = ibex_pkg_IC_LINE_BYTES / ibex_pkg_BUS_BYTES;
	localparam [31:0] ibex_pkg_IC_LINE_BEATS_W = $clog2(ibex_pkg_IC_LINE_BEATS);
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_ext_cnt_d;
	reg [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_ext_cnt_q;
	wire [3:0] fill_ext_hold_d;
	reg [3:0] fill_ext_hold_q;
	wire [3:0] fill_ext_done_d;
	reg [3:0] fill_ext_done_q;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_rvd_cnt_d;
	reg [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_rvd_cnt_q;
	wire [3:0] fill_rvd_done;
	wire [3:0] fill_ram_done_d;
	reg [3:0] fill_ram_done_q;
	wire [3:0] fill_out_grant;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_out_cnt_d;
	reg [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_out_cnt_q;
	wire [3:0] fill_out_done;
	wire [3:0] fill_ext_req;
	wire [3:0] fill_rvd_exp;
	wire [3:0] fill_ram_req;
	wire [3:0] fill_out_req;
	wire [3:0] fill_data_sel;
	wire [3:0] fill_data_reg;
	wire [3:0] fill_data_hit;
	wire [3:0] fill_data_rvd;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS_W) - 1:0] fill_ext_off;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS_W) - 1:0] fill_rvd_off;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_ext_beat;
	wire [(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (NUM_FB * (ibex_pkg_IC_LINE_BEATS_W + 1)) - 1 : (NUM_FB * (1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W - 1)):(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W + 0)] fill_rvd_beat;
	wire [3:0] fill_ext_arb;
	wire [3:0] fill_ram_arb;
	wire [3:0] fill_out_arb;
	wire [3:0] fill_rvd_arb;
	wire [3:0] fill_entry_en;
	wire [3:0] fill_addr_en;
	wire [3:0] fill_way_en;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS) - 1:0] fill_data_en;
	wire [(NUM_FB * ibex_pkg_IC_LINE_BEATS) - 1:0] fill_err_d;
	reg [(NUM_FB * ibex_pkg_IC_LINE_BEATS) - 1:0] fill_err_q;
	reg [31:0] fill_addr_q [0:3];
	reg [1:0] fill_way_q [0:3];
	wire [63:0] fill_data_d [0:3];
	reg [63:0] fill_data_q [0:3];
	localparam [31:0] ibex_pkg_BUS_W = 2;
	reg [31:ibex_pkg_BUS_W] fill_ext_req_addr;
	reg [31:0] fill_ram_req_addr;
	reg [1:0] fill_ram_req_way;
	reg [63:0] fill_ram_req_data;
	reg [63:0] fill_out_data;
	reg [ibex_pkg_IC_LINE_BEATS - 1:0] fill_out_err;
	wire instr_req;
	wire [31:ibex_pkg_BUS_W] instr_addr;
	wire skid_complete_instr;
	wire skid_ready;
	wire output_compressed;
	wire skid_valid_d;
	reg skid_valid_q;
	wire skid_en;
	wire [15:0] skid_data_d;
	reg [15:0] skid_data_q;
	reg skid_err_q;
	wire output_valid;
	wire addr_incr_two;
	wire output_addr_en;
	wire [31:1] output_addr_incr;
	wire [31:1] output_addr_d;
	reg [31:1] output_addr_q;
	reg [15:0] output_data_lo;
	reg [15:0] output_data_hi;
	wire data_valid;
	wire output_ready;
	wire [63:0] line_data;
	wire [ibex_pkg_IC_LINE_BEATS - 1:0] line_err;
	reg [31:0] line_data_muxed;
	reg line_err_muxed;
	wire [31:0] output_data;
	wire output_err;
	reg [1:0] inval_state_q;
	reg [1:0] inval_state_d;
	reg inval_write_req;
	reg inval_block_cache;
	reg [ibex_pkg_IC_INDEX_W - 1:0] inval_index_d;
	reg [ibex_pkg_IC_INDEX_W - 1:0] inval_index_q;
	reg inval_index_en;
	wire inval_active;
	assign lookup_addr_aligned = {lookup_addr_ic0[31:ibex_pkg_IC_LINE_W], {ibex_pkg_IC_LINE_W {1'b0}}};
	assign prefetch_addr_d = (lookup_grant_ic0 ? lookup_addr_aligned + {{(ibex_pkg_ADDR_W - ibex_pkg_IC_LINE_W) - 1 {1'b0}}, 1'b1, {ibex_pkg_IC_LINE_W {1'b0}}} : addr_i);
	assign prefetch_addr_en = branch_i | lookup_grant_ic0;
	generate
		if (ResetAll) begin : g_prefetch_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					prefetch_addr_q <= 1'sb0;
				else if (prefetch_addr_en)
					prefetch_addr_q <= prefetch_addr_d;
		end
		else begin : g_prefetch_addr_nr
			always @(posedge clk_i)
				if (prefetch_addr_en)
					prefetch_addr_q <= prefetch_addr_d;
		end
	endgenerate
	assign lookup_throttle = fb_fill_level > FB_THRESHOLD[1:0];
	assign lookup_req_ic0 = ((req_i & ~&fill_busy_q) & (branch_i | ~lookup_throttle)) & ~ecc_write_req;
	assign lookup_addr_ic0 = (branch_i ? addr_i : prefetch_addr_q);
	assign lookup_index_ic0 = lookup_addr_ic0[ibex_pkg_IC_INDEX_HI:ibex_pkg_IC_LINE_W];
	assign fill_req_ic0 = |fill_ram_req;
	assign fill_index_ic0 = fill_ram_req_addr[ibex_pkg_IC_INDEX_HI:ibex_pkg_IC_LINE_W];
	assign fill_tag_ic0 = {~inval_write_req & ~ecc_write_req, fill_ram_req_addr[31:ibex_pkg_IC_INDEX_HI + 1]};
	assign fill_wdata_ic0 = fill_ram_req_data;
	assign lookup_grant_ic0 = lookup_req_ic0;
	assign fill_grant_ic0 = ((fill_req_ic0 & ~lookup_req_ic0) & ~inval_write_req) & ~ecc_write_req;
	assign lookup_actual_ic0 = (lookup_grant_ic0 & icache_enable_i) & ~inval_block_cache;
	assign tag_req_ic0 = ((lookup_req_ic0 | fill_req_ic0) | inval_write_req) | ecc_write_req;
	assign tag_index_ic0 = (inval_write_req ? inval_index_q : (ecc_write_req ? ecc_write_index : (fill_grant_ic0 ? fill_index_ic0 : lookup_index_ic0)));
	assign tag_banks_ic0 = (ecc_write_req ? ecc_write_ways : (fill_grant_ic0 ? fill_ram_req_way : {ibex_pkg_IC_NUM_WAYS {1'b1}}));
	assign tag_write_ic0 = (fill_grant_ic0 | inval_write_req) | ecc_write_req;
	assign data_req_ic0 = lookup_req_ic0 | fill_req_ic0;
	assign data_index_ic0 = tag_index_ic0;
	assign data_banks_ic0 = tag_banks_ic0;
	assign data_write_ic0 = tag_write_ic0;
	generate
		if (ICacheECC) begin : gen_ecc_wdata
			wire [21:0] tag_ecc_input_padded;
			wire [27:0] tag_ecc_output_padded;
			wire [22 - ibex_pkg_IC_TAG_SIZE:0] unused_tag_ecc_output;
			assign tag_ecc_input_padded = {{22 - ibex_pkg_IC_TAG_SIZE {1'b0}}, fill_tag_ic0};
			assign unused_tag_ecc_output = tag_ecc_output_padded[21:ibex_pkg_IC_TAG_SIZE - 1];
			prim_secded_inv_28_22_enc tag_ecc_enc(
				.data_i(tag_ecc_input_padded),
				.data_o(tag_ecc_output_padded)
			);
			assign tag_wdata_ic0 = {tag_ecc_output_padded[27:22], tag_ecc_output_padded[ibex_pkg_IC_TAG_SIZE - 1:0]};
			genvar _gv_bank_1;
			for (_gv_bank_1 = 0; _gv_bank_1 < ibex_pkg_IC_LINE_BEATS; _gv_bank_1 = _gv_bank_1 + 1) begin : gen_ecc_banks
				localparam bank = _gv_bank_1;
				prim_secded_inv_39_32_enc data_ecc_enc(
					.data_i(fill_wdata_ic0[bank * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE]),
					.data_o(data_wdata_ic0[bank * BusSizeECC+:BusSizeECC])
				);
			end
		end
		else begin : gen_noecc_wdata
			assign tag_wdata_ic0 = fill_tag_ic0;
			assign data_wdata_ic0 = fill_wdata_ic0;
		end
	endgenerate
	assign ic_tag_req_o = {ibex_pkg_IC_NUM_WAYS {tag_req_ic0}} & tag_banks_ic0;
	assign ic_tag_write_o = tag_write_ic0;
	assign ic_tag_addr_o = tag_index_ic0;
	assign ic_tag_wdata_o = tag_wdata_ic0;
	assign tag_rdata_ic1 = ic_tag_rdata_i;
	assign ic_data_req_o = {ibex_pkg_IC_NUM_WAYS {data_req_ic0}} & data_banks_ic0;
	assign ic_data_write_o = data_write_ic0;
	assign ic_data_addr_o = data_index_ic0;
	assign ic_data_wdata_o = data_wdata_ic0;
	assign data_rdata_ic1 = ic_data_rdata_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			lookup_valid_ic1 <= 1'b0;
		else
			lookup_valid_ic1 <= lookup_actual_ic0;
	generate
		if (ResetAll) begin : g_lookup_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					lookup_addr_ic1 <= 1'sb0;
					fill_in_ic1 <= 1'sb0;
				end
				else if (lookup_grant_ic0) begin
					lookup_addr_ic1 <= lookup_addr_ic0[31:ibex_pkg_IC_INDEX_HI + 1];
					fill_in_ic1 <= fill_alloc_sel;
				end
		end
		else begin : g_lookup_addr_nr
			always @(posedge clk_i)
				if (lookup_grant_ic0) begin
					lookup_addr_ic1 <= lookup_addr_ic0[31:ibex_pkg_IC_INDEX_HI + 1];
					fill_in_ic1 <= fill_alloc_sel;
				end
		end
	endgenerate
	genvar _gv_way_1;
	generate
		for (_gv_way_1 = 0; _gv_way_1 < ibex_pkg_IC_NUM_WAYS; _gv_way_1 = _gv_way_1 + 1) begin : gen_tag_match
			localparam way = _gv_way_1;
			assign tag_match_ic1[way] = tag_rdata_ic1[((1 - way) * TagSizeECC) + (ibex_pkg_IC_TAG_SIZE - 1)-:ibex_pkg_IC_TAG_SIZE] == {1'b1, lookup_addr_ic1[31:ibex_pkg_IC_INDEX_HI + 1]};
			assign tag_invalid_ic1[way] = ~tag_rdata_ic1[((1 - way) * TagSizeECC) + (ibex_pkg_IC_TAG_SIZE - 1)];
		end
	endgenerate
	assign tag_hit_ic1 = |tag_match_ic1;
	always @(*) begin
		if (_sv2v_0)
			;
		hit_data_ecc_ic1 = 'b0;
		begin : sv2v_autoblock_1
			reg signed [31:0] way;
			for (way = 0; way < ibex_pkg_IC_NUM_WAYS; way = way + 1)
				if (tag_match_ic1[way])
					hit_data_ecc_ic1 = hit_data_ecc_ic1 | data_rdata_ic1[(1 - way) * LineSizeECC+:LineSizeECC];
		end
	end
	assign lowest_invalid_way_ic1[0] = tag_invalid_ic1[0];
	assign round_robin_way_ic1[0] = round_robin_way_q[1];
	genvar _gv_way_2;
	generate
		for (_gv_way_2 = 1; _gv_way_2 < ibex_pkg_IC_NUM_WAYS; _gv_way_2 = _gv_way_2 + 1) begin : gen_lowest_way
			localparam way = _gv_way_2;
			assign lowest_invalid_way_ic1[way] = tag_invalid_ic1[way] & ~|tag_invalid_ic1[way - 1:0];
			assign round_robin_way_ic1[way] = round_robin_way_q[way - 1];
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			round_robin_way_q <= 2'b01;
		else if (lookup_valid_ic1)
			round_robin_way_q <= round_robin_way_ic1;
	assign sel_way_ic1 = (|tag_invalid_ic1 ? lowest_invalid_way_ic1 : round_robin_way_q);
	generate
		if (ICacheECC) begin : gen_data_ecc_checking
			wire [1:0] tag_err_ic1;
			wire [(ibex_pkg_IC_LINE_BEATS * 2) - 1:0] data_err_ic1;
			wire ecc_correction_write_d;
			reg ecc_correction_write_q;
			wire [1:0] ecc_correction_ways_d;
			reg [1:0] ecc_correction_ways_q;
			reg [ibex_pkg_IC_INDEX_W - 1:0] lookup_index_ic1;
			reg [ibex_pkg_IC_INDEX_W - 1:0] ecc_correction_index_q;
			genvar _gv_way_3;
			for (_gv_way_3 = 0; _gv_way_3 < ibex_pkg_IC_NUM_WAYS; _gv_way_3 = _gv_way_3 + 1) begin : gen_tag_ecc
				localparam way = _gv_way_3;
				wire [1:0] tag_err_bank_ic1;
				wire [27:0] tag_rdata_padded_ic1;
				assign tag_rdata_padded_ic1 = {tag_rdata_ic1[((1 - way) * TagSizeECC) + (TagSizeECC - 1)-:6], {22 - ibex_pkg_IC_TAG_SIZE {1'b0}}, tag_rdata_ic1[((1 - way) * TagSizeECC) + (ibex_pkg_IC_TAG_SIZE - 1)-:ibex_pkg_IC_TAG_SIZE]};
				prim_secded_inv_28_22_dec data_ecc_dec(
					.data_i(tag_rdata_padded_ic1),
					.data_o(),
					.syndrome_o(),
					.err_o(tag_err_bank_ic1)
				);
				assign tag_err_ic1[way] = |tag_err_bank_ic1;
			end
			genvar _gv_bank_2;
			for (_gv_bank_2 = 0; _gv_bank_2 < ibex_pkg_IC_LINE_BEATS; _gv_bank_2 = _gv_bank_2 + 1) begin : gen_ecc_banks
				localparam bank = _gv_bank_2;
				prim_secded_inv_39_32_dec data_ecc_dec(
					.data_i(hit_data_ecc_ic1[bank * BusSizeECC+:BusSizeECC]),
					.data_o(),
					.syndrome_o(),
					.err_o(data_err_ic1[bank * 2+:2])
				);
				assign hit_data_ic1[bank * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] = hit_data_ecc_ic1[bank * BusSizeECC+:ibex_pkg_BUS_SIZE];
			end
			assign ecc_err_ic1 = lookup_valid_ic1 & ((|data_err_ic1 & tag_hit_ic1) | (|tag_err_ic1));
			assign ecc_correction_ways_d = {ibex_pkg_IC_NUM_WAYS {|tag_err_ic1}} | (tag_match_ic1 & {ibex_pkg_IC_NUM_WAYS {|data_err_ic1}});
			assign ecc_correction_write_d = ecc_err_ic1;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					ecc_correction_write_q <= 1'b0;
				else
					ecc_correction_write_q <= ecc_correction_write_d;
			if (ResetAll) begin : g_lookup_ind_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						lookup_index_ic1 <= 1'sb0;
					else if (lookup_grant_ic0)
						lookup_index_ic1 <= lookup_addr_ic0[ibex_pkg_IC_INDEX_HI-:ibex_pkg_IC_INDEX_W];
			end
			else begin : g_lookup_ind_nr
				always @(posedge clk_i)
					if (lookup_grant_ic0)
						lookup_index_ic1 <= lookup_addr_ic0[ibex_pkg_IC_INDEX_HI-:ibex_pkg_IC_INDEX_W];
			end
			if (ResetAll) begin : g_ecc_correction_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						ecc_correction_ways_q <= 1'sb0;
						ecc_correction_index_q <= 1'sb0;
					end
					else if (ecc_err_ic1) begin
						ecc_correction_ways_q <= ecc_correction_ways_d;
						ecc_correction_index_q <= lookup_index_ic1;
					end
			end
			else begin : g_ecc_correction_nr
				always @(posedge clk_i)
					if (ecc_err_ic1) begin
						ecc_correction_ways_q <= ecc_correction_ways_d;
						ecc_correction_index_q <= lookup_index_ic1;
					end
			end
			assign ecc_write_req = ecc_correction_write_q;
			assign ecc_write_ways = ecc_correction_ways_q;
			assign ecc_write_index = ecc_correction_index_q;
			assign ecc_error_o = ecc_err_ic1;
		end
		else begin : gen_no_data_ecc
			assign ecc_err_ic1 = 1'b0;
			assign ecc_write_req = 1'b0;
			assign ecc_write_ways = 1'sb0;
			assign ecc_write_index = 1'sb0;
			assign hit_data_ic1 = hit_data_ecc_ic1;
			assign ecc_error_o = 1'b0;
		end
		if (BranchCache) begin : gen_caching_logic
			localparam [31:0] CACHE_AHEAD = 2;
			localparam [31:0] CACHE_CNT_W = 2;
			wire cache_cnt_dec;
			wire [1:0] cache_cnt_d;
			reg [1:0] cache_cnt_q;
			assign cache_cnt_dec = lookup_grant_ic0 & |cache_cnt_q;
			assign cache_cnt_d = (branch_i ? CACHE_AHEAD[1:0] : cache_cnt_q - {1'b0, cache_cnt_dec});
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					cache_cnt_q <= 1'sb0;
				else
					cache_cnt_q <= cache_cnt_d;
			assign fill_cache_new = ((branch_i | (|cache_cnt_q)) & icache_enable_i) & ~inval_block_cache;
		end
		else begin : gen_cache_all
			assign fill_cache_new = icache_enable_i & ~inval_block_cache;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		fb_fill_level = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_busy_q[i] & ~fill_stale_q[i])
					fb_fill_level = fb_fill_level + 2'b01;
		end
	end
	assign fill_new_alloc = lookup_grant_ic0;
	assign fill_spec_req = (~icache_enable_i | branch_i) & ~|fill_ext_req;
	assign fill_spec_done = fill_spec_req & instr_gnt_i;
	assign fill_spec_hold = fill_spec_req & ~instr_gnt_i;
	genvar _gv_fb_1;
	generate
		for (_gv_fb_1 = 0; _gv_fb_1 < NUM_FB; _gv_fb_1 = _gv_fb_1 + 1) begin : gen_fbs
			localparam fb = _gv_fb_1;
			if (fb == 0) begin : gen_fb_zero
				assign fill_alloc_sel[fb] = ~fill_busy_q[fb];
			end
			else begin : gen_fb_rest
				assign fill_alloc_sel[fb] = ~fill_busy_q[fb] & (&fill_busy_q[fb - 1:0]);
			end
			assign fill_alloc[fb] = fill_alloc_sel[fb] & fill_new_alloc;
			assign fill_busy_d[fb] = fill_alloc[fb] | (fill_busy_q[fb] & ~fill_done[fb]);
			assign fill_older_d[fb * NUM_FB+:NUM_FB] = (fill_alloc[fb] ? fill_busy_q : fill_older_q[fb * NUM_FB+:NUM_FB]) & ~fill_done;
			assign fill_done[fb] = ((((fill_ram_done_q[fb] | fill_hit_q[fb]) | ~fill_cache_q[fb]) | (|fill_err_q[fb * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS])) & ((fill_out_done[fb] | fill_stale_q[fb]) | branch_i)) & fill_rvd_done[fb];
			assign fill_stale_d[fb] = fill_busy_q[fb] & (branch_i | fill_stale_q[fb]);
			assign fill_cache_d[fb] = (fill_alloc[fb] & fill_cache_new) | (((fill_cache_q[fb] & fill_busy_q[fb]) & icache_enable_i) & ~icache_inval_i);
			assign fill_hit_ic1[fb] = ((lookup_valid_ic1 & fill_in_ic1[fb]) & tag_hit_ic1) & ~ecc_err_ic1;
			assign fill_hit_d[fb] = fill_hit_ic1[fb] | (fill_hit_q[fb] & fill_busy_q[fb]);
			assign fill_ext_req[fb] = fill_busy_q[fb] & ~fill_ext_done_d[fb];
			assign fill_ext_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = (fill_alloc[fb] ? {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_spec_done} : fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] + {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_ext_arb[fb] & instr_gnt_i});
			assign fill_ext_hold_d[fb] = (fill_alloc[fb] & fill_spec_hold) | (fill_ext_arb[fb] & ~instr_gnt_i);
			assign fill_ext_done_d[fb] = ((((fill_ext_cnt_q[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)] | fill_hit_ic1[fb]) | fill_hit_q[fb]) | (~fill_cache_q[fb] & ((branch_i | fill_stale_q[fb]) | fill_ext_beat[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)]))) & ~fill_ext_hold_q[fb]) & fill_busy_q[fb];
			assign fill_rvd_exp[fb] = fill_busy_q[fb] & ~fill_rvd_done[fb];
			assign fill_rvd_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = (fill_alloc[fb] ? {(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W) * 1 {1'sb0}} : fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] + {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_rvd_arb[fb]});
			assign fill_rvd_done[fb] = (fill_ext_done_q[fb] & ~fill_ext_hold_q[fb]) & (fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] == fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)]);
			assign fill_out_req[fb] = ((fill_busy_q[fb] & ~fill_stale_q[fb]) & ~fill_out_done[fb]) & (((fill_hit_ic1[fb] | fill_hit_q[fb]) | (fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] > fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)])) | fill_rvd_arb[fb]);
			assign fill_out_grant[fb] = fill_out_arb[fb] & output_ready;
			assign fill_out_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = (fill_alloc[fb] ? {1'b0, lookup_addr_ic0[2:ibex_pkg_BUS_W]} : fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] + {{ibex_pkg_IC_LINE_BEATS_W {1'b0}}, fill_out_grant[fb]});
			assign fill_out_done[fb] = fill_out_cnt_q[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)];
			assign fill_ram_req[fb] = ((((fill_busy_q[fb] & fill_rvd_cnt_q[(fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : ibex_pkg_IC_LINE_BEATS_W - ibex_pkg_IC_LINE_BEATS_W)]) & ~fill_hit_q[fb]) & fill_cache_q[fb]) & ~|fill_err_q[fb * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS]) & ~fill_ram_done_q[fb];
			assign fill_ram_done_d[fb] = fill_ram_arb[fb] | (fill_ram_done_q[fb] & fill_busy_q[fb]);
			assign fill_ext_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = {1'b0, fill_addr_q[fb][2:ibex_pkg_BUS_W]} + fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1))) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)-:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
			assign fill_ext_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] = fill_ext_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1))) + ibex_pkg_IC_LINE_BEATS_W) - 1)-:ibex_pkg_IC_LINE_BEATS_W];
			assign fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] = {1'b0, fill_addr_q[fb][2:ibex_pkg_BUS_W]} + fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1) : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W : (ibex_pkg_IC_LINE_BEATS_W + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1))) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) - 1)-:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
			assign fill_rvd_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] = fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1)) : (((fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)) + (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W - 1 : ibex_pkg_IC_LINE_BEATS_W - (ibex_pkg_IC_LINE_BEATS_W - 1))) + ibex_pkg_IC_LINE_BEATS_W) - 1)-:ibex_pkg_IC_LINE_BEATS_W];
			assign fill_ext_arb[fb] = fill_ext_req[fb] & ~|(fill_ext_req & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_ram_arb[fb] = (fill_ram_req[fb] & fill_grant_ic0) & ~|(fill_ram_req & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_data_sel[fb] = ~|(((fill_busy_q & ~fill_out_done) & ~fill_stale_q) & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_out_arb[fb] = fill_out_req[fb] & fill_data_sel[fb];
			assign fill_rvd_arb[fb] = (instr_rvalid_i & fill_rvd_exp[fb]) & ~|(fill_rvd_exp & fill_older_q[fb * NUM_FB+:NUM_FB]);
			assign fill_data_reg[fb] = (((fill_busy_q[fb] & ~fill_stale_q[fb]) & ~fill_out_done[fb]) & fill_data_sel[fb]) & (((fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] > fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)]) | fill_hit_q[fb]) | (|fill_err_q[fb * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS]));
			assign fill_data_hit[fb] = (fill_busy_q[fb] & fill_hit_ic1[fb]) & fill_data_sel[fb];
			assign fill_data_rvd[fb] = ((((((fill_busy_q[fb] & fill_rvd_arb[fb]) & ~fill_hit_q[fb]) & ~fill_hit_ic1[fb]) & ~fill_stale_q[fb]) & ~fill_out_done[fb]) & (fill_rvd_beat[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] == fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)])) & fill_data_sel[fb];
			assign fill_entry_en[fb] = fill_alloc[fb] | fill_busy_q[fb];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					fill_busy_q[fb] <= 1'b0;
					fill_older_q[fb * NUM_FB+:NUM_FB] <= 1'sb0;
					fill_stale_q[fb] <= 1'b0;
					fill_cache_q[fb] <= 1'b0;
					fill_hit_q[fb] <= 1'b0;
					fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= 1'sb0;
					fill_ext_hold_q[fb] <= 1'b0;
					fill_ext_done_q[fb] <= 1'b0;
					fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= 1'sb0;
					fill_ram_done_q[fb] <= 1'b0;
					fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= 1'sb0;
				end
				else if (fill_entry_en[fb]) begin
					fill_busy_q[fb] <= fill_busy_d[fb];
					fill_older_q[fb * NUM_FB+:NUM_FB] <= fill_older_d[fb * NUM_FB+:NUM_FB];
					fill_stale_q[fb] <= fill_stale_d[fb];
					fill_cache_q[fb] <= fill_cache_d[fb];
					fill_hit_q[fb] <= fill_hit_d[fb];
					fill_ext_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= fill_ext_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
					fill_ext_hold_q[fb] <= fill_ext_hold_d[fb];
					fill_ext_done_q[fb] <= fill_ext_done_d[fb];
					fill_rvd_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= fill_rvd_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
					fill_ram_done_q[fb] <= fill_ram_done_d[fb];
					fill_out_cnt_q[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)] <= fill_out_cnt_d[(ibex_pkg_IC_LINE_BEATS_W >= 0 ? 0 : ibex_pkg_IC_LINE_BEATS_W) + (fb * (ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W))+:(ibex_pkg_IC_LINE_BEATS_W >= 0 ? ibex_pkg_IC_LINE_BEATS_W + 1 : 1 - ibex_pkg_IC_LINE_BEATS_W)];
				end
			assign fill_addr_en[fb] = fill_alloc[fb];
			assign fill_way_en[fb] = lookup_valid_ic1 & fill_in_ic1[fb];
			if (ResetAll) begin : g_fill_addr_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						fill_addr_q[fb] <= 1'sb0;
					else if (fill_addr_en[fb])
						fill_addr_q[fb] <= lookup_addr_ic0;
			end
			else begin : g_fill_addr_nr
				always @(posedge clk_i)
					if (fill_addr_en[fb])
						fill_addr_q[fb] <= lookup_addr_ic0;
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					fill_way_q[fb] <= 1'sb0;
				else if (fill_way_en[fb])
					fill_way_q[fb] <= sel_way_ic1;
			assign fill_data_d[fb] = (fill_hit_ic1[fb] ? hit_data_ic1 : {ibex_pkg_IC_LINE_BEATS {instr_rdata_i}});
			genvar _gv_b_1;
			for (_gv_b_1 = 0; _gv_b_1 < ibex_pkg_IC_LINE_BEATS; _gv_b_1 = _gv_b_1 + 1) begin : gen_data_buf
				localparam b = _gv_b_1;
				assign fill_err_d[(fb * ibex_pkg_IC_LINE_BEATS) + b] = ((fill_rvd_arb[fb] & instr_err_i) & (fill_rvd_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] == b[ibex_pkg_IC_LINE_BEATS_W - 1:0])) | (fill_busy_q[fb] & fill_err_q[(fb * ibex_pkg_IC_LINE_BEATS) + b]);
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						fill_err_q[(fb * ibex_pkg_IC_LINE_BEATS) + b] <= 1'sb0;
					else if (fill_entry_en[fb])
						fill_err_q[(fb * ibex_pkg_IC_LINE_BEATS) + b] <= fill_err_d[(fb * ibex_pkg_IC_LINE_BEATS) + b];
				assign fill_data_en[(fb * ibex_pkg_IC_LINE_BEATS) + b] = fill_hit_ic1[fb] | ((fill_rvd_arb[fb] & ~fill_hit_q[fb]) & (fill_rvd_off[fb * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W] == b[ibex_pkg_IC_LINE_BEATS_W - 1:0]));
				if (ResetAll) begin : g_fill_data_ra
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							fill_data_q[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] <= 1'sb0;
						else if (fill_data_en[(fb * ibex_pkg_IC_LINE_BEATS) + b])
							fill_data_q[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] <= fill_data_d[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE];
				end
				else begin : g_fill_data_nr
					always @(posedge clk_i)
						if (fill_data_en[(fb * ibex_pkg_IC_LINE_BEATS) + b])
							fill_data_q[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE] <= fill_data_d[fb][b * ibex_pkg_BUS_SIZE+:ibex_pkg_BUS_SIZE];
				end
			end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		fill_ext_req_addr = 1'sb0;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_ext_arb[i])
					fill_ext_req_addr = fill_ext_req_addr | {fill_addr_q[i][31:ibex_pkg_IC_LINE_W], fill_ext_off[i * ibex_pkg_IC_LINE_BEATS_W+:ibex_pkg_IC_LINE_BEATS_W]};
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		fill_ram_req_addr = 1'sb0;
		fill_ram_req_way = 1'sb0;
		fill_ram_req_data = 1'sb0;
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_ram_arb[i]) begin
					fill_ram_req_addr = fill_ram_req_addr | fill_addr_q[i];
					fill_ram_req_way = fill_ram_req_way | fill_way_q[i];
					fill_ram_req_data = fill_ram_req_data | fill_data_q[i];
				end
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		fill_out_data = 1'sb0;
		fill_out_err = 1'sb0;
		begin : sv2v_autoblock_5
			reg signed [31:0] i;
			for (i = 0; i < NUM_FB; i = i + 1)
				if (fill_data_reg[i]) begin
					fill_out_data = fill_out_data | fill_data_q[i];
					fill_out_err = fill_out_err | (fill_err_q[i * ibex_pkg_IC_LINE_BEATS+:ibex_pkg_IC_LINE_BEATS] & ~{ibex_pkg_IC_LINE_BEATS {fill_hit_q[i]}});
				end
		end
	end
	assign instr_req = ((~icache_enable_i | branch_i) & lookup_grant_ic0) | (|fill_ext_req);
	assign instr_addr = (|fill_ext_req ? fill_ext_req_addr : lookup_addr_ic0[31:ibex_pkg_BUS_W]);
	assign instr_req_o = instr_req;
	assign instr_addr_o = {instr_addr[31:ibex_pkg_BUS_W], {ibex_pkg_BUS_W {1'b0}}};
	assign line_data = (|fill_data_hit ? hit_data_ic1 : fill_out_data);
	assign line_err = (|fill_data_hit ? {ibex_pkg_IC_LINE_BEATS {1'b0}} : fill_out_err);
	always @(*) begin
		if (_sv2v_0)
			;
		line_data_muxed = 1'sb0;
		line_err_muxed = 1'b0;
		begin : sv2v_autoblock_6
			reg [31:0] i;
			for (i = 0; i < ibex_pkg_IC_LINE_BEATS; i = i + 1)
				if ((output_addr_q[2:ibex_pkg_BUS_W] + {{ibex_pkg_IC_LINE_BEATS_W - 1 {1'b0}}, skid_valid_q}) == i[ibex_pkg_IC_LINE_BEATS_W - 1:0]) begin
					line_data_muxed = line_data_muxed | line_data[i * 32+:32];
					line_err_muxed = line_err_muxed | line_err[i];
				end
		end
	end
	assign output_data = (|fill_data_rvd ? instr_rdata_i : line_data_muxed);
	assign output_err = (|fill_data_rvd ? instr_err_i : line_err_muxed);
	assign data_valid = |fill_out_arb;
	assign skid_data_d = output_data[31:16];
	assign skid_en = data_valid & (ready_i | skid_ready);
	generate
		if (ResetAll) begin : g_skid_data_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					skid_data_q <= 1'sb0;
					skid_err_q <= 1'sb0;
				end
				else if (skid_en) begin
					skid_data_q <= skid_data_d;
					skid_err_q <= output_err;
				end
		end
		else begin : g_skid_data_nr
			always @(posedge clk_i)
				if (skid_en) begin
					skid_data_q <= skid_data_d;
					skid_err_q <= output_err;
				end
		end
	endgenerate
	assign skid_complete_instr = skid_valid_q & ((skid_data_q[1:0] != 2'b11) | skid_err_q);
	assign skid_ready = (output_addr_q[1] & ~skid_valid_q) & (~output_compressed | output_err);
	assign output_ready = (ready_i | skid_ready) & ~skid_complete_instr;
	assign output_compressed = rdata_o[1:0] != 2'b11;
	assign skid_valid_d = (branch_i ? 1'b0 : (skid_valid_q ? ~(ready_i & ((skid_data_q[1:0] != 2'b11) | skid_err_q)) : data_valid & ((output_addr_q[1] & (~output_compressed | output_err)) | (((~output_addr_q[1] & output_compressed) & ~output_err) & ready_i))));
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			skid_valid_q <= 1'b0;
		else
			skid_valid_q <= skid_valid_d;
	assign output_valid = skid_complete_instr | (data_valid & (((~output_addr_q[1] | skid_valid_q) | output_err) | (output_data[17:16] != 2'b11)));
	assign output_addr_en = branch_i | (ready_i & valid_o);
	assign addr_incr_two = output_compressed & ~err_o;
	assign output_addr_incr = output_addr_q[31:1] + {29'd0, ~addr_incr_two, addr_incr_two};
	assign output_addr_d = (branch_i ? addr_i[31:1] : output_addr_incr);
	generate
		if (ResetAll) begin : g_output_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					output_addr_q <= 1'sb0;
				else if (output_addr_en)
					output_addr_q <= output_addr_d;
		end
		else begin : g_output_addr_nr
			always @(posedge clk_i)
				if (output_addr_en)
					output_addr_q <= output_addr_d;
		end
	endgenerate
	localparam [31:0] ibex_pkg_IC_OUTPUT_BEATS = 2;
	always @(*) begin
		if (_sv2v_0)
			;
		output_data_lo = 1'sb0;
		begin : sv2v_autoblock_7
			reg [31:0] i;
			for (i = 0; i < ibex_pkg_IC_OUTPUT_BEATS; i = i + 1)
				if (output_addr_q[1:1] == i[0:0])
					output_data_lo = output_data_lo | output_data[i * 16+:16];
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		output_data_hi = 1'sb0;
		begin : sv2v_autoblock_8
			reg [31:0] i;
			for (i = 0; i < 1; i = i + 1)
				if (output_addr_q[1:1] == i[0:0])
					output_data_hi = output_data_hi | output_data[(i + 1) * 16+:16];
		end
		if (&output_addr_q[1:1])
			output_data_hi = output_data_hi | output_data[15:0];
	end
	assign valid_o = output_valid;
	assign rdata_o = {output_data_hi, (skid_valid_q ? skid_data_q : output_data_lo)};
	assign addr_o = {output_addr_q, 1'b0};
	assign err_o = (skid_valid_q & skid_err_q) | (~skid_complete_instr & output_err);
	assign err_plus2_o = skid_valid_q & ~skid_err_q;
	always @(*) begin
		if (_sv2v_0)
			;
		inval_state_d = inval_state_q;
		inval_index_d = inval_index_q;
		inval_index_en = 1'b0;
		inval_write_req = 1'b0;
		ic_scr_key_req_o = 1'b0;
		inval_block_cache = 1'b1;
		(* full_case, parallel_case *)
		case (inval_state_q)
			2'd0: begin
				inval_state_d = 2'd1;
				if (~ic_scr_key_valid_i)
					ic_scr_key_req_o = 1'b1;
			end
			2'd1:
				if (ic_scr_key_valid_i) begin
					inval_state_d = 2'd2;
					inval_index_d = 1'sb0;
					inval_index_en = 1'b1;
				end
			2'd2: begin
				inval_write_req = 1'b1;
				inval_index_d = inval_index_q + {{ibex_pkg_IC_INDEX_W - 1 {1'b0}}, 1'b1};
				inval_index_en = 1'b1;
				if (icache_inval_i) begin
					ic_scr_key_req_o = 1'b1;
					inval_state_d = 2'd1;
				end
				else if (&inval_index_q)
					inval_state_d = 2'd3;
			end
			2'd3:
				if (icache_inval_i) begin
					ic_scr_key_req_o = 1'b1;
					inval_state_d = 2'd1;
				end
				else
					inval_block_cache = 1'b0;
			default:
				;
		endcase
	end
	assign inval_active = inval_state_q != 2'd3;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inval_state_q <= 2'd0;
		else
			inval_state_q <= inval_state_d;
	generate
		if (ResetAll) begin : g_inval_index_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inval_index_q <= 1'sb0;
				else if (inval_index_en)
					inval_index_q <= inval_index_d;
		end
		else begin : g_inval_index_nr
			always @(posedge clk_i)
				if (inval_index_en)
					inval_index_q <= inval_index_d;
		end
	endgenerate
	assign busy_o = inval_active | (|(fill_busy_q & ~fill_rvd_done));
	initial _sv2v_0 = 0;
endmodule
module ibex_id_stage (
	clk_i,
	rst_ni,
	ctrl_busy_o,
	illegal_insn_o,
	instr_valid_i,
	instr_rdata_i,
	instr_rdata_alu_i,
	instr_rdata_c_i,
	instr_is_compressed_i,
	instr_bp_taken_i,
	instr_req_o,
	instr_first_cycle_id_o,
	instr_valid_clear_o,
	id_in_ready_o,
	instr_exec_i,
	icache_inval_o,
	branch_decision_i,
	pc_set_o,
	pc_mux_o,
	nt_branch_mispredict_o,
	nt_branch_addr_o,
	exc_pc_mux_o,
	exc_cause_o,
	illegal_c_insn_i,
	instr_fetch_err_i,
	instr_fetch_err_plus2_i,
	pc_id_i,
	ex_valid_i,
	lsu_resp_valid_i,
	alu_operator_ex_o,
	alu_operand_a_ex_o,
	alu_operand_b_ex_o,
	imd_val_we_ex_i,
	imd_val_d_ex_i,
	imd_val_q_ex_o,
	bt_a_operand_o,
	bt_b_operand_o,
	mult_en_ex_o,
	div_en_ex_o,
	mult_sel_ex_o,
	div_sel_ex_o,
	multdiv_operator_ex_o,
	multdiv_signed_mode_ex_o,
	multdiv_operand_a_ex_o,
	multdiv_operand_b_ex_o,
	multdiv_ready_id_o,
	csr_access_o,
	csr_op_o,
	csr_op_en_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_wb_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	csr_mtval_o,
	priv_mode_i,
	csr_mstatus_tw_i,
	illegal_csr_insn_i,
	data_ind_timing_i,
	lsu_req_o,
	lsu_we_o,
	lsu_type_o,
	lsu_sign_ext_o,
	lsu_wdata_o,
	lsu_req_done_i,
	lsu_addr_incr_req_i,
	lsu_addr_last_i,
	csr_mstatus_mie_i,
	irq_pending_i,
	irqs_i,
	irq_nm_i,
	nmi_mode_o,
	lsu_load_err_i,
	lsu_load_resp_intg_err_i,
	lsu_store_err_i,
	lsu_store_resp_intg_err_i,
	expecting_load_resp_o,
	expecting_store_resp_o,
	debug_mode_o,
	debug_mode_entering_o,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	result_ex_i,
	csr_rdata_i,
	rf_raddr_a_o,
	rf_rdata_a_i,
	rf_raddr_b_o,
	rf_rdata_b_i,
	rf_ren_a_o,
	rf_ren_b_o,
	rf_waddr_id_o,
	rf_wdata_id_o,
	rf_we_id_o,
	rf_rd_a_wb_match_o,
	rf_rd_b_wb_match_o,
	rf_waddr_wb_i,
	rf_wdata_fwd_wb_i,
	rf_write_wb_i,
	en_wb_o,
	instr_type_wb_o,
	instr_perf_count_id_o,
	ready_wb_i,
	outstanding_load_wb_i,
	outstanding_store_wb_i,
	perf_jump_o,
	perf_branch_o,
	perf_tbranch_o,
	perf_dside_wait_o,
	perf_mul_wait_o,
	perf_div_wait_o,
	instr_id_done_o
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] DataIndTiming = 1'b0;
	parameter [0:0] BranchTargetALU = 0;
	parameter [0:0] WritebackStage = 0;
	parameter [0:0] BranchPredictor = 0;
	parameter [0:0] MemECC = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	output wire ctrl_busy_o;
	output wire illegal_insn_o;
	input wire instr_valid_i;
	input wire [31:0] instr_rdata_i;
	input wire [31:0] instr_rdata_alu_i;
	input wire [15:0] instr_rdata_c_i;
	input wire instr_is_compressed_i;
	input wire instr_bp_taken_i;
	output wire instr_req_o;
	output wire instr_first_cycle_id_o;
	output wire instr_valid_clear_o;
	output wire id_in_ready_o;
	input wire instr_exec_i;
	output wire icache_inval_o;
	input wire branch_decision_i;
	output wire pc_set_o;
	output wire [2:0] pc_mux_o;
	output wire nt_branch_mispredict_o;
	output wire [31:0] nt_branch_addr_o;
	output wire [1:0] exc_pc_mux_o;
	output wire [6:0] exc_cause_o;
	input wire illegal_c_insn_i;
	input wire instr_fetch_err_i;
	input wire instr_fetch_err_plus2_i;
	input wire [31:0] pc_id_i;
	input wire ex_valid_i;
	input wire lsu_resp_valid_i;
	output wire [6:0] alu_operator_ex_o;
	output wire [31:0] alu_operand_a_ex_o;
	output wire [31:0] alu_operand_b_ex_o;
	input wire [1:0] imd_val_we_ex_i;
	input wire [67:0] imd_val_d_ex_i;
	output wire [67:0] imd_val_q_ex_o;
	output reg [31:0] bt_a_operand_o;
	output reg [31:0] bt_b_operand_o;
	output wire mult_en_ex_o;
	output wire div_en_ex_o;
	output wire mult_sel_ex_o;
	output wire div_sel_ex_o;
	output wire [1:0] multdiv_operator_ex_o;
	output wire [1:0] multdiv_signed_mode_ex_o;
	output wire [31:0] multdiv_operand_a_ex_o;
	output wire [31:0] multdiv_operand_b_ex_o;
	output wire multdiv_ready_id_o;
	output wire csr_access_o;
	output wire [1:0] csr_op_o;
	output wire csr_op_en_o;
	output wire csr_save_if_o;
	output wire csr_save_id_o;
	output wire csr_save_wb_o;
	output wire csr_restore_mret_id_o;
	output wire csr_restore_dret_id_o;
	output wire csr_save_cause_o;
	output wire [31:0] csr_mtval_o;
	input wire [1:0] priv_mode_i;
	input wire csr_mstatus_tw_i;
	input wire illegal_csr_insn_i;
	input wire data_ind_timing_i;
	output wire lsu_req_o;
	output wire lsu_we_o;
	output wire [1:0] lsu_type_o;
	output wire lsu_sign_ext_o;
	output wire [31:0] lsu_wdata_o;
	input wire lsu_req_done_i;
	input wire lsu_addr_incr_req_i;
	input wire [31:0] lsu_addr_last_i;
	input wire csr_mstatus_mie_i;
	input wire irq_pending_i;
	input wire [17:0] irqs_i;
	input wire irq_nm_i;
	output wire nmi_mode_o;
	input wire lsu_load_err_i;
	input wire lsu_load_resp_intg_err_i;
	input wire lsu_store_err_i;
	input wire lsu_store_resp_intg_err_i;
	output wire expecting_load_resp_o;
	output wire expecting_store_resp_o;
	output wire debug_mode_o;
	output wire debug_mode_entering_o;
	output wire [2:0] debug_cause_o;
	output wire debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	input wire [31:0] result_ex_i;
	input wire [31:0] csr_rdata_i;
	output wire [4:0] rf_raddr_a_o;
	input wire [31:0] rf_rdata_a_i;
	output wire [4:0] rf_raddr_b_o;
	input wire [31:0] rf_rdata_b_i;
	output wire rf_ren_a_o;
	output wire rf_ren_b_o;
	output wire [4:0] rf_waddr_id_o;
	output reg [31:0] rf_wdata_id_o;
	output wire rf_we_id_o;
	output wire rf_rd_a_wb_match_o;
	output wire rf_rd_b_wb_match_o;
	input wire [4:0] rf_waddr_wb_i;
	input wire [31:0] rf_wdata_fwd_wb_i;
	input wire rf_write_wb_i;
	output wire en_wb_o;
	output wire [1:0] instr_type_wb_o;
	output wire instr_perf_count_id_o;
	input wire ready_wb_i;
	input wire outstanding_load_wb_i;
	input wire outstanding_store_wb_i;
	output wire perf_jump_o;
	output reg perf_branch_o;
	output wire perf_tbranch_o;
	output wire perf_dside_wait_o;
	output wire perf_mul_wait_o;
	output wire perf_div_wait_o;
	output wire instr_id_done_o;
	wire illegal_insn_dec;
	wire illegal_dret_insn;
	wire illegal_umode_insn;
	wire ebrk_insn;
	wire mret_insn_dec;
	wire dret_insn_dec;
	wire ecall_insn_dec;
	wire wfi_insn_dec;
	wire wb_exception;
	wire id_exception;
	wire branch_in_dec;
	wire branch_set;
	wire branch_set_raw;
	reg branch_set_raw_d;
	reg branch_jump_set_done_q;
	wire branch_jump_set_done_d;
	reg branch_not_set;
	wire branch_taken;
	wire jump_in_dec;
	wire jump_set_dec;
	wire jump_set;
	reg jump_set_raw;
	wire instr_first_cycle;
	wire instr_executing_spec;
	wire instr_executing;
	wire instr_done;
	wire controller_run;
	wire stall_ld_hz;
	wire stall_mem;
	reg stall_multdiv;
	reg stall_branch;
	reg stall_jump;
	wire stall_id;
	wire stall_wb;
	wire flush_id;
	wire multicycle_done;
	wire mem_resp_intg_err;
	wire [31:0] imm_i_type;
	wire [31:0] imm_s_type;
	wire [31:0] imm_b_type;
	wire [31:0] imm_u_type;
	wire [31:0] imm_j_type;
	wire [31:0] zimm_rs1_type;
	wire [31:0] imm_a;
	reg [31:0] imm_b;
	wire rf_wdata_sel;
	wire rf_we_dec;
	reg rf_we_raw;
	wire rf_ren_a;
	wire rf_ren_b;
	wire rf_ren_a_dec;
	wire rf_ren_b_dec;
	assign rf_ren_a = ((instr_valid_i & ~instr_fetch_err_i) & ~illegal_insn_o) & rf_ren_a_dec;
	assign rf_ren_b = ((instr_valid_i & ~instr_fetch_err_i) & ~illegal_insn_o) & rf_ren_b_dec;
	assign rf_ren_a_o = rf_ren_a;
	assign rf_ren_b_o = rf_ren_b;
	wire [31:0] rf_rdata_a_fwd;
	wire [31:0] rf_rdata_b_fwd;
	wire [6:0] alu_operator;
	wire [1:0] alu_op_a_mux_sel;
	wire [1:0] alu_op_a_mux_sel_dec;
	wire alu_op_b_mux_sel;
	wire alu_op_b_mux_sel_dec;
	wire alu_multicycle_dec;
	reg stall_alu;
	reg [67:0] imd_val_q;
	wire [1:0] bt_a_mux_sel;
	wire [2:0] bt_b_mux_sel;
	wire imm_a_mux_sel;
	wire [2:0] imm_b_mux_sel;
	wire [2:0] imm_b_mux_sel_dec;
	wire mult_en_id;
	wire mult_en_dec;
	wire div_en_id;
	wire div_en_dec;
	wire multdiv_en_dec;
	wire [1:0] multdiv_operator;
	wire [1:0] multdiv_signed_mode;
	wire lsu_we;
	wire [1:0] lsu_type;
	wire lsu_sign_ext;
	wire lsu_req;
	wire lsu_req_dec;
	wire data_req_allowed;
	reg csr_pipe_flush;
	reg [31:0] alu_operand_a;
	wire [31:0] alu_operand_b;
	assign alu_op_a_mux_sel = (lsu_addr_incr_req_i ? 2'd1 : alu_op_a_mux_sel_dec);
	assign alu_op_b_mux_sel = (lsu_addr_incr_req_i ? 1'd1 : alu_op_b_mux_sel_dec);
	assign imm_b_mux_sel = (lsu_addr_incr_req_i ? 3'd6 : imm_b_mux_sel_dec);
	assign imm_a = (imm_a_mux_sel == 1'd0 ? zimm_rs1_type : {32 {1'sb0}});
	always @(*) begin : alu_operand_a_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (alu_op_a_mux_sel)
			2'd0: alu_operand_a = rf_rdata_a_fwd;
			2'd1: alu_operand_a = lsu_addr_last_i;
			2'd2: alu_operand_a = pc_id_i;
			2'd3: alu_operand_a = imm_a;
			default: alu_operand_a = pc_id_i;
		endcase
	end
	generate
		if (BranchTargetALU) begin : g_btalu_muxes
			always @(*) begin : bt_operand_a_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (bt_a_mux_sel)
					2'd0: bt_a_operand_o = rf_rdata_a_fwd;
					2'd2: bt_a_operand_o = pc_id_i;
					default: bt_a_operand_o = pc_id_i;
				endcase
			end
			always @(*) begin : bt_immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (bt_b_mux_sel)
					3'd0: bt_b_operand_o = imm_i_type;
					3'd2: bt_b_operand_o = imm_b_type;
					3'd4: bt_b_operand_o = imm_j_type;
					3'd5: bt_b_operand_o = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					default: bt_b_operand_o = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
				endcase
			end
			always @(*) begin : immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (imm_b_mux_sel)
					3'd0: imm_b = imm_i_type;
					3'd1: imm_b = imm_s_type;
					3'd3: imm_b = imm_u_type;
					3'd5: imm_b = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					3'd6: imm_b = 32'h00000004;
					default: imm_b = 32'h00000004;
				endcase
			end
		end
		else begin : g_nobtalu
			wire [1:0] unused_a_mux_sel;
			wire [2:0] unused_b_mux_sel;
			assign unused_a_mux_sel = bt_a_mux_sel;
			assign unused_b_mux_sel = bt_b_mux_sel;
			wire [32:1] sv2v_tmp_1FCCD;
			assign sv2v_tmp_1FCCD = 1'sb0;
			always @(*) bt_a_operand_o = sv2v_tmp_1FCCD;
			wire [32:1] sv2v_tmp_B876E;
			assign sv2v_tmp_B876E = 1'sb0;
			always @(*) bt_b_operand_o = sv2v_tmp_B876E;
			always @(*) begin : immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (imm_b_mux_sel)
					3'd0: imm_b = imm_i_type;
					3'd1: imm_b = imm_s_type;
					3'd2: imm_b = imm_b_type;
					3'd3: imm_b = imm_u_type;
					3'd4: imm_b = imm_j_type;
					3'd5: imm_b = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					3'd6: imm_b = 32'h00000004;
					default: imm_b = 32'h00000004;
				endcase
			end
		end
	endgenerate
	assign alu_operand_b = (alu_op_b_mux_sel == 1'd1 ? imm_b : rf_rdata_b_fwd);
	genvar _gv_i_30;
	generate
		for (_gv_i_30 = 0; _gv_i_30 < 2; _gv_i_30 = _gv_i_30 + 1) begin : gen_intermediate_val_reg
			localparam i = _gv_i_30;
			always @(posedge clk_i or negedge rst_ni) begin : intermediate_val_reg
				if (!rst_ni)
					imd_val_q[(1 - i) * 34+:34] <= 1'sb0;
				else if (imd_val_we_ex_i[i])
					imd_val_q[(1 - i) * 34+:34] <= imd_val_d_ex_i[(1 - i) * 34+:34];
			end
		end
	endgenerate
	assign imd_val_q_ex_o = imd_val_q;
	assign rf_we_id_o = (rf_we_raw & instr_executing) & ~illegal_csr_insn_i;
	always @(*) begin : rf_wdata_id_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rf_wdata_sel)
			1'd0: rf_wdata_id_o = result_ex_i;
			1'd1: rf_wdata_id_o = csr_rdata_i;
			default: rf_wdata_id_o = result_ex_i;
		endcase
	end
	ibex_decoder #(
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU)
	) decoder_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.illegal_insn_o(illegal_insn_dec),
		.ebrk_insn_o(ebrk_insn),
		.mret_insn_o(mret_insn_dec),
		.dret_insn_o(dret_insn_dec),
		.ecall_insn_o(ecall_insn_dec),
		.wfi_insn_o(wfi_insn_dec),
		.jump_set_o(jump_set_dec),
		.branch_taken_i(branch_taken),
		.icache_inval_o(icache_inval_o),
		.instr_first_cycle_i(instr_first_cycle),
		.instr_rdata_i(instr_rdata_i),
		.instr_rdata_alu_i(instr_rdata_alu_i),
		.illegal_c_insn_i(illegal_c_insn_i),
		.imm_a_mux_sel_o(imm_a_mux_sel),
		.imm_b_mux_sel_o(imm_b_mux_sel_dec),
		.bt_a_mux_sel_o(bt_a_mux_sel),
		.bt_b_mux_sel_o(bt_b_mux_sel),
		.imm_i_type_o(imm_i_type),
		.imm_s_type_o(imm_s_type),
		.imm_b_type_o(imm_b_type),
		.imm_u_type_o(imm_u_type),
		.imm_j_type_o(imm_j_type),
		.zimm_rs1_type_o(zimm_rs1_type),
		.rf_wdata_sel_o(rf_wdata_sel),
		.rf_we_o(rf_we_dec),
		.rf_raddr_a_o(rf_raddr_a_o),
		.rf_raddr_b_o(rf_raddr_b_o),
		.rf_waddr_o(rf_waddr_id_o),
		.rf_ren_a_o(rf_ren_a_dec),
		.rf_ren_b_o(rf_ren_b_dec),
		.alu_operator_o(alu_operator),
		.alu_op_a_mux_sel_o(alu_op_a_mux_sel_dec),
		.alu_op_b_mux_sel_o(alu_op_b_mux_sel_dec),
		.alu_multicycle_o(alu_multicycle_dec),
		.mult_en_o(mult_en_dec),
		.div_en_o(div_en_dec),
		.mult_sel_o(mult_sel_ex_o),
		.div_sel_o(div_sel_ex_o),
		.multdiv_operator_o(multdiv_operator),
		.multdiv_signed_mode_o(multdiv_signed_mode),
		.csr_access_o(csr_access_o),
		.csr_op_o(csr_op_o),
		.data_req_o(lsu_req_dec),
		.data_we_o(lsu_we),
		.data_type_o(lsu_type),
		.data_sign_extension_o(lsu_sign_ext),
		.jump_in_dec_o(jump_in_dec),
		.branch_in_dec_o(branch_in_dec)
	);
	always @(*) begin : csr_pipeline_flushes
		if (_sv2v_0)
			;
		csr_pipe_flush = 1'b0;
		if ((csr_op_en_o == 1'b1) && ((csr_op_o == 2'd1) || (csr_op_o == 2'd2))) begin
			if ((((instr_rdata_i[31:20] == 12'h300) || (instr_rdata_i[31:20] == 12'h304)) || (instr_rdata_i[31:20] == 12'h747)) || (instr_rdata_i[31:25] == 7'h1d))
				csr_pipe_flush = 1'b1;
		end
		else if ((csr_op_en_o == 1'b1) && (csr_op_o != 2'd0)) begin
			if ((((instr_rdata_i[31:20] == 12'h7b0) || (instr_rdata_i[31:20] == 12'h7b1)) || (instr_rdata_i[31:20] == 12'h7b2)) || (instr_rdata_i[31:20] == 12'h7b3))
				csr_pipe_flush = 1'b1;
		end
	end
	assign illegal_dret_insn = dret_insn_dec & ~debug_mode_o;
	assign illegal_umode_insn = (priv_mode_i != 2'b11) & (mret_insn_dec | (csr_mstatus_tw_i & wfi_insn_dec));
	assign illegal_insn_o = instr_valid_i & (((illegal_insn_dec | illegal_csr_insn_i) | illegal_dret_insn) | illegal_umode_insn);
	assign mem_resp_intg_err = lsu_load_resp_intg_err_i | lsu_store_resp_intg_err_i;
	ibex_controller #(
		.WritebackStage(WritebackStage),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC)
	) controller_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.ctrl_busy_o(ctrl_busy_o),
		.illegal_insn_i(illegal_insn_o),
		.ecall_insn_i(ecall_insn_dec),
		.mret_insn_i(mret_insn_dec),
		.dret_insn_i(dret_insn_dec),
		.wfi_insn_i(wfi_insn_dec),
		.ebrk_insn_i(ebrk_insn),
		.csr_pipe_flush_i(csr_pipe_flush),
		.instr_valid_i(instr_valid_i),
		.instr_i(instr_rdata_i),
		.instr_compressed_i(instr_rdata_c_i),
		.instr_is_compressed_i(instr_is_compressed_i),
		.instr_bp_taken_i(instr_bp_taken_i),
		.instr_fetch_err_i(instr_fetch_err_i),
		.instr_fetch_err_plus2_i(instr_fetch_err_plus2_i),
		.pc_id_i(pc_id_i),
		.instr_valid_clear_o(instr_valid_clear_o),
		.id_in_ready_o(id_in_ready_o),
		.controller_run_o(controller_run),
		.instr_exec_i(instr_exec_i),
		.instr_req_o(instr_req_o),
		.pc_set_o(pc_set_o),
		.pc_mux_o(pc_mux_o),
		.nt_branch_mispredict_o(nt_branch_mispredict_o),
		.exc_pc_mux_o(exc_pc_mux_o),
		.exc_cause_o(exc_cause_o),
		.lsu_addr_last_i(lsu_addr_last_i),
		.load_err_i(lsu_load_err_i),
		.mem_resp_intg_err_i(mem_resp_intg_err),
		.store_err_i(lsu_store_err_i),
		.wb_exception_o(wb_exception),
		.id_exception_o(id_exception),
		.branch_set_i(branch_set),
		.branch_not_set_i(branch_not_set),
		.jump_set_i(jump_set),
		.csr_mstatus_mie_i(csr_mstatus_mie_i),
		.irq_pending_i(irq_pending_i),
		.irqs_i(irqs_i),
		.irq_nm_ext_i(irq_nm_i),
		.nmi_mode_o(nmi_mode_o),
		.csr_save_if_o(csr_save_if_o),
		.csr_save_id_o(csr_save_id_o),
		.csr_save_wb_o(csr_save_wb_o),
		.csr_restore_mret_id_o(csr_restore_mret_id_o),
		.csr_restore_dret_id_o(csr_restore_dret_id_o),
		.csr_save_cause_o(csr_save_cause_o),
		.csr_mtval_o(csr_mtval_o),
		.priv_mode_i(priv_mode_i),
		.debug_mode_o(debug_mode_o),
		.debug_mode_entering_o(debug_mode_entering_o),
		.debug_cause_o(debug_cause_o),
		.debug_csr_save_o(debug_csr_save_o),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step_i),
		.debug_ebreakm_i(debug_ebreakm_i),
		.debug_ebreaku_i(debug_ebreaku_i),
		.trigger_match_i(trigger_match_i),
		.stall_id_i(stall_id),
		.stall_wb_i(stall_wb),
		.flush_id_o(flush_id),
		.ready_wb_i(ready_wb_i),
		.perf_jump_o(perf_jump_o),
		.perf_tbranch_o(perf_tbranch_o)
	);
	assign multdiv_en_dec = mult_en_dec | div_en_dec;
	assign lsu_req = (instr_executing ? data_req_allowed & lsu_req_dec : 1'b0);
	assign mult_en_id = (instr_executing ? mult_en_dec : 1'b0);
	assign div_en_id = (instr_executing ? div_en_dec : 1'b0);
	assign lsu_req_o = lsu_req;
	assign lsu_we_o = lsu_we;
	assign lsu_type_o = lsu_type;
	assign lsu_sign_ext_o = lsu_sign_ext;
	assign lsu_wdata_o = rf_rdata_b_fwd;
	assign csr_op_en_o = (csr_access_o & instr_executing) & instr_id_done_o;
	assign alu_operator_ex_o = alu_operator;
	assign alu_operand_a_ex_o = alu_operand_a;
	assign alu_operand_b_ex_o = alu_operand_b;
	assign mult_en_ex_o = mult_en_id;
	assign div_en_ex_o = div_en_id;
	assign multdiv_operator_ex_o = multdiv_operator;
	assign multdiv_signed_mode_ex_o = multdiv_signed_mode;
	assign multdiv_operand_a_ex_o = rf_rdata_a_fwd;
	assign multdiv_operand_b_ex_o = rf_rdata_b_fwd;
	generate
		if (BranchTargetALU && !DataIndTiming) begin : g_branch_set_direct
			assign branch_set_raw = branch_set_raw_d;
		end
		else begin : g_branch_set_flop
			reg branch_set_raw_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					branch_set_raw_q <= 1'b0;
				else
					branch_set_raw_q <= branch_set_raw_d;
			assign branch_set_raw = (BranchTargetALU && !data_ind_timing_i ? branch_set_raw_d : branch_set_raw_q);
		end
	endgenerate
	assign branch_jump_set_done_d = ((branch_set_raw | jump_set_raw) | branch_jump_set_done_q) & ~instr_valid_clear_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			branch_jump_set_done_q <= 1'b0;
		else
			branch_jump_set_done_q <= branch_jump_set_done_d;
	assign jump_set = jump_set_raw & ~branch_jump_set_done_q;
	assign branch_set = branch_set_raw & ~branch_jump_set_done_q;
	generate
		if (DataIndTiming) begin : g_sec_branch_taken
			reg branch_taken_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					branch_taken_q <= 1'b0;
				else
					branch_taken_q <= branch_decision_i;
			assign branch_taken = ~data_ind_timing_i | branch_taken_q;
		end
		else begin : g_nosec_branch_taken
			assign branch_taken = 1'b1;
		end
		if (BranchPredictor) begin : g_calc_nt_addr
			assign nt_branch_addr_o = pc_id_i + (instr_is_compressed_i ? 32'd2 : 32'd4);
		end
		else begin : g_n_calc_nt_addr
			assign nt_branch_addr_o = 32'd0;
		end
	endgenerate
	reg id_fsm_q;
	reg id_fsm_d;
	always @(posedge clk_i or negedge rst_ni) begin : id_pipeline_reg
		if (!rst_ni)
			id_fsm_q <= 1'd0;
		else if (instr_executing)
			id_fsm_q <= id_fsm_d;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		id_fsm_d = id_fsm_q;
		rf_we_raw = rf_we_dec;
		stall_multdiv = 1'b0;
		stall_jump = 1'b0;
		stall_branch = 1'b0;
		stall_alu = 1'b0;
		branch_set_raw_d = 1'b0;
		branch_not_set = 1'b0;
		jump_set_raw = 1'b0;
		perf_branch_o = 1'b0;
		if (instr_executing_spec)
			(* full_case, parallel_case *)
			case (id_fsm_q)
				1'd0:
					(* full_case, parallel_case *)
					case (1'b1)
						lsu_req_dec:
							if (!WritebackStage)
								id_fsm_d = 1'd1;
							else if (~lsu_req_done_i)
								id_fsm_d = 1'd1;
						multdiv_en_dec:
							if (~ex_valid_i) begin
								id_fsm_d = 1'd1;
								rf_we_raw = 1'b0;
								stall_multdiv = 1'b1;
							end
						branch_in_dec: begin
							id_fsm_d = (data_ind_timing_i || (!BranchTargetALU && branch_decision_i) ? 1'd1 : 1'd0);
							stall_branch = (~BranchTargetALU & branch_decision_i) | data_ind_timing_i;
							branch_set_raw_d = branch_decision_i | data_ind_timing_i;
							if (BranchPredictor)
								branch_not_set = ~branch_decision_i;
							perf_branch_o = 1'b1;
						end
						jump_in_dec: begin
							id_fsm_d = (BranchTargetALU ? 1'd0 : 1'd1);
							stall_jump = ~BranchTargetALU;
							jump_set_raw = jump_set_dec;
						end
						alu_multicycle_dec: begin
							stall_alu = 1'b1;
							id_fsm_d = 1'd1;
							rf_we_raw = 1'b0;
						end
						default: id_fsm_d = 1'd0;
					endcase
				1'd1: begin
					if (multdiv_en_dec)
						rf_we_raw = rf_we_dec & ex_valid_i;
					if (multicycle_done & ready_wb_i)
						id_fsm_d = 1'd0;
					else begin
						stall_multdiv = multdiv_en_dec;
						stall_branch = branch_in_dec;
						stall_jump = jump_in_dec;
					end
				end
				default: id_fsm_d = 1'd0;
			endcase
	end
	assign multdiv_ready_id_o = ready_wb_i;
	assign stall_id = ((((stall_ld_hz | stall_mem) | stall_multdiv) | stall_jump) | stall_branch) | stall_alu;
	assign instr_done = (~stall_id & ~flush_id) & instr_executing;
	assign instr_first_cycle = instr_valid_i & (id_fsm_q == 1'd0);
	assign instr_first_cycle_id_o = instr_first_cycle;
	generate
		if (WritebackStage) begin : gen_stall_mem
			wire rf_rd_a_wb_match;
			wire rf_rd_b_wb_match;
			wire rf_rd_a_hz;
			wire rf_rd_b_hz;
			wire outstanding_memory_access;
			wire instr_kill;
			assign multicycle_done = (lsu_req_dec ? ~stall_mem : ex_valid_i);
			assign outstanding_memory_access = (outstanding_load_wb_i | outstanding_store_wb_i) & ~lsu_resp_valid_i;
			assign data_req_allowed = ~outstanding_memory_access;
			assign instr_kill = ((instr_fetch_err_i | wb_exception) | id_exception) | ~controller_run;
			assign instr_executing_spec = ((instr_valid_i & ~instr_fetch_err_i) & controller_run) & ~stall_ld_hz;
			assign instr_executing = ((instr_valid_i & ~instr_kill) & ~stall_ld_hz) & ~outstanding_memory_access;
			assign stall_mem = instr_valid_i & (outstanding_memory_access | (lsu_req_dec & ~lsu_req_done_i));
			assign rf_rd_a_wb_match = (rf_waddr_wb_i == rf_raddr_a_o) & |rf_raddr_a_o;
			assign rf_rd_b_wb_match = (rf_waddr_wb_i == rf_raddr_b_o) & |rf_raddr_b_o;
			assign rf_rd_a_wb_match_o = rf_rd_a_wb_match;
			assign rf_rd_b_wb_match_o = rf_rd_b_wb_match;
			assign rf_rd_a_hz = rf_rd_a_wb_match & rf_ren_a;
			assign rf_rd_b_hz = rf_rd_b_wb_match & rf_ren_b;
			assign rf_rdata_a_fwd = (rf_rd_a_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_a_i);
			assign rf_rdata_b_fwd = (rf_rd_b_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_b_i);
			assign stall_ld_hz = outstanding_load_wb_i & (rf_rd_a_hz | rf_rd_b_hz);
			assign instr_type_wb_o = (~lsu_req_dec ? 2'd2 : (lsu_we ? 2'd1 : 2'd0));
			assign instr_id_done_o = en_wb_o & ready_wb_i;
			assign stall_wb = en_wb_o & ~ready_wb_i;
			assign perf_dside_wait_o = (instr_valid_i & ~instr_kill) & (outstanding_memory_access | stall_ld_hz);
			assign expecting_load_resp_o = 1'b0;
			assign expecting_store_resp_o = 1'b0;
		end
		else begin : gen_no_stall_mem
			assign multicycle_done = (lsu_req_dec ? lsu_resp_valid_i : ex_valid_i);
			assign data_req_allowed = instr_first_cycle;
			assign stall_mem = instr_valid_i & (lsu_req_dec & (~lsu_resp_valid_i | instr_first_cycle));
			assign stall_ld_hz = 1'b0;
			assign instr_executing_spec = (instr_valid_i & ~instr_fetch_err_i) & controller_run;
			assign instr_executing = instr_executing_spec;
			assign rf_rdata_a_fwd = rf_rdata_a_i;
			assign rf_rdata_b_fwd = rf_rdata_b_i;
			assign rf_rd_a_wb_match_o = 1'b0;
			assign rf_rd_b_wb_match_o = 1'b0;
			assign expecting_load_resp_o = ((instr_valid_i & lsu_req_dec) & ~instr_first_cycle) & ~lsu_we;
			assign expecting_store_resp_o = ((instr_valid_i & lsu_req_dec) & ~instr_first_cycle) & lsu_we;
			wire unused_data_req_done_ex;
			wire [4:0] unused_rf_waddr_wb;
			wire unused_rf_write_wb;
			wire unused_outstanding_load_wb;
			wire unused_outstanding_store_wb;
			wire unused_wb_exception;
			wire [31:0] unused_rf_wdata_fwd_wb;
			wire unused_id_exception;
			assign unused_data_req_done_ex = lsu_req_done_i;
			assign unused_rf_waddr_wb = rf_waddr_wb_i;
			assign unused_rf_write_wb = rf_write_wb_i;
			assign unused_outstanding_load_wb = outstanding_load_wb_i;
			assign unused_outstanding_store_wb = outstanding_store_wb_i;
			assign unused_wb_exception = wb_exception;
			assign unused_rf_wdata_fwd_wb = rf_wdata_fwd_wb_i;
			assign unused_id_exception = id_exception;
			assign instr_type_wb_o = 2'd2;
			assign stall_wb = 1'b0;
			assign perf_dside_wait_o = (instr_executing & lsu_req_dec) & ~lsu_resp_valid_i;
			assign instr_id_done_o = instr_done;
		end
	endgenerate
	assign instr_perf_count_id_o = (((~ebrk_insn & ~ecall_insn_dec) & ~illegal_insn_dec) & ~illegal_csr_insn_i) & ~instr_fetch_err_i;
	assign en_wb_o = instr_done;
	assign perf_mul_wait_o = stall_multdiv & mult_en_dec;
	assign perf_div_wait_o = stall_multdiv & div_en_dec;
	initial _sv2v_0 = 0;
endmodule
module ibex_if_stage (
	clk_i,
	rst_ni,
	boot_addr_i,
	req_i,
	instr_req_o,
	instr_addr_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_bus_err_i,
	instr_intg_err_o,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	instr_valid_id_o,
	instr_new_id_o,
	instr_rdata_id_o,
	instr_rdata_alu_id_o,
	instr_rdata_c_id_o,
	instr_is_compressed_id_o,
	instr_bp_taken_o,
	instr_fetch_err_o,
	instr_fetch_err_plus2_o,
	illegal_c_insn_id_o,
	dummy_instr_id_o,
	pc_if_o,
	pc_id_o,
	pmp_err_if_i,
	pmp_err_if_plus2_i,
	instr_valid_clear_i,
	pc_set_i,
	pc_mux_i,
	nt_branch_mispredict_i,
	nt_branch_addr_i,
	exc_pc_mux_i,
	exc_cause,
	dummy_instr_en_i,
	dummy_instr_mask_i,
	dummy_instr_seed_en_i,
	dummy_instr_seed_i,
	icache_enable_i,
	icache_inval_i,
	icache_ecc_error_o,
	branch_target_ex_i,
	csr_mepc_i,
	csr_depc_i,
	csr_mtvec_i,
	csr_mtvec_init_o,
	id_in_ready_i,
	pc_mismatch_alert_o,
	if_busy_o
);
	reg _sv2v_0;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] PCIncrCheck = 1'b0;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] boot_addr_i;
	input wire req_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_bus_err_i;
	output wire instr_intg_err_o;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output wire ic_scr_key_req_o;
	output wire instr_valid_id_o;
	output wire instr_new_id_o;
	output reg [31:0] instr_rdata_id_o;
	output reg [31:0] instr_rdata_alu_id_o;
	output reg [15:0] instr_rdata_c_id_o;
	output reg instr_is_compressed_id_o;
	output wire instr_bp_taken_o;
	output reg instr_fetch_err_o;
	output reg instr_fetch_err_plus2_o;
	output reg illegal_c_insn_id_o;
	output reg dummy_instr_id_o;
	output wire [31:0] pc_if_o;
	output reg [31:0] pc_id_o;
	input wire pmp_err_if_i;
	input wire pmp_err_if_plus2_i;
	input wire instr_valid_clear_i;
	input wire pc_set_i;
	input wire [2:0] pc_mux_i;
	input wire nt_branch_mispredict_i;
	input wire [31:0] nt_branch_addr_i;
	input wire [1:0] exc_pc_mux_i;
	input wire [6:0] exc_cause;
	input wire dummy_instr_en_i;
	input wire [2:0] dummy_instr_mask_i;
	input wire dummy_instr_seed_en_i;
	input wire [31:0] dummy_instr_seed_i;
	input wire icache_enable_i;
	input wire icache_inval_i;
	output wire icache_ecc_error_o;
	input wire [31:0] branch_target_ex_i;
	input wire [31:0] csr_mepc_i;
	input wire [31:0] csr_depc_i;
	input wire [31:0] csr_mtvec_i;
	output wire csr_mtvec_init_o;
	input wire id_in_ready_i;
	output wire pc_mismatch_alert_o;
	output wire if_busy_o;
	wire instr_valid_id_d;
	reg instr_valid_id_q;
	wire instr_new_id_d;
	reg instr_new_id_q;
	wire instr_err;
	wire instr_intg_err;
	wire prefetch_busy;
	wire branch_req;
	reg [31:0] fetch_addr_n;
	wire unused_fetch_addr_n0;
	wire prefetch_branch;
	wire [31:0] prefetch_addr;
	wire fetch_valid_raw;
	wire fetch_valid;
	wire fetch_ready;
	wire [31:0] fetch_rdata;
	wire [31:0] fetch_addr;
	wire fetch_err;
	wire fetch_err_plus2;
	wire [31:0] instr_decompressed;
	wire illegal_c_insn;
	wire instr_is_compressed;
	wire if_instr_valid;
	wire [31:0] if_instr_rdata;
	wire [31:0] if_instr_addr;
	wire if_instr_bus_err;
	wire if_instr_pmp_err;
	wire if_instr_err;
	wire if_instr_err_plus2;
	reg [31:0] exc_pc;
	wire if_id_pipe_reg_we;
	wire stall_dummy_instr;
	wire [31:0] instr_out;
	wire instr_is_compressed_out;
	wire illegal_c_instr_out;
	wire instr_err_out;
	wire predict_branch_taken;
	wire [31:0] predict_branch_pc;
	reg [4:0] irq_vec;
	wire [2:0] pc_mux_internal;
	wire [7:0] unused_boot_addr;
	wire [7:0] unused_csr_mtvec;
	wire unused_exc_cause;
	assign unused_boot_addr = boot_addr_i[7:0];
	assign unused_csr_mtvec = csr_mtvec_i[7:0];
	assign unused_exc_cause = |{exc_cause[5], exc_cause[6]};
	localparam [6:0] ibex_pkg_ExcCauseIrqNm = 7'h3f;
	always @(*) begin : exc_pc_mux
		if (_sv2v_0)
			;
		irq_vec = exc_cause[4-:5];
		if (exc_cause[6])
			irq_vec = ibex_pkg_ExcCauseIrqNm[4-:5];
		(* full_case, parallel_case *)
		case (exc_pc_mux_i)
			2'd0: exc_pc = {csr_mtvec_i[31:8], 8'h00};
			2'd1: exc_pc = {csr_mtvec_i[31:8], 1'b0, irq_vec, 2'b00};
			2'd2: exc_pc = DmHaltAddr;
			2'd3: exc_pc = DmExceptionAddr;
			default: exc_pc = {csr_mtvec_i[31:8], 8'h00};
		endcase
	end
	assign pc_mux_internal = ((BranchPredictor && predict_branch_taken) && !pc_set_i ? 3'd5 : pc_mux_i);
	always @(*) begin : fetch_addr_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (pc_mux_internal)
			3'd0: fetch_addr_n = {boot_addr_i[31:8], 8'h80};
			3'd1: fetch_addr_n = branch_target_ex_i;
			3'd2: fetch_addr_n = exc_pc;
			3'd3: fetch_addr_n = csr_mepc_i;
			3'd4: fetch_addr_n = csr_depc_i;
			3'd5: fetch_addr_n = (BranchPredictor ? predict_branch_pc : {boot_addr_i[31:8], 8'h80});
			default: fetch_addr_n = {boot_addr_i[31:8], 8'h80};
		endcase
	end
	assign csr_mtvec_init_o = (pc_mux_i == 3'd0) & pc_set_i;
	generate
		if (MemECC) begin : g_mem_ecc
			wire [1:0] ecc_err;
			wire [MemDataWidth - 1:0] instr_rdata_buf;
			prim_buf #(.Width(MemDataWidth)) u_prim_buf_instr_rdata(
				.in_i(instr_rdata_i),
				.out_o(instr_rdata_buf)
			);
			prim_secded_inv_39_32_dec u_instr_intg_dec(
				.data_i(instr_rdata_buf),
				.data_o(),
				.syndrome_o(),
				.err_o(ecc_err)
			);
			assign instr_intg_err = |ecc_err;
		end
		else begin : g_no_mem_ecc
			assign instr_intg_err = 1'b0;
		end
	endgenerate
	assign instr_err = instr_intg_err | instr_bus_err_i;
	assign instr_intg_err_o = instr_intg_err & instr_rvalid_i;
	assign prefetch_branch = branch_req | nt_branch_mispredict_i;
	assign prefetch_addr = (branch_req ? {fetch_addr_n[31:1], 1'b0} : nt_branch_addr_i);
	assign fetch_valid = fetch_valid_raw & ~nt_branch_mispredict_i;
	generate
		if (ICache) begin : gen_icache
			ibex_icache #(
				.ICacheECC(ICacheECC),
				.ResetAll(ResetAll),
				.BusSizeECC(BusSizeECC),
				.TagSizeECC(TagSizeECC),
				.LineSizeECC(LineSizeECC)
			) icache_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req_i),
				.branch_i(prefetch_branch),
				.addr_i(prefetch_addr),
				.ready_i(fetch_ready),
				.valid_o(fetch_valid_raw),
				.rdata_o(fetch_rdata),
				.addr_o(fetch_addr),
				.err_o(fetch_err),
				.err_plus2_o(fetch_err_plus2),
				.instr_req_o(instr_req_o),
				.instr_addr_o(instr_addr_o),
				.instr_gnt_i(instr_gnt_i),
				.instr_rvalid_i(instr_rvalid_i),
				.instr_rdata_i(instr_rdata_i[31:0]),
				.instr_err_i(instr_err),
				.ic_tag_req_o(ic_tag_req_o),
				.ic_tag_write_o(ic_tag_write_o),
				.ic_tag_addr_o(ic_tag_addr_o),
				.ic_tag_wdata_o(ic_tag_wdata_o),
				.ic_tag_rdata_i(ic_tag_rdata_i),
				.ic_data_req_o(ic_data_req_o),
				.ic_data_write_o(ic_data_write_o),
				.ic_data_addr_o(ic_data_addr_o),
				.ic_data_wdata_o(ic_data_wdata_o),
				.ic_data_rdata_i(ic_data_rdata_i),
				.ic_scr_key_valid_i(ic_scr_key_valid_i),
				.ic_scr_key_req_o(ic_scr_key_req_o),
				.icache_enable_i(icache_enable_i),
				.icache_inval_i(icache_inval_i),
				.busy_o(prefetch_busy),
				.ecc_error_o(icache_ecc_error_o)
			);
		end
		else begin : gen_prefetch_buffer
			ibex_prefetch_buffer #(.ResetAll(ResetAll)) prefetch_buffer_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req_i),
				.branch_i(prefetch_branch),
				.addr_i(prefetch_addr),
				.ready_i(fetch_ready),
				.valid_o(fetch_valid_raw),
				.rdata_o(fetch_rdata),
				.addr_o(fetch_addr),
				.err_o(fetch_err),
				.err_plus2_o(fetch_err_plus2),
				.instr_req_o(instr_req_o),
				.instr_addr_o(instr_addr_o),
				.instr_gnt_i(instr_gnt_i),
				.instr_rvalid_i(instr_rvalid_i),
				.instr_rdata_i(instr_rdata_i[31:0]),
				.instr_err_i(instr_err),
				.busy_o(prefetch_busy)
			);
			wire unused_icen;
			wire unused_icinv;
			wire unused_scr_key_valid;
			wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] unused_tag_ram_input;
			wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] unused_data_ram_input;
			assign unused_icen = icache_enable_i;
			assign unused_icinv = icache_inval_i;
			assign unused_tag_ram_input = ic_tag_rdata_i;
			assign unused_data_ram_input = ic_data_rdata_i;
			assign unused_scr_key_valid = ic_scr_key_valid_i;
			assign ic_tag_req_o = 'b0;
			assign ic_tag_write_o = 'b0;
			assign ic_tag_addr_o = 'b0;
			assign ic_tag_wdata_o = 'b0;
			assign ic_data_req_o = 'b0;
			assign ic_data_write_o = 'b0;
			assign ic_data_addr_o = 'b0;
			assign ic_data_wdata_o = 'b0;
			assign ic_scr_key_req_o = 'b0;
			assign icache_ecc_error_o = 'b0;
		end
	endgenerate
	assign unused_fetch_addr_n0 = fetch_addr_n[0];
	assign branch_req = pc_set_i | predict_branch_taken;
	assign pc_if_o = if_instr_addr;
	assign if_busy_o = prefetch_busy;
	assign if_instr_pmp_err = pmp_err_if_i | ((if_instr_addr[1] & ~instr_is_compressed) & pmp_err_if_plus2_i);
	assign if_instr_err = if_instr_bus_err | if_instr_pmp_err;
	assign if_instr_err_plus2 = (((if_instr_addr[1] & ~instr_is_compressed) & pmp_err_if_plus2_i) | fetch_err_plus2) & ~pmp_err_if_i;
	ibex_compressed_decoder compressed_decoder_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.valid_i(fetch_valid & ~fetch_err),
		.instr_i(if_instr_rdata),
		.instr_o(instr_decompressed),
		.is_compressed_o(instr_is_compressed),
		.illegal_instr_o(illegal_c_insn)
	);
	generate
		if (DummyInstructions) begin : gen_dummy_instr
			wire insert_dummy_instr;
			wire [31:0] dummy_instr_data;
			ibex_dummy_instr #(
				.RndCnstLfsrSeed(RndCnstLfsrSeed),
				.RndCnstLfsrPerm(RndCnstLfsrPerm)
			) dummy_instr_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.dummy_instr_en_i(dummy_instr_en_i),
				.dummy_instr_mask_i(dummy_instr_mask_i),
				.dummy_instr_seed_en_i(dummy_instr_seed_en_i),
				.dummy_instr_seed_i(dummy_instr_seed_i),
				.fetch_valid_i(fetch_valid),
				.id_in_ready_i(id_in_ready_i),
				.insert_dummy_instr_o(insert_dummy_instr),
				.dummy_instr_data_o(dummy_instr_data)
			);
			assign instr_out = (insert_dummy_instr ? dummy_instr_data : instr_decompressed);
			assign instr_is_compressed_out = (insert_dummy_instr ? 1'b0 : instr_is_compressed);
			assign illegal_c_instr_out = (insert_dummy_instr ? 1'b0 : illegal_c_insn);
			assign instr_err_out = (insert_dummy_instr ? 1'b0 : if_instr_err);
			assign stall_dummy_instr = insert_dummy_instr;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					dummy_instr_id_o <= 1'b0;
				else if (if_id_pipe_reg_we)
					dummy_instr_id_o <= insert_dummy_instr;
		end
		else begin : gen_no_dummy_instr
			wire unused_dummy_en;
			wire [2:0] unused_dummy_mask;
			wire unused_dummy_seed_en;
			wire [31:0] unused_dummy_seed;
			assign unused_dummy_en = dummy_instr_en_i;
			assign unused_dummy_mask = dummy_instr_mask_i;
			assign unused_dummy_seed_en = dummy_instr_seed_en_i;
			assign unused_dummy_seed = dummy_instr_seed_i;
			assign instr_out = instr_decompressed;
			assign instr_is_compressed_out = instr_is_compressed;
			assign illegal_c_instr_out = illegal_c_insn;
			assign instr_err_out = if_instr_err;
			assign stall_dummy_instr = 1'b0;
			wire [1:1] sv2v_tmp_C8A0C;
			assign sv2v_tmp_C8A0C = 1'b0;
			always @(*) dummy_instr_id_o = sv2v_tmp_C8A0C;
		end
	endgenerate
	assign instr_valid_id_d = ((if_instr_valid & id_in_ready_i) & ~pc_set_i) | (instr_valid_id_q & ~instr_valid_clear_i);
	assign instr_new_id_d = if_instr_valid & id_in_ready_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			instr_valid_id_q <= 1'b0;
			instr_new_id_q <= 1'b0;
		end
		else begin
			instr_valid_id_q <= instr_valid_id_d;
			instr_new_id_q <= instr_new_id_d;
		end
	assign instr_valid_id_o = instr_valid_id_q;
	assign instr_new_id_o = instr_new_id_q;
	assign if_id_pipe_reg_we = instr_new_id_d;
	generate
		if (ResetAll) begin : g_instr_rdata_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					instr_rdata_id_o <= 1'sb0;
					instr_rdata_alu_id_o <= 1'sb0;
					instr_fetch_err_o <= 1'sb0;
					instr_fetch_err_plus2_o <= 1'sb0;
					instr_rdata_c_id_o <= 1'sb0;
					instr_is_compressed_id_o <= 1'sb0;
					illegal_c_insn_id_o <= 1'sb0;
					pc_id_o <= 1'sb0;
				end
				else if (if_id_pipe_reg_we) begin
					instr_rdata_id_o <= instr_out;
					instr_rdata_alu_id_o <= instr_out;
					instr_fetch_err_o <= instr_err_out;
					instr_fetch_err_plus2_o <= if_instr_err_plus2;
					instr_rdata_c_id_o <= if_instr_rdata[15:0];
					instr_is_compressed_id_o <= instr_is_compressed_out;
					illegal_c_insn_id_o <= illegal_c_instr_out;
					pc_id_o <= pc_if_o;
				end
		end
		else begin : g_instr_rdata_nr
			always @(posedge clk_i)
				if (if_id_pipe_reg_we) begin
					instr_rdata_id_o <= instr_out;
					instr_rdata_alu_id_o <= instr_out;
					instr_fetch_err_o <= instr_err_out;
					instr_fetch_err_plus2_o <= if_instr_err_plus2;
					instr_rdata_c_id_o <= if_instr_rdata[15:0];
					instr_is_compressed_id_o <= instr_is_compressed_out;
					illegal_c_insn_id_o <= illegal_c_instr_out;
					pc_id_o <= pc_if_o;
				end
		end
		if (PCIncrCheck) begin : g_secure_pc
			wire [31:0] prev_instr_addr_incr;
			wire [31:0] prev_instr_addr_incr_buf;
			reg prev_instr_seq_q;
			wire prev_instr_seq_d;
			assign prev_instr_seq_d = (((prev_instr_seq_q | instr_new_id_d) & ~branch_req) & ~if_instr_err) & ~stall_dummy_instr;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					prev_instr_seq_q <= 1'b0;
				else
					prev_instr_seq_q <= prev_instr_seq_d;
			assign prev_instr_addr_incr = pc_id_o + (instr_is_compressed_id_o ? 32'd2 : 32'd4);
			prim_buf #(.Width(32)) u_prev_instr_addr_incr_buf(
				.in_i(prev_instr_addr_incr),
				.out_o(prev_instr_addr_incr_buf)
			);
			assign pc_mismatch_alert_o = prev_instr_seq_q & (pc_if_o != prev_instr_addr_incr_buf);
		end
		else begin : g_no_secure_pc
			assign pc_mismatch_alert_o = 1'b0;
		end
		if (BranchPredictor) begin : g_branch_predictor
			reg [31:0] instr_skid_data_q;
			reg [31:0] instr_skid_addr_q;
			reg instr_skid_bp_taken_q;
			reg instr_skid_valid_q;
			wire instr_skid_valid_d;
			wire instr_skid_en;
			reg instr_bp_taken_q;
			wire instr_bp_taken_d;
			wire predict_branch_taken_raw;
			if (ResetAll) begin : g_bp_taken_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						instr_bp_taken_q <= 1'sb0;
					else if (if_id_pipe_reg_we)
						instr_bp_taken_q <= instr_bp_taken_d;
			end
			else begin : g_bp_taken_nr
				always @(posedge clk_i)
					if (if_id_pipe_reg_we)
						instr_bp_taken_q <= instr_bp_taken_d;
			end
			assign instr_skid_en = ((predict_branch_taken & ~pc_set_i) & ~id_in_ready_i) & ~instr_skid_valid_q;
			assign instr_skid_valid_d = ((instr_skid_valid_q & ~id_in_ready_i) & ~stall_dummy_instr) | instr_skid_en;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					instr_skid_valid_q <= 1'b0;
				else
					instr_skid_valid_q <= instr_skid_valid_d;
			if (ResetAll) begin : g_instr_skid_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						instr_skid_bp_taken_q <= 1'sb0;
						instr_skid_data_q <= 1'sb0;
						instr_skid_addr_q <= 1'sb0;
					end
					else if (instr_skid_en) begin
						instr_skid_bp_taken_q <= predict_branch_taken;
						instr_skid_data_q <= fetch_rdata;
						instr_skid_addr_q <= fetch_addr;
					end
			end
			else begin : g_instr_skid_nr
				always @(posedge clk_i)
					if (instr_skid_en) begin
						instr_skid_bp_taken_q <= predict_branch_taken;
						instr_skid_data_q <= fetch_rdata;
						instr_skid_addr_q <= fetch_addr;
					end
			end
			ibex_branch_predict branch_predict_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.fetch_rdata_i(fetch_rdata),
				.fetch_pc_i(fetch_addr),
				.fetch_valid_i(fetch_valid),
				.predict_branch_taken_o(predict_branch_taken_raw),
				.predict_branch_pc_o(predict_branch_pc)
			);
			assign predict_branch_taken = (predict_branch_taken_raw & ~instr_skid_valid_q) & ~fetch_err;
			assign if_instr_valid = fetch_valid | (instr_skid_valid_q & ~nt_branch_mispredict_i);
			assign if_instr_rdata = (instr_skid_valid_q ? instr_skid_data_q : fetch_rdata);
			assign if_instr_addr = (instr_skid_valid_q ? instr_skid_addr_q : fetch_addr);
			assign if_instr_bus_err = ~instr_skid_valid_q & fetch_err;
			assign instr_bp_taken_d = (instr_skid_valid_q ? instr_skid_bp_taken_q : predict_branch_taken);
			assign fetch_ready = (id_in_ready_i & ~stall_dummy_instr) & ~instr_skid_valid_q;
			assign instr_bp_taken_o = instr_bp_taken_q;
		end
		else begin : g_no_branch_predictor
			assign instr_bp_taken_o = 1'b0;
			assign predict_branch_taken = 1'b0;
			assign predict_branch_pc = 32'b00000000000000000000000000000000;
			assign if_instr_valid = fetch_valid;
			assign if_instr_rdata = fetch_rdata;
			assign if_instr_addr = fetch_addr;
			assign if_instr_bus_err = fetch_err;
			assign fetch_ready = id_in_ready_i & ~stall_dummy_instr;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_load_store_unit (
	clk_i,
	rst_ni,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_bus_err_i,
	data_pmp_err_i,
	data_addr_o,
	data_we_o,
	data_be_o,
	data_wdata_o,
	data_rdata_i,
	lsu_we_i,
	lsu_type_i,
	lsu_wdata_i,
	lsu_sign_ext_i,
	lsu_rdata_o,
	lsu_rdata_valid_o,
	lsu_req_i,
	adder_result_ex_i,
	addr_incr_req_o,
	addr_last_o,
	lsu_req_done_o,
	lsu_resp_valid_o,
	load_err_o,
	load_resp_intg_err_o,
	store_err_o,
	store_resp_intg_err_o,
	busy_o,
	perf_load_o,
	perf_store_o
);
	reg _sv2v_0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	input wire clk_i;
	input wire rst_ni;
	output reg data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_bus_err_i;
	input wire data_pmp_err_i;
	output wire [31:0] data_addr_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire lsu_we_i;
	input wire [1:0] lsu_type_i;
	input wire [31:0] lsu_wdata_i;
	input wire lsu_sign_ext_i;
	output wire [31:0] lsu_rdata_o;
	output wire lsu_rdata_valid_o;
	input wire lsu_req_i;
	input wire [31:0] adder_result_ex_i;
	output reg addr_incr_req_o;
	output wire [31:0] addr_last_o;
	output wire lsu_req_done_o;
	output wire lsu_resp_valid_o;
	output wire load_err_o;
	output wire load_resp_intg_err_o;
	output wire store_err_o;
	output wire store_resp_intg_err_o;
	output wire busy_o;
	output reg perf_load_o;
	output reg perf_store_o;
	wire [31:0] data_addr;
	wire [31:0] data_addr_w_aligned;
	reg [31:0] addr_last_q;
	wire [31:0] addr_last_d;
	reg addr_update;
	reg ctrl_update;
	reg rdata_update;
	reg [31:8] rdata_q;
	reg [1:0] rdata_offset_q;
	reg [1:0] data_type_q;
	reg data_sign_ext_q;
	reg data_we_q;
	wire [1:0] data_offset;
	reg [3:0] data_be;
	reg [31:0] data_wdata;
	reg [31:0] data_rdata_ext;
	reg [31:0] rdata_w_ext;
	reg [31:0] rdata_h_ext;
	reg [31:0] rdata_b_ext;
	wire split_misaligned_access;
	reg handle_misaligned_q;
	reg handle_misaligned_d;
	reg pmp_err_q;
	reg pmp_err_d;
	reg lsu_err_q;
	reg lsu_err_d;
	wire data_intg_err;
	wire data_or_pmp_err;
	reg [2:0] ls_fsm_cs;
	reg [2:0] ls_fsm_ns;
	assign data_addr = adder_result_ex_i;
	assign data_offset = data_addr[1:0];
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (lsu_type_i)
			2'b00:
				if (!handle_misaligned_q)
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b1111;
						2'b01: data_be = 4'b1110;
						2'b10: data_be = 4'b1100;
						2'b11: data_be = 4'b1000;
						default: data_be = 4'b1111;
					endcase
				else
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b0000;
						2'b01: data_be = 4'b0001;
						2'b10: data_be = 4'b0011;
						2'b11: data_be = 4'b0111;
						default: data_be = 4'b1111;
					endcase
			2'b01:
				if (!handle_misaligned_q)
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b0011;
						2'b01: data_be = 4'b0110;
						2'b10: data_be = 4'b1100;
						2'b11: data_be = 4'b1000;
						default: data_be = 4'b1111;
					endcase
				else
					data_be = 4'b0001;
			2'b10, 2'b11:
				(* full_case, parallel_case *)
				case (data_offset)
					2'b00: data_be = 4'b0001;
					2'b01: data_be = 4'b0010;
					2'b10: data_be = 4'b0100;
					2'b11: data_be = 4'b1000;
					default: data_be = 4'b1111;
				endcase
			default: data_be = 4'b1111;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_offset)
			2'b00: data_wdata = lsu_wdata_i[31:0];
			2'b01: data_wdata = {lsu_wdata_i[23:0], lsu_wdata_i[31:24]};
			2'b10: data_wdata = {lsu_wdata_i[15:0], lsu_wdata_i[31:16]};
			2'b11: data_wdata = {lsu_wdata_i[7:0], lsu_wdata_i[31:8]};
			default: data_wdata = lsu_wdata_i[31:0];
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rdata_q <= 1'sb0;
		else if (rdata_update)
			rdata_q <= data_rdata_i[31:8];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			rdata_offset_q <= 2'h0;
			data_type_q <= 2'h0;
			data_sign_ext_q <= 1'b0;
			data_we_q <= 1'b0;
		end
		else if (ctrl_update) begin
			rdata_offset_q <= data_offset;
			data_type_q <= lsu_type_i;
			data_sign_ext_q <= lsu_sign_ext_i;
			data_we_q <= lsu_we_i;
		end
	assign addr_last_d = (addr_incr_req_o ? data_addr_w_aligned : data_addr);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			addr_last_q <= 1'sb0;
		else if (addr_update)
			addr_last_q <= addr_last_d;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00: rdata_w_ext = data_rdata_i[31:0];
			2'b01: rdata_w_ext = {data_rdata_i[7:0], rdata_q[31:8]};
			2'b10: rdata_w_ext = {data_rdata_i[15:0], rdata_q[31:16]};
			2'b11: rdata_w_ext = {data_rdata_i[23:0], rdata_q[31:24]};
			default: rdata_w_ext = data_rdata_i[31:0];
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
				else
					rdata_h_ext = {{16 {data_rdata_i[15]}}, data_rdata_i[15:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[23:8]};
				else
					rdata_h_ext = {{16 {data_rdata_i[23]}}, data_rdata_i[23:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[31:16]};
				else
					rdata_h_ext = {{16 {data_rdata_i[31]}}, data_rdata_i[31:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[7:0], rdata_q[31:24]};
				else
					rdata_h_ext = {{16 {data_rdata_i[7]}}, data_rdata_i[7:0], rdata_q[31:24]};
			default: rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
				else
					rdata_b_ext = {{24 {data_rdata_i[7]}}, data_rdata_i[7:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[15:8]};
				else
					rdata_b_ext = {{24 {data_rdata_i[15]}}, data_rdata_i[15:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[23:16]};
				else
					rdata_b_ext = {{24 {data_rdata_i[23]}}, data_rdata_i[23:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[31:24]};
				else
					rdata_b_ext = {{24 {data_rdata_i[31]}}, data_rdata_i[31:24]};
			default: rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_type_q)
			2'b00: data_rdata_ext = rdata_w_ext;
			2'b01: data_rdata_ext = rdata_h_ext;
			2'b10, 2'b11: data_rdata_ext = rdata_b_ext;
			default: data_rdata_ext = rdata_w_ext;
		endcase
	end
	generate
		if (MemECC) begin : g_mem_rdata_ecc
			wire [1:0] ecc_err;
			wire [MemDataWidth - 1:0] data_rdata_buf;
			prim_buf #(.Width(MemDataWidth)) u_prim_buf_instr_rdata(
				.in_i(data_rdata_i),
				.out_o(data_rdata_buf)
			);
			prim_secded_inv_39_32_dec u_data_intg_dec(
				.data_i(data_rdata_buf),
				.data_o(),
				.syndrome_o(),
				.err_o(ecc_err)
			);
			assign data_intg_err = |ecc_err;
		end
		else begin : g_no_mem_data_ecc
			assign data_intg_err = 1'b0;
		end
	endgenerate
	assign split_misaligned_access = ((lsu_type_i == 2'b00) && (data_offset != 2'b00)) || ((lsu_type_i == 2'b01) && (data_offset == 2'b11));
	always @(*) begin
		if (_sv2v_0)
			;
		ls_fsm_ns = ls_fsm_cs;
		data_req_o = 1'b0;
		addr_incr_req_o = 1'b0;
		handle_misaligned_d = handle_misaligned_q;
		pmp_err_d = pmp_err_q;
		lsu_err_d = lsu_err_q;
		addr_update = 1'b0;
		ctrl_update = 1'b0;
		rdata_update = 1'b0;
		perf_load_o = 1'b0;
		perf_store_o = 1'b0;
		(* full_case, parallel_case *)
		case (ls_fsm_cs)
			3'd0: begin
				pmp_err_d = 1'b0;
				if (lsu_req_i) begin
					data_req_o = 1'b1;
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = 1'b0;
					perf_load_o = ~lsu_we_i;
					perf_store_o = lsu_we_i;
					if (data_gnt_i) begin
						ctrl_update = 1'b1;
						addr_update = 1'b1;
						handle_misaligned_d = split_misaligned_access;
						ls_fsm_ns = (split_misaligned_access ? 3'd2 : 3'd0);
					end
					else
						ls_fsm_ns = (split_misaligned_access ? 3'd1 : 3'd3);
				end
			end
			3'd1: begin
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					addr_update = 1'b1;
					ctrl_update = 1'b1;
					handle_misaligned_d = 1'b1;
					ls_fsm_ns = 3'd2;
				end
			end
			3'd2: begin
				data_req_o = 1'b1;
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i || pmp_err_q) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i | pmp_err_q;
					rdata_update = ~data_we_q;
					ls_fsm_ns = (data_gnt_i ? 3'd0 : 3'd3);
					addr_update = data_gnt_i & ~(data_bus_err_i | pmp_err_q);
					handle_misaligned_d = ~data_gnt_i;
				end
				else if (data_gnt_i) begin
					ls_fsm_ns = 3'd4;
					handle_misaligned_d = 1'b0;
				end
			end
			3'd3: begin
				addr_incr_req_o = handle_misaligned_q;
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					ctrl_update = 1'b1;
					addr_update = ~lsu_err_q;
					ls_fsm_ns = 3'd0;
					handle_misaligned_d = 1'b0;
				end
			end
			3'd4: begin
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i;
					addr_update = ~data_bus_err_i;
					rdata_update = ~data_we_q;
					ls_fsm_ns = 3'd0;
				end
			end
			default: ls_fsm_ns = 3'd0;
		endcase
	end
	assign lsu_req_done_o = (lsu_req_i | (ls_fsm_cs != 3'd0)) & (ls_fsm_ns == 3'd0);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ls_fsm_cs <= 3'd0;
			handle_misaligned_q <= 1'sb0;
			pmp_err_q <= 1'sb0;
			lsu_err_q <= 1'sb0;
		end
		else begin
			ls_fsm_cs <= ls_fsm_ns;
			handle_misaligned_q <= handle_misaligned_d;
			pmp_err_q <= pmp_err_d;
			lsu_err_q <= lsu_err_d;
		end
	assign data_or_pmp_err = (lsu_err_q | data_bus_err_i) | pmp_err_q;
	assign lsu_resp_valid_o = (data_rvalid_i | pmp_err_q) & (ls_fsm_cs == 3'd0);
	assign lsu_rdata_valid_o = ((((ls_fsm_cs == 3'd0) & data_rvalid_i) & ~data_or_pmp_err) & ~data_we_q) & ~data_intg_err;
	assign lsu_rdata_o = data_rdata_ext;
	assign data_addr_w_aligned = {data_addr[31:2], 2'b00};
	assign data_addr_o = data_addr_w_aligned;
	assign data_we_o = lsu_we_i;
	assign data_be_o = data_be;
	generate
		if (MemECC) begin : g_mem_wdata_ecc
			prim_secded_inv_39_32_enc u_data_gen(
				.data_i(data_wdata),
				.data_o(data_wdata_o)
			);
		end
		else begin : g_no_mem_wdata_ecc
			assign data_wdata_o = data_wdata;
		end
	endgenerate
	assign addr_last_o = addr_last_q;
	assign load_err_o = (data_or_pmp_err & ~data_we_q) & lsu_resp_valid_o;
	assign store_err_o = (data_or_pmp_err & data_we_q) & lsu_resp_valid_o;
	assign load_resp_intg_err_o = (data_intg_err & data_rvalid_i) & ~data_we_q;
	assign store_resp_intg_err_o = (data_intg_err & data_rvalid_i) & data_we_q;
	assign busy_o = ls_fsm_cs != 3'd0;
	initial _sv2v_0 = 0;
endmodule
module ibex_lockstep (
	clk_i,
	rst_ni,
	hart_id_i,
	boot_addr_i,
	instr_req_i,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_i,
	instr_rdata_i,
	instr_err_i,
	data_req_i,
	data_gnt_i,
	data_rvalid_i,
	data_we_i,
	data_be_i,
	data_addr_i,
	data_wdata_i,
	data_rdata_i,
	data_err_i,
	dummy_instr_id_i,
	dummy_instr_wb_i,
	rf_raddr_a_i,
	rf_raddr_b_i,
	rf_waddr_wb_i,
	rf_we_wb_i,
	rf_wdata_wb_ecc_i,
	rf_rdata_a_ecc_i,
	rf_rdata_b_ecc_i,
	ic_tag_req_i,
	ic_tag_write_i,
	ic_tag_addr_i,
	ic_tag_wdata_i,
	ic_tag_rdata_i,
	ic_data_req_i,
	ic_data_write_i,
	ic_data_addr_i,
	ic_data_wdata_i,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	irq_pending_i,
	debug_req_i,
	crash_dump_i,
	double_fault_seen_i,
	fetch_enable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_busy_i,
	test_en_i,
	scan_rst_ni
);
	parameter [31:0] LockstepOffset = 2;
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] RegFileECC = 1'b0;
	parameter [31:0] RegFileDataWidth = 32;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	input wire instr_req_i;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [31:0] instr_addr_i;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_err_i;
	input wire data_req_i;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_we_i;
	input wire [3:0] data_be_i;
	input wire [31:0] data_addr_i;
	input wire [MemDataWidth - 1:0] data_wdata_i;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_err_i;
	input wire dummy_instr_id_i;
	input wire dummy_instr_wb_i;
	input wire [4:0] rf_raddr_a_i;
	input wire [4:0] rf_raddr_b_i;
	input wire [4:0] rf_waddr_wb_i;
	input wire rf_we_wb_i;
	input wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_i;
	input wire [1:0] ic_tag_req_i;
	input wire ic_tag_write_i;
	input wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_i;
	input wire [TagSizeECC - 1:0] ic_tag_wdata_i;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	input wire [1:0] ic_data_req_i;
	input wire ic_data_write_i;
	input wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_i;
	input wire [LineSizeECC - 1:0] ic_data_wdata_i;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	input wire ic_scr_key_req_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	input wire irq_pending_i;
	input wire debug_req_i;
	input wire [159:0] crash_dump_i;
	input wire double_fault_seen_i;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] fetch_enable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	input wire [3:0] core_busy_i;
	input wire test_en_i;
	input wire scan_rst_ni;
	localparam [31:0] LockstepOffsetW = $clog2(LockstepOffset);
	localparam [31:0] OutputsOffset = LockstepOffset + 1;
	wire [LockstepOffsetW - 1:0] rst_shadow_cnt;
	wire rst_shadow_cnt_err;
	wire [3:0] rst_shadow_set_d;
	wire [3:0] rst_shadow_set_q;
	wire rst_shadow_n;
	wire rst_shadow_set_single_bit;
	wire [3:0] enable_cmp_d;
	wire [3:0] enable_cmp_q;
	function automatic [LockstepOffsetW - 1:0] sv2v_cast_5A7C9;
		input reg [LockstepOffsetW - 1:0] inp;
		sv2v_cast_5A7C9 = inp;
	endfunction
	prim_count #(
		.Width(LockstepOffsetW),
		.ResetValue(sv2v_cast_5A7C9(1'b0))
	) u_rst_shadow_cnt(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.set_i(1'b0),
		.set_cnt_i(1'sb0),
		.incr_en_i(1'b1),
		.decr_en_i(1'b0),
		.step_i(sv2v_cast_5A7C9(1'b1)),
		.commit_i(1'b1),
		.cnt_o(rst_shadow_cnt),
		.cnt_after_commit_o(),
		.err_o(rst_shadow_cnt_err)
	);
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign rst_shadow_set_d = (rst_shadow_cnt >= sv2v_cast_5A7C9(LockstepOffset - 1) ? ibex_pkg_IbexMuBiOn : ibex_pkg_IbexMuBiOff);
	assign enable_cmp_d = rst_shadow_set_q;
	assign rst_shadow_set_single_bit = rst_shadow_set_q[0];
	prim_flop #(
		.Width(ibex_pkg_IbexMuBiWidth),
		.ResetValue(ibex_pkg_IbexMuBiOff)
	) u_prim_rst_shadow_set_flop(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d_i(rst_shadow_set_d),
		.q_o(rst_shadow_set_q)
	);
	prim_flop #(
		.Width(ibex_pkg_IbexMuBiWidth),
		.ResetValue(ibex_pkg_IbexMuBiOff)
	) u_prim_enable_cmp_flop(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d_i(enable_cmp_d),
		.q_o(enable_cmp_q)
	);
	prim_clock_mux2 #(.NoFpgaBufG(1'b1)) u_prim_rst_shadow_n_mux2(
		.clk0_i(rst_shadow_set_single_bit),
		.clk1_i(scan_rst_ni),
		.sel_i(test_en_i),
		.clk_o(rst_shadow_n)
	);
	reg [((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? (LockstepOffset * (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1)) - 1 : (LockstepOffset * (1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0))) + (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 1)):((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)] shadow_inputs_q;
	wire [((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0:0] shadow_inputs_in;
	reg [(LockstepOffset * TagSizeECC) - 1:0] shadow_tag_rdata_q [0:1];
	reg [(LockstepOffset * LineSizeECC) - 1:0] shadow_data_rdata_q [0:1];
	assign shadow_inputs_in[2 + (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))] = instr_gnt_i;
	assign shadow_inputs_in[1 + (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))] = instr_rvalid_i;
	assign shadow_inputs_in[MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))-:((MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) >= (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25))))) ? ((MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) - (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25)))))) + 1 : ((3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25))))) - (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))) + 1)] = instr_rdata_i;
	assign shadow_inputs_in[3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))] = instr_err_i;
	assign shadow_inputs_in[2 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))] = data_gnt_i;
	assign shadow_inputs_in[1 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))] = data_rvalid_i;
	assign shadow_inputs_in[MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))-:((MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) >= (1 + (RegFileDataWidth + (RegFileDataWidth + 25))) ? ((MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) - (1 + (RegFileDataWidth + (RegFileDataWidth + 25)))) + 1 : ((1 + (RegFileDataWidth + (RegFileDataWidth + 25))) - (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))) + 1)] = data_rdata_i;
	assign shadow_inputs_in[1 + (RegFileDataWidth + (RegFileDataWidth + 24))] = data_err_i;
	assign shadow_inputs_in[RegFileDataWidth + (RegFileDataWidth + 24)-:((RegFileDataWidth + (RegFileDataWidth + 24)) >= (RegFileDataWidth + 25) ? ((RegFileDataWidth + (RegFileDataWidth + 24)) - (RegFileDataWidth + 25)) + 1 : ((RegFileDataWidth + 25) - (RegFileDataWidth + (RegFileDataWidth + 24))) + 1)] = rf_rdata_a_ecc_i;
	assign shadow_inputs_in[RegFileDataWidth + 24-:((RegFileDataWidth + 24) >= 25 ? RegFileDataWidth : 26 - (RegFileDataWidth + 24))] = rf_rdata_b_ecc_i;
	assign shadow_inputs_in[24] = irq_software_i;
	assign shadow_inputs_in[23] = irq_timer_i;
	assign shadow_inputs_in[22] = irq_external_i;
	assign shadow_inputs_in[21-:15] = irq_fast_i;
	assign shadow_inputs_in[6] = irq_nm_i;
	assign shadow_inputs_in[5] = debug_req_i;
	assign shadow_inputs_in[4-:4] = fetch_enable_i;
	assign shadow_inputs_in[0] = ic_scr_key_valid_i;
	function automatic [((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)) - 1:0] sv2v_cast_F4D25;
		input reg [((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)) - 1:0] inp;
		sv2v_cast_F4D25 = inp;
	endfunction
	function automatic [TagSizeECC - 1:0] sv2v_cast_0CBAD;
		input reg [TagSizeECC - 1:0] inp;
		sv2v_cast_0CBAD = inp;
	endfunction
	function automatic [LineSizeECC - 1:0] sv2v_cast_033B0;
		input reg [LineSizeECC - 1:0] inp;
		sv2v_cast_033B0 = inp;
	endfunction
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < LockstepOffset; i = i + 1)
				begin
					shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) + (i * ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)))+:((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0))] <= sv2v_cast_F4D25(1'sb0);
					shadow_tag_rdata_q[i] <= {LockstepOffset {sv2v_cast_0CBAD(0)}};
					shadow_data_rdata_q[i] <= {LockstepOffset {sv2v_cast_033B0(0)}};
				end
		end
		else begin
			begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < (LockstepOffset - 1); i = i + 1)
					begin
						shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) + (i * ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)))+:((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0))] <= shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) + ((i + 1) * ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)))+:((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0))];
						shadow_tag_rdata_q[i] <= shadow_tag_rdata_q[i + 1];
						shadow_data_rdata_q[i] <= shadow_data_rdata_q[i + 1];
					end
			end
			shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) + ((LockstepOffset - 1) * ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)))+:((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 1 : 1 - (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0))] <= shadow_inputs_in;
			shadow_tag_rdata_q[LockstepOffset - 1] <= ic_tag_rdata_i;
			shadow_data_rdata_q[LockstepOffset - 1] <= ic_data_rdata_i;
		end
	reg [(OutputsOffset * (((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth)) - 1:0] core_outputs_q;
	wire [(((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) - 1:0] core_outputs_in;
	wire [(((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) - 1:0] shadow_outputs_d;
	reg [(((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth) - 1:0] shadow_outputs_q;
	assign core_outputs_in[71 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))] = instr_req_i;
	assign core_outputs_in[70 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))-:((70 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) >= (38 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) ? ((70 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) - (38 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))))) + 1 : ((38 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))))) - (70 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))))) + 1)] = instr_addr_i;
	assign core_outputs_in[38 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))] = data_req_i;
	assign core_outputs_in[37 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))] = data_we_i;
	assign core_outputs_in[36 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))-:((36 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) >= (32 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) ? ((36 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) - (32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))))) + 1 : ((32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))))) - (36 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))))) + 1)] = data_be_i;
	assign core_outputs_in[32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))-:((32 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) >= (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))) ? ((32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) - (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))))) + 1 : ((MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) - (32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))))) + 1)] = data_addr_i;
	assign core_outputs_in[MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))-:((MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))) >= (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) - (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) + 1)] = data_wdata_i;
	assign core_outputs_in[18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))] = dummy_instr_id_i;
	assign core_outputs_in[17 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))] = dummy_instr_wb_i;
	assign core_outputs_in[16 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))-:((16 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) >= (11 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((16 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) - (11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (16 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) + 1)] = rf_raddr_a_i;
	assign core_outputs_in[11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))-:((11 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) >= (6 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) - (6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) + 1)] = rf_raddr_b_i;
	assign core_outputs_in[6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))-:((6 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) >= (1 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) - (1 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((1 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) + 1)] = rf_waddr_wb_i;
	assign core_outputs_in[1 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))] = rf_we_wb_i;
	assign core_outputs_in[RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))-:((RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))) >= (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))) ? ((RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))) + 1 : ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) - (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) + 1)] = rf_wdata_wb_ecc_i;
	assign core_outputs_in[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))-:((3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))) >= (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) - (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))) + 1)] = ic_tag_req_i;
	assign core_outputs_in[1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))] = ic_tag_write_i;
	assign core_outputs_in[ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))-:((ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))) >= (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))) ? ((ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))) + 1 : ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))) - (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))) + 1)] = ic_tag_addr_i;
	assign core_outputs_in[TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))-:((TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))) >= (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))) ? ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))) + 1 : ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))) + 1)] = ic_tag_wdata_i;
	assign core_outputs_in[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))-:((3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))) >= (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))) - (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))) + 1)] = ic_data_req_i;
	assign core_outputs_in[1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))] = ic_data_write_i;
	assign core_outputs_in[ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)-:((ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)) >= (LineSizeECC + 167) ? ((ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)) - (LineSizeECC + 167)) + 1 : ((LineSizeECC + 167) - (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))) + 1)] = ic_data_addr_i;
	assign core_outputs_in[LineSizeECC + 166-:((LineSizeECC + 166) >= 167 ? LineSizeECC : 168 - (LineSizeECC + 166))] = ic_data_wdata_i;
	assign core_outputs_in[166] = ic_scr_key_req_i;
	assign core_outputs_in[165] = irq_pending_i;
	assign core_outputs_in[164-:160] = crash_dump_i;
	assign core_outputs_in[4] = double_fault_seen_i;
	assign core_outputs_in[3-:ibex_pkg_IbexMuBiWidth] = core_busy_i;
	always @(posedge clk_i) begin
		begin : sv2v_autoblock_3
			reg [31:0] i;
			for (i = 0; i < (OutputsOffset - 1); i = i + 1)
				core_outputs_q[i * (((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth)+:((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth] <= core_outputs_q[(i + 1) * (((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth)+:((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth];
		end
		core_outputs_q[(OutputsOffset - 1) * (((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth)+:((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth] <= core_outputs_in;
	end
	wire shadow_alert_minor;
	wire shadow_alert_major_internal;
	wire shadow_alert_major_bus;
	ibex_core #(
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.ICache(ICache),
		.ICacheECC(ICacheECC),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.BranchPredictor(BranchPredictor),
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.WritebackStage(WritebackStage),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.SecureIbex(SecureIbex),
		.DummyInstructions(DummyInstructions),
		.RegFileECC(RegFileECC),
		.RegFileDataWidth(RegFileDataWidth),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.DmBaseAddr(DmBaseAddr),
		.DmAddrMask(DmAddrMask),
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr)
	) u_shadow_core(
		.clk_i(clk_i),
		.rst_ni(rst_shadow_n),
		.hart_id_i(hart_id_i),
		.boot_addr_i(boot_addr_i),
		.instr_req_o(shadow_outputs_d[71 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))]),
		.instr_gnt_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 2 + (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (2 + (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))))]),
		.instr_rvalid_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 1 + (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (1 + (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))))]),
		.instr_addr_o(shadow_outputs_d[70 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))-:((70 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) >= (38 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) ? ((70 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) - (38 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))))) + 1 : ((38 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))))) - (70 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))))) + 1)]),
		.instr_rdata_i(shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))) : ((0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))))) + ((MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) >= (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25))))) ? ((MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) - (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25)))))) + 1 : ((3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25))))) - (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))) + 1)) - 1)-:((MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) >= (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25))))) ? ((MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) - (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25)))))) + 1 : ((3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 25))))) - (MemDataWidth + (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))) + 1)]),
		.instr_err_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (3 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))]),
		.data_req_o(shadow_outputs_d[38 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))]),
		.data_gnt_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 2 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (2 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))]),
		.data_rvalid_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 1 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (1 + (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))))]),
		.data_we_o(shadow_outputs_d[37 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))]),
		.data_be_o(shadow_outputs_d[36 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))-:((36 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) >= (32 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) ? ((36 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) - (32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))))) + 1 : ((32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))))) - (36 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))))) + 1)]),
		.data_addr_o(shadow_outputs_d[32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))-:((32 + (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) >= (MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))) ? ((32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) - (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))))) + 1 : ((MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) - (32 + (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))))) + 1)]),
		.data_wdata_o(shadow_outputs_d[MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))-:((MemDataWidth + (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))) >= (18 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) - (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (MemDataWidth + (18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))))) + 1)]),
		.data_rdata_i(shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))) : ((0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))))) + ((MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) >= (1 + (RegFileDataWidth + (RegFileDataWidth + 25))) ? ((MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) - (1 + (RegFileDataWidth + (RegFileDataWidth + 25)))) + 1 : ((1 + (RegFileDataWidth + (RegFileDataWidth + 25))) - (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))) + 1)) - 1)-:((MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) >= (1 + (RegFileDataWidth + (RegFileDataWidth + 25))) ? ((MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24)))) - (1 + (RegFileDataWidth + (RegFileDataWidth + 25)))) + 1 : ((1 + (RegFileDataWidth + (RegFileDataWidth + 25))) - (MemDataWidth + (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))) + 1)]),
		.data_err_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 1 + (RegFileDataWidth + (RegFileDataWidth + 24)) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (1 + (RegFileDataWidth + (RegFileDataWidth + 24))))]),
		.dummy_instr_id_o(shadow_outputs_d[18 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))]),
		.dummy_instr_wb_o(shadow_outputs_d[17 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))]),
		.rf_raddr_a_o(shadow_outputs_d[16 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))-:((16 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) >= (11 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((16 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) - (11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (16 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) + 1)]),
		.rf_raddr_b_o(shadow_outputs_d[11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))-:((11 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) >= (6 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) - (6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (11 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) + 1)]),
		.rf_waddr_wb_o(shadow_outputs_d[6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))-:((6 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) >= (1 + (RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) ? ((6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) - (1 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))))) + 1 : ((1 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))))) - (6 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))))) + 1)]),
		.rf_we_wb_o(shadow_outputs_d[1 + (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))]),
		.rf_wdata_wb_ecc_o(shadow_outputs_d[RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))-:((RegFileDataWidth + (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))) >= (3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))) ? ((RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))))) + 1 : ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) - (RegFileDataWidth + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))))) + 1)]),
		.rf_rdata_a_ecc_i(shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? RegFileDataWidth + (RegFileDataWidth + 24) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (RegFileDataWidth + (RegFileDataWidth + 24))) : ((0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? RegFileDataWidth + (RegFileDataWidth + 24) : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (RegFileDataWidth + (RegFileDataWidth + 24)))) + ((RegFileDataWidth + (RegFileDataWidth + 24)) >= (RegFileDataWidth + 25) ? ((RegFileDataWidth + (RegFileDataWidth + 24)) - (RegFileDataWidth + 25)) + 1 : ((RegFileDataWidth + 25) - (RegFileDataWidth + (RegFileDataWidth + 24))) + 1)) - 1)-:((RegFileDataWidth + (RegFileDataWidth + 24)) >= (RegFileDataWidth + 25) ? ((RegFileDataWidth + (RegFileDataWidth + 24)) - (RegFileDataWidth + 25)) + 1 : ((RegFileDataWidth + 25) - (RegFileDataWidth + (RegFileDataWidth + 24))) + 1)]),
		.rf_rdata_b_ecc_i(shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? RegFileDataWidth + 24 : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (RegFileDataWidth + 24)) : ((0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? RegFileDataWidth + 24 : (((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0) - (RegFileDataWidth + 24))) + ((RegFileDataWidth + 24) >= 25 ? RegFileDataWidth : 26 - (RegFileDataWidth + 24))) - 1)-:((RegFileDataWidth + 24) >= 25 ? RegFileDataWidth : 26 - (RegFileDataWidth + 24))]),
		.ic_tag_req_o(shadow_outputs_d[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))-:((3 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))) >= (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))))) - (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))))) + 1)]),
		.ic_tag_write_o(shadow_outputs_d[1 + (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))]),
		.ic_tag_addr_o(shadow_outputs_d[ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))-:((ibex_pkg_IC_INDEX_W + (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))) >= (TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))) ? ((ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))))) + 1 : ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))) - (ibex_pkg_IC_INDEX_W + (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))))) + 1)]),
		.ic_tag_wdata_o(shadow_outputs_d[TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))-:((TagSizeECC + (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))) >= (3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))) ? ((TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))))) + 1 : ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))) - (TagSizeECC + (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))))) + 1)]),
		.ic_tag_rdata_i(shadow_tag_rdata_q[0]),
		.ic_data_req_o(shadow_outputs_d[ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))-:((3 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))) >= (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))) ? ((ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)))) - (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167)))) + 1 : ((1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 167))) - (ibex_pkg_IC_NUM_WAYS + (1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))))) + 1)]),
		.ic_data_write_o(shadow_outputs_d[1 + (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))]),
		.ic_data_addr_o(shadow_outputs_d[ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)-:((ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)) >= (LineSizeECC + 167) ? ((ibex_pkg_IC_INDEX_W + (LineSizeECC + 166)) - (LineSizeECC + 167)) + 1 : ((LineSizeECC + 167) - (ibex_pkg_IC_INDEX_W + (LineSizeECC + 166))) + 1)]),
		.ic_data_wdata_o(shadow_outputs_d[LineSizeECC + 166-:((LineSizeECC + 166) >= 167 ? LineSizeECC : 168 - (LineSizeECC + 166))]),
		.ic_data_rdata_i(shadow_data_rdata_q[0]),
		.ic_scr_key_valid_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) + 0)]),
		.ic_scr_key_req_o(shadow_outputs_d[166]),
		.irq_software_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 24 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 24)]),
		.irq_timer_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 23 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 23)]),
		.irq_external_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 22 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 22)]),
		.irq_fast_i(shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 21 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 21) : (0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 21 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 21)) + 14)-:15]),
		.irq_nm_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 6 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 6)]),
		.irq_pending_o(shadow_outputs_d[165]),
		.debug_req_i(shadow_inputs_q[0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 5 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 5)]),
		.crash_dump_o(shadow_outputs_d[164-:160]),
		.double_fault_seen_o(shadow_outputs_d[4]),
		.fetch_enable_i(shadow_inputs_q[((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 4 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 4) : (0 + ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 24) >= 0 ? 4 : ((((((((2 + MemDataWidth) + 3) + MemDataWidth) + 1) + RegFileDataWidth) + RegFileDataWidth) + 20) + ibex_pkg_IbexMuBiWidth) - 4)) + 3)-:4]),
		.alert_minor_o(shadow_alert_minor),
		.alert_major_internal_o(shadow_alert_major_internal),
		.alert_major_bus_o(shadow_alert_major_bus),
		.core_busy_o(shadow_outputs_d[3-:ibex_pkg_IbexMuBiWidth])
	);
	always @(posedge clk_i) shadow_outputs_q <= shadow_outputs_d;
	wire outputs_mismatch;
	assign outputs_mismatch = (enable_cmp_q != ibex_pkg_IbexMuBiOff) & (shadow_outputs_q != core_outputs_q[0+:((((((((((((71 + MemDataWidth) + 18) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 163) + ibex_pkg_IbexMuBiWidth]);
	assign alert_major_internal_o = (outputs_mismatch | shadow_alert_major_internal) | rst_shadow_cnt_err;
	assign alert_major_bus_o = shadow_alert_major_bus;
	assign alert_minor_o = shadow_alert_minor;
endmodule
module ibex_multdiv_fast (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero_i,
	data_ind_timing_i,
	alu_operand_a_o,
	alu_operand_b_o,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	multdiv_ready_id_i,
	multdiv_result_o,
	valid_o
);
	reg _sv2v_0;
	parameter integer RV32M = 32'sd2;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero_i;
	input wire data_ind_timing_i;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	input wire [67:0] imd_val_q_i;
	output wire [67:0] imd_val_d_o;
	output wire [1:0] imd_val_we_o;
	input wire multdiv_ready_id_i;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	wire signed [34:0] mac_res_signed;
	wire [34:0] mac_res_ext;
	reg [33:0] accum;
	reg sign_a;
	reg sign_b;
	reg mult_valid;
	wire signed_mult;
	reg [33:0] mac_res_d;
	reg [33:0] op_remainder_d;
	wire [33:0] mac_res;
	wire div_sign_a;
	wire div_sign_b;
	reg is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	wire [31:0] one_shift;
	wire [31:0] op_denominator_q;
	reg [31:0] op_numerator_q;
	reg [31:0] op_quotient_q;
	reg [31:0] op_denominator_d;
	reg [31:0] op_numerator_d;
	reg [31:0] op_quotient_d;
	wire [31:0] next_remainder;
	wire [32:0] next_quotient;
	wire [31:0] res_adder_h;
	reg div_valid;
	reg [4:0] div_counter_q;
	reg [4:0] div_counter_d;
	wire multdiv_en;
	reg mult_hold;
	reg div_hold;
	reg div_by_zero_d;
	reg div_by_zero_q;
	wire mult_en_internal;
	wire div_en_internal;
	wire sva_mul_fsm_idle;
	reg [2:0] md_state_q;
	reg [2:0] md_state_d;
	wire unused_mult_sel_i;
	assign unused_mult_sel_i = mult_sel_i;
	assign mult_en_internal = mult_en_i & ~mult_hold;
	assign div_en_internal = div_en_i & ~div_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			div_counter_q <= 1'sb0;
			md_state_q <= 3'd0;
			op_numerator_q <= 1'sb0;
			op_quotient_q <= 1'sb0;
			div_by_zero_q <= 1'sb0;
		end
		else if (div_en_internal) begin
			div_counter_q <= div_counter_d;
			op_numerator_q <= op_numerator_d;
			op_quotient_q <= op_quotient_d;
			md_state_q <= md_state_d;
			div_by_zero_q <= div_by_zero_d;
		end
	assign multdiv_en = mult_en_internal | div_en_internal;
	assign imd_val_d_o[34+:34] = (div_sel_i ? op_remainder_d : mac_res_d);
	assign imd_val_we_o[0] = multdiv_en;
	assign imd_val_d_o[0+:34] = {2'b00, op_denominator_d};
	assign imd_val_we_o[1] = div_en_internal;
	assign op_denominator_q = imd_val_q_i[31-:32];
	wire [1:0] unused_imd_val;
	assign unused_imd_val = imd_val_q_i[33-:2];
	wire unused_mac_res_ext;
	assign unused_mac_res_ext = mac_res_ext[34];
	assign signed_mult = signed_mode_i != 2'b00;
	assign multdiv_result_o = (div_sel_i ? imd_val_q_i[65-:32] : mac_res_d[31:0]);
	generate
		if (RV32M == 32'sd3) begin : gen_mult_single_cycle
			reg mult_state_q;
			reg mult_state_d;
			wire signed [33:0] mult1_res;
			wire signed [33:0] mult2_res;
			wire signed [33:0] mult3_res;
			wire [33:0] mult1_res_uns;
			wire [33:32] unused_mult1_res_uns;
			wire [15:0] mult1_op_a;
			wire [15:0] mult1_op_b;
			wire [15:0] mult2_op_a;
			wire [15:0] mult2_op_b;
			reg [15:0] mult3_op_a;
			reg [15:0] mult3_op_b;
			wire mult1_sign_a;
			wire mult1_sign_b;
			wire mult2_sign_a;
			wire mult2_sign_b;
			reg mult3_sign_a;
			reg mult3_sign_b;
			reg [33:0] summand1;
			reg [33:0] summand2;
			reg [33:0] summand3;
			assign mult1_res = $signed({mult1_sign_a, mult1_op_a}) * $signed({mult1_sign_b, mult1_op_b});
			assign mult2_res = $signed({mult2_sign_a, mult2_op_a}) * $signed({mult2_sign_b, mult2_op_b});
			assign mult3_res = $signed({mult3_sign_a, mult3_op_a}) * $signed({mult3_sign_b, mult3_op_b});
			assign mac_res_signed = ($signed(summand1) + $signed(summand2)) + $signed(summand3);
			assign mult1_res_uns = $unsigned(mult1_res);
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			wire [1:1] sv2v_tmp_5ADA8;
			assign sv2v_tmp_5ADA8 = signed_mode_i[0] & op_a_i[31];
			always @(*) sign_a = sv2v_tmp_5ADA8;
			wire [1:1] sv2v_tmp_C5449;
			assign sv2v_tmp_C5449 = signed_mode_i[1] & op_b_i[31];
			always @(*) sign_b = sv2v_tmp_C5449;
			assign mult1_sign_a = 1'b0;
			assign mult1_sign_b = 1'b0;
			assign mult1_op_a = op_a_i[15:0];
			assign mult1_op_b = op_b_i[15:0];
			assign mult2_sign_a = 1'b0;
			assign mult2_sign_b = sign_b;
			assign mult2_op_a = op_a_i[15:0];
			assign mult2_op_b = op_b_i[31:16];
			wire [18:1] sv2v_tmp_6FF3F;
			assign sv2v_tmp_6FF3F = imd_val_q_i[67-:18];
			always @(*) accum[17:0] = sv2v_tmp_6FF3F;
			wire [16:1] sv2v_tmp_A7770;
			assign sv2v_tmp_A7770 = {16 {signed_mult & imd_val_q_i[67]}};
			always @(*) accum[33:18] = sv2v_tmp_A7770;
			always @(*) begin
				if (_sv2v_0)
					;
				mult3_sign_a = sign_a;
				mult3_sign_b = 1'b0;
				mult3_op_a = op_a_i[31:16];
				mult3_op_b = op_b_i[15:0];
				summand1 = {18'h00000, mult1_res_uns[31:16]};
				summand2 = $unsigned(mult2_res);
				summand3 = $unsigned(mult3_res);
				mac_res_d = {2'b00, mac_res[15:0], mult1_res_uns[15:0]};
				mult_valid = mult_en_i;
				mult_state_d = 1'd0;
				mult_hold = 1'b0;
				(* full_case, parallel_case *)
				case (mult_state_q)
					1'd0:
						if (operator_i != 2'd0) begin
							mac_res_d = mac_res;
							mult_valid = 1'b0;
							mult_state_d = 1'd1;
						end
						else
							mult_hold = ~multdiv_ready_id_i;
					1'd1: begin
						mult3_sign_a = sign_a;
						mult3_sign_b = sign_b;
						mult3_op_a = op_a_i[31:16];
						mult3_op_b = op_b_i[31:16];
						mac_res_d = mac_res;
						summand1 = 1'sb0;
						summand2 = accum;
						summand3 = $unsigned(mult3_res);
						mult_state_d = 1'd0;
						mult_valid = 1'b1;
						mult_hold = ~multdiv_ready_id_i;
					end
					default: mult_state_d = 1'd0;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= 1'd0;
				else if (mult_en_internal)
					mult_state_q <= mult_state_d;
			assign unused_mult1_res_uns = mult1_res_uns[33:32];
			assign sva_mul_fsm_idle = mult_state_q == 1'd0;
		end
		else begin : gen_mult_fast
			reg [15:0] mult_op_a;
			reg [15:0] mult_op_b;
			reg [1:0] mult_state_q;
			reg [1:0] mult_state_d;
			assign mac_res_signed = ($signed({sign_a, mult_op_a}) * $signed({sign_b, mult_op_b})) + $signed(accum);
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			always @(*) begin
				if (_sv2v_0)
					;
				mult_op_a = op_a_i[15:0];
				mult_op_b = op_b_i[15:0];
				sign_a = 1'b0;
				sign_b = 1'b0;
				accum = imd_val_q_i[34+:34];
				mac_res_d = mac_res;
				mult_state_d = mult_state_q;
				mult_valid = 1'b0;
				mult_hold = 1'b0;
				(* full_case, parallel_case *)
				case (mult_state_q)
					2'd0: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[15:0];
						sign_a = 1'b0;
						sign_b = 1'b0;
						accum = 1'sb0;
						mac_res_d = mac_res;
						mult_state_d = 2'd1;
					end
					2'd1: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[31:16];
						sign_a = 1'b0;
						sign_b = signed_mode_i[1] & op_b_i[31];
						accum = {18'b000000000000000000, imd_val_q_i[65-:16]};
						if (operator_i == 2'd0)
							mac_res_d = {2'b00, mac_res[15:0], imd_val_q_i[49-:16]};
						else
							mac_res_d = mac_res;
						mult_state_d = 2'd2;
					end
					2'd2: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[15:0];
						sign_a = signed_mode_i[0] & op_a_i[31];
						sign_b = 1'b0;
						if (operator_i == 2'd0) begin
							accum = {18'b000000000000000000, imd_val_q_i[65-:16]};
							mac_res_d = {2'b00, mac_res[15:0], imd_val_q_i[49-:16]};
							mult_valid = 1'b1;
							mult_state_d = 2'd0;
							mult_hold = ~multdiv_ready_id_i;
						end
						else begin
							accum = imd_val_q_i[34+:34];
							mac_res_d = mac_res;
							mult_state_d = 2'd3;
						end
					end
					2'd3: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[31:16];
						sign_a = signed_mode_i[0] & op_a_i[31];
						sign_b = signed_mode_i[1] & op_b_i[31];
						accum[17:0] = imd_val_q_i[67-:18];
						accum[33:18] = {16 {signed_mult & imd_val_q_i[67]}};
						mac_res_d = mac_res;
						mult_valid = 1'b1;
						mult_state_d = 2'd0;
						mult_hold = ~multdiv_ready_id_i;
					end
					default: mult_state_d = 2'd0;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= 2'd0;
				else if (mult_en_internal)
					mult_state_q <= mult_state_d;
			assign sva_mul_fsm_idle = mult_state_q == 2'd0;
		end
	endgenerate
	assign res_adder_h = alu_adder_ext_i[32:1];
	wire [1:0] unused_alu_adder_ext;
	assign unused_alu_adder_ext = {alu_adder_ext_i[33], alu_adder_ext_i[0]};
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : imd_val_q_i[65-:32]);
	assign next_quotient = (is_greater_equal ? {1'b0, op_quotient_q} | {1'b0, one_shift} : {1'b0, op_quotient_q});
	assign one_shift = 32'b00000000000000000000000000000001 << div_counter_q;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((imd_val_q_i[65] ^ op_denominator_q[31]) == 1'b0)
			is_greater_equal = res_adder_h[31] == 1'b0;
		else
			is_greater_equal = imd_val_q_i[65];
	end
	assign div_sign_a = op_a_i[31] & signed_mode_i[0];
	assign div_sign_b = op_b_i[31] & signed_mode_i[1];
	assign div_change_sign = (div_sign_a ^ div_sign_b) & ~div_by_zero_q;
	assign rem_change_sign = div_sign_a;
	always @(*) begin
		if (_sv2v_0)
			;
		div_counter_d = div_counter_q - 5'h01;
		op_remainder_d = imd_val_q_i[34+:34];
		op_quotient_d = op_quotient_q;
		md_state_d = md_state_q;
		op_numerator_d = op_numerator_q;
		op_denominator_d = op_denominator_q;
		alu_operand_a_o = 33'h000000001;
		alu_operand_b_o = {~op_b_i, 1'b1};
		div_valid = 1'b0;
		div_hold = 1'b0;
		div_by_zero_d = div_by_zero_q;
		(* full_case, parallel_case *)
		case (md_state_q)
			3'd0: begin
				if (operator_i == 2'd2) begin
					op_remainder_d = 1'sb1;
					md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
					div_by_zero_d = equal_to_zero_i;
				end
				else begin
					op_remainder_d = {2'b00, op_a_i};
					md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
				end
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_b_i, 1'b1};
				div_counter_d = 5'd31;
			end
			3'd1: begin
				op_quotient_d = 1'sb0;
				op_numerator_d = (div_sign_a ? alu_adder_i : op_a_i);
				md_state_d = 3'd2;
				div_counter_d = 5'd31;
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_a_i, 1'b1};
			end
			3'd2: begin
				op_remainder_d = {33'h000000000, op_numerator_q[31]};
				op_denominator_d = (div_sign_b ? alu_adder_i : op_b_i);
				md_state_d = 3'd3;
				div_counter_d = 5'd31;
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_b_i, 1'b1};
			end
			3'd3: begin
				op_remainder_d = {1'b0, next_remainder[31:0], op_numerator_q[div_counter_d]};
				op_quotient_d = next_quotient[31:0];
				md_state_d = (div_counter_q == 5'd1 ? 3'd4 : 3'd3);
				alu_operand_a_o = {imd_val_q_i[65-:32], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
			end
			3'd4: begin
				if (operator_i == 2'd2)
					op_remainder_d = {1'b0, next_quotient};
				else
					op_remainder_d = {2'b00, next_remainder[31:0]};
				alu_operand_a_o = {imd_val_q_i[65-:32], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
				md_state_d = 3'd5;
			end
			3'd5: begin
				md_state_d = 3'd6;
				if (operator_i == 2'd2)
					op_remainder_d = (div_change_sign ? {2'h0, alu_adder_i} : imd_val_q_i[34+:34]);
				else
					op_remainder_d = (rem_change_sign ? {2'h0, alu_adder_i} : imd_val_q_i[34+:34]);
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~imd_val_q_i[65-:32], 1'b1};
			end
			3'd6: begin
				md_state_d = 3'd0;
				div_hold = ~multdiv_ready_id_i;
				div_valid = 1'b1;
			end
			default: md_state_d = 3'd0;
		endcase
	end
	assign valid_o = mult_valid | div_valid;
	wire unused_sva_mul_fsm_idle;
	assign unused_sva_mul_fsm_idle = sva_mul_fsm_idle;
	initial _sv2v_0 = 0;
endmodule
module ibex_multdiv_slow (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero_i,
	data_ind_timing_i,
	alu_operand_a_o,
	alu_operand_b_o,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	multdiv_ready_id_i,
	multdiv_result_o,
	valid_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero_i;
	input wire data_ind_timing_i;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	input wire [67:0] imd_val_q_i;
	output wire [67:0] imd_val_d_o;
	output wire [1:0] imd_val_we_o;
	input wire multdiv_ready_id_i;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	reg [2:0] md_state_q;
	reg [2:0] md_state_d;
	wire [32:0] accum_window_q;
	reg [32:0] accum_window_d;
	wire unused_imd_val0;
	wire [1:0] unused_imd_val1;
	wire [32:0] res_adder_l;
	wire [32:0] res_adder_h;
	reg [4:0] multdiv_count_q;
	reg [4:0] multdiv_count_d;
	reg [32:0] op_b_shift_q;
	reg [32:0] op_b_shift_d;
	reg [32:0] op_a_shift_q;
	reg [32:0] op_a_shift_d;
	wire [32:0] op_a_ext;
	wire [32:0] op_b_ext;
	wire [32:0] one_shift;
	wire [32:0] op_a_bw_pp;
	wire [32:0] op_a_bw_last_pp;
	wire [31:0] b_0;
	wire sign_a;
	wire sign_b;
	wire [32:0] next_quotient;
	wire [31:0] next_remainder;
	wire [31:0] op_numerator_q;
	reg [31:0] op_numerator_d;
	wire is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	reg div_by_zero_d;
	reg div_by_zero_q;
	reg multdiv_hold;
	wire multdiv_en;
	assign res_adder_l = alu_adder_ext_i[32:0];
	assign res_adder_h = alu_adder_ext_i[33:1];
	assign imd_val_d_o[34+:34] = {1'b0, accum_window_d};
	assign imd_val_we_o[0] = ~multdiv_hold;
	assign accum_window_q = imd_val_q_i[66-:33];
	assign unused_imd_val0 = imd_val_q_i[67];
	assign imd_val_d_o[0+:34] = {2'b00, op_numerator_d};
	assign imd_val_we_o[1] = multdiv_en;
	assign op_numerator_q = imd_val_q_i[31-:32];
	assign unused_imd_val1 = imd_val_q_i[33-:2];
	always @(*) begin
		if (_sv2v_0)
			;
		alu_operand_a_o = accum_window_q;
		(* full_case, parallel_case *)
		case (operator_i)
			2'd0: alu_operand_b_o = op_a_bw_pp;
			2'd1: alu_operand_b_o = (md_state_q == 3'd4 ? op_a_bw_last_pp : op_a_bw_pp);
			2'd2, 2'd3:
				(* full_case, parallel_case *)
				case (md_state_q)
					3'd0: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					3'd1: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_a_i, 1'b1};
					end
					3'd2: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					3'd5: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~accum_window_q[31:0], 1'b1};
					end
					default: begin
						alu_operand_a_o = {accum_window_q[31:0], 1'b1};
						alu_operand_b_o = {~op_b_shift_q[31:0], 1'b1};
					end
				endcase
			default: begin
				alu_operand_a_o = accum_window_q;
				alu_operand_b_o = {~op_b_shift_q[31:0], 1'b1};
			end
		endcase
	end
	assign b_0 = {32 {op_b_shift_q[0]}};
	assign op_a_bw_pp = {~(op_a_shift_q[32] & op_b_shift_q[0]), op_a_shift_q[31:0] & b_0};
	assign op_a_bw_last_pp = {op_a_shift_q[32] & op_b_shift_q[0], ~(op_a_shift_q[31:0] & b_0)};
	assign sign_a = op_a_i[31] & signed_mode_i[0];
	assign sign_b = op_b_i[31] & signed_mode_i[1];
	assign op_a_ext = {sign_a, op_a_i};
	assign op_b_ext = {sign_b, op_b_i};
	assign is_greater_equal = (accum_window_q[31] == op_b_shift_q[31] ? ~res_adder_h[31] : accum_window_q[31]);
	assign one_shift = 33'b000000000000000000000000000000001 << multdiv_count_q;
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : accum_window_q[31:0]);
	assign next_quotient = (is_greater_equal ? op_a_shift_q | one_shift : op_a_shift_q);
	assign div_change_sign = (sign_a ^ sign_b) & ~div_by_zero_q;
	assign rem_change_sign = sign_a;
	always @(*) begin
		if (_sv2v_0)
			;
		multdiv_count_d = multdiv_count_q;
		accum_window_d = accum_window_q;
		op_b_shift_d = op_b_shift_q;
		op_a_shift_d = op_a_shift_q;
		op_numerator_d = op_numerator_q;
		md_state_d = md_state_q;
		multdiv_hold = 1'b0;
		div_by_zero_d = div_by_zero_q;
		if (mult_sel_i || div_sel_i)
			(* full_case, parallel_case *)
			case (md_state_q)
				3'd0: begin
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							op_a_shift_d = op_a_ext << 1;
							accum_window_d = {~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:0] & {32 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							md_state_d = (!data_ind_timing_i && ((op_b_ext >> 1) == 0) ? 3'd4 : 3'd3);
						end
						2'd1: begin
							op_a_shift_d = op_a_ext;
							accum_window_d = {1'b1, ~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:1] & {31 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							md_state_d = 3'd3;
						end
						2'd2: begin
							accum_window_d = {33 {1'b1}};
							md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
							div_by_zero_d = equal_to_zero_i;
						end
						2'd3: begin
							accum_window_d = op_a_ext;
							md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
						end
						default:
							;
					endcase
					multdiv_count_d = 5'd31;
				end
				3'd1: begin
					op_a_shift_d = 1'sb0;
					op_numerator_d = (sign_a ? alu_adder_i : op_a_i);
					md_state_d = 3'd2;
				end
				3'd2: begin
					accum_window_d = {32'h00000000, op_numerator_q[31]};
					op_b_shift_d = (sign_b ? {1'b0, alu_adder_i} : {1'b0, op_b_i});
					md_state_d = 3'd3;
				end
				3'd3: begin
					multdiv_count_d = multdiv_count_q - 5'h01;
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							accum_window_d = res_adder_l;
							op_a_shift_d = op_a_shift_q << 1;
							op_b_shift_d = op_b_shift_q >> 1;
							md_state_d = ((!data_ind_timing_i && (op_b_shift_d == 0)) || (multdiv_count_q == 5'd1) ? 3'd4 : 3'd3);
						end
						2'd1: begin
							accum_window_d = res_adder_h;
							op_a_shift_d = op_a_shift_q;
							op_b_shift_d = op_b_shift_q >> 1;
							md_state_d = (multdiv_count_q == 5'd1 ? 3'd4 : 3'd3);
						end
						2'd2, 2'd3: begin
							accum_window_d = {next_remainder[31:0], op_numerator_q[multdiv_count_d]};
							op_a_shift_d = next_quotient;
							md_state_d = (multdiv_count_q == 5'd1 ? 3'd4 : 3'd3);
						end
						default:
							;
					endcase
				end
				3'd4:
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							accum_window_d = res_adder_l;
							md_state_d = 3'd0;
							multdiv_hold = ~multdiv_ready_id_i;
						end
						2'd1: begin
							accum_window_d = res_adder_l;
							md_state_d = 3'd0;
							md_state_d = 3'd0;
							multdiv_hold = ~multdiv_ready_id_i;
						end
						2'd2: begin
							accum_window_d = next_quotient;
							md_state_d = 3'd5;
						end
						2'd3: begin
							accum_window_d = {1'b0, next_remainder[31:0]};
							md_state_d = 3'd5;
						end
						default:
							;
					endcase
				3'd5: begin
					md_state_d = 3'd6;
					(* full_case, parallel_case *)
					case (operator_i)
						2'd2: accum_window_d = (div_change_sign ? {1'b0, alu_adder_i} : accum_window_q);
						2'd3: accum_window_d = (rem_change_sign ? {1'b0, alu_adder_i} : accum_window_q);
						default:
							;
					endcase
				end
				3'd6: begin
					md_state_d = 3'd0;
					multdiv_hold = ~multdiv_ready_id_i;
				end
				default: md_state_d = 3'd0;
			endcase
	end
	assign multdiv_en = (mult_en_i | div_en_i) & ~multdiv_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			multdiv_count_q <= 5'h00;
			op_b_shift_q <= 33'h000000000;
			op_a_shift_q <= 33'h000000000;
			md_state_q <= 3'd0;
			div_by_zero_q <= 1'b0;
		end
		else if (multdiv_en) begin
			multdiv_count_q <= multdiv_count_d;
			op_b_shift_q <= op_b_shift_d;
			op_a_shift_q <= op_a_shift_d;
			md_state_q <= md_state_d;
			div_by_zero_q <= div_by_zero_d;
		end
	assign valid_o = (md_state_q == 3'd6) | ((md_state_q == 3'd4) & ((operator_i == 2'd0) | (operator_i == 2'd1)));
	assign multdiv_result_o = (div_en_i ? accum_window_q[31:0] : res_adder_l[31:0]);
	initial _sv2v_0 = 0;
endmodule
module ibex_pmp (
	csr_pmp_cfg_i,
	csr_pmp_addr_i,
	csr_pmp_mseccfg_i,
	debug_mode_i,
	priv_mode_i,
	pmp_req_addr_i,
	pmp_req_type_i,
	pmp_req_err_o
);
	reg _sv2v_0;
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumChan = 2;
	parameter [31:0] PMPNumRegions = 4;
	input wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg_i;
	input wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr_i;
	input wire [2:0] csr_pmp_mseccfg_i;
	input wire debug_mode_i;
	input wire [(PMPNumChan * 2) - 1:0] priv_mode_i;
	input wire [(PMPNumChan * 34) - 1:0] pmp_req_addr_i;
	input wire [(PMPNumChan * 2) - 1:0] pmp_req_type_i;
	output wire [0:PMPNumChan - 1] pmp_req_err_o;
	wire [33:0] region_start_addr [0:PMPNumRegions - 1];
	wire [33:PMPGranularity + 2] region_addr_mask [0:PMPNumRegions - 1];
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_match_gt;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_match_lt;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_match_eq;
	reg [(PMPNumChan * PMPNumRegions) - 1:0] region_match_all;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_basic_perm_check;
	wire [(PMPNumChan * PMPNumRegions) - 1:0] region_perm_check;
	wire [PMPNumChan - 1:0] debug_mode_allowed_access;
	function automatic mml_perm_check;
		input reg [5:0] region_csr_pmp_cfg;
		input reg [1:0] pmp_req_type;
		input reg [1:0] priv_mode;
		input reg permission_check;
		reg result;
		reg unused_cfg;
		begin
			result = 1'b0;
			unused_cfg = |region_csr_pmp_cfg[4-:2];
			if (!region_csr_pmp_cfg[0] && region_csr_pmp_cfg[1])
				(* full_case, parallel_case *)
				case ({region_csr_pmp_cfg[5], region_csr_pmp_cfg[2]})
					2'b00: result = (pmp_req_type == 2'b10) | ((pmp_req_type == 2'b01) & (priv_mode == 2'b11));
					2'b01: result = (pmp_req_type == 2'b10) | (pmp_req_type == 2'b01);
					2'b10: result = pmp_req_type == 2'b00;
					2'b11: result = (pmp_req_type == 2'b00) | ((pmp_req_type == 2'b10) & (priv_mode == 2'b11));
					default:
						;
				endcase
			else if (((region_csr_pmp_cfg[0] & region_csr_pmp_cfg[1]) & region_csr_pmp_cfg[2]) & region_csr_pmp_cfg[5])
				result = pmp_req_type == 2'b10;
			else
				result = permission_check & (priv_mode == 2'b11 ? region_csr_pmp_cfg[5] : ~region_csr_pmp_cfg[5]);
			mml_perm_check = result;
		end
	endfunction
	function automatic orig_perm_check;
		input reg pmp_cfg_lock;
		input reg [1:0] priv_mode;
		input reg permission_check;
		orig_perm_check = (priv_mode == 2'b11 ? ~pmp_cfg_lock | permission_check : permission_check);
	endfunction
	function automatic perm_check_wrapper;
		input reg csr_pmp_mseccfg_mml;
		input reg [5:0] region_csr_pmp_cfg;
		input reg [1:0] pmp_req_type;
		input reg [1:0] priv_mode;
		input reg permission_check;
		perm_check_wrapper = (csr_pmp_mseccfg_mml ? mml_perm_check(region_csr_pmp_cfg, pmp_req_type, priv_mode, permission_check) : orig_perm_check(region_csr_pmp_cfg[5], priv_mode, permission_check));
	endfunction
	function automatic access_fault_check;
		input reg csr_pmp_mseccfg_mmwp;
		input reg csr_pmp_mseccfg_mml;
		input reg [1:0] pmp_req_type;
		input reg [PMPNumRegions - 1:0] match_all;
		input reg [1:0] priv_mode;
		input reg [PMPNumRegions - 1:0] final_perm_check;
		reg access_fail;
		reg matched;
		begin
			access_fail = (csr_pmp_mseccfg_mmwp | (priv_mode != 2'b11)) | (csr_pmp_mseccfg_mml && (pmp_req_type == 2'b00));
			matched = 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] r;
				for (r = 0; r < PMPNumRegions; r = r + 1)
					if (!matched && match_all[r]) begin
						access_fail = ~final_perm_check[r];
						matched = 1'b1;
					end
			end
			access_fault_check = access_fail;
		end
	endfunction
	genvar _gv_r_1;
	generate
		for (_gv_r_1 = 0; _gv_r_1 < PMPNumRegions; _gv_r_1 = _gv_r_1 + 1) begin : g_addr_exp
			localparam r = _gv_r_1;
			if (r == 0) begin : g_entry0
				assign region_start_addr[r] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] == 2'b01 ? 34'h000000000 : csr_pmp_addr_i[((PMPNumRegions - 1) - r) * 34+:34]);
			end
			else begin : g_oth
				assign region_start_addr[r] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] == 2'b01 ? csr_pmp_addr_i[((PMPNumRegions - 1) - (r - 1)) * 34+:34] : csr_pmp_addr_i[((PMPNumRegions - 1) - r) * 34+:34]);
			end
			genvar _gv_b_2;
			for (_gv_b_2 = PMPGranularity + 2; _gv_b_2 < 34; _gv_b_2 = _gv_b_2 + 1) begin : g_bitmask
				localparam b = _gv_b_2;
				if (b == 2) begin : g_bit0
					assign region_addr_mask[r][b] = csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] != 2'b11;
				end
				else begin : g_others
					if (PMPGranularity == 0) begin : g_region_addr_mask_zero_granularity
						assign region_addr_mask[r][b] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] != 2'b11) | ~&csr_pmp_addr_i[(((PMPNumRegions - 1) - r) * 34) + ((b - 1) >= 2 ? b - 1 : ((b - 1) + ((b - 1) >= 2 ? b - 2 : 4 - b)) - 1)-:((b - 1) >= 2 ? b - 2 : 4 - b)];
					end
					else begin : g_region_addr_mask_other_granularity
						assign region_addr_mask[r][b] = (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2] != 2'b11) | ~&csr_pmp_addr_i[(((PMPNumRegions - 1) - r) * 34) + ((b - 1) >= (PMPGranularity + 1) ? b - 1 : ((b - 1) + ((b - 1) >= (PMPGranularity + 1) ? ((b - 1) - (PMPGranularity + 1)) + 1 : ((PMPGranularity + 1) - (b - 1)) + 1)) - 1)-:((b - 1) >= (PMPGranularity + 1) ? ((b - 1) - (PMPGranularity + 1)) + 1 : ((PMPGranularity + 1) - (b - 1)) + 1)];
					end
				end
			end
		end
	endgenerate
	genvar _gv_c_1;
	generate
		for (_gv_c_1 = 0; _gv_c_1 < PMPNumChan; _gv_c_1 = _gv_c_1 + 1) begin : g_access_check
			localparam c = _gv_c_1;
			genvar _gv_r_2;
			for (_gv_r_2 = 0; _gv_r_2 < PMPNumRegions; _gv_r_2 = _gv_r_2 + 1) begin : g_regions
				localparam r = _gv_r_2;
				assign region_match_eq[(c * PMPNumRegions) + r] = (pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + (33 >= (PMPGranularity + 2) ? 33 : (33 + (33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)) - 1)-:(33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)] & region_addr_mask[r]) == (region_start_addr[r][33:PMPGranularity + 2] & region_addr_mask[r]);
				assign region_match_gt[(c * PMPNumRegions) + r] = pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + (33 >= (PMPGranularity + 2) ? 33 : (33 + (33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)) - 1)-:(33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)] > region_start_addr[r][33:PMPGranularity + 2];
				assign region_match_lt[(c * PMPNumRegions) + r] = pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + (33 >= (PMPGranularity + 2) ? 33 : (33 + (33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)) - 1)-:(33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)] < csr_pmp_addr_i[(((PMPNumRegions - 1) - r) * 34) + (33 >= (PMPGranularity + 2) ? 33 : (33 + (33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)) - 1)-:(33 >= (PMPGranularity + 2) ? 34 - (PMPGranularity + 2) : PMPGranularity - 30)];
				always @(*) begin
					if (_sv2v_0)
						;
					region_match_all[(c * PMPNumRegions) + r] = 1'b0;
					(* full_case, parallel_case *)
					case (csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 4-:2])
						2'b00: region_match_all[(c * PMPNumRegions) + r] = 1'b0;
						2'b10: region_match_all[(c * PMPNumRegions) + r] = region_match_eq[(c * PMPNumRegions) + r];
						2'b11: region_match_all[(c * PMPNumRegions) + r] = region_match_eq[(c * PMPNumRegions) + r];
						2'b01: region_match_all[(c * PMPNumRegions) + r] = (region_match_eq[(c * PMPNumRegions) + r] | region_match_gt[(c * PMPNumRegions) + r]) & region_match_lt[(c * PMPNumRegions) + r];
						default: region_match_all[(c * PMPNumRegions) + r] = 1'b0;
					endcase
				end
				assign region_basic_perm_check[(c * PMPNumRegions) + r] = (((pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2] == 2'b00) & csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 2]) | ((pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2] == 2'b01) & csr_pmp_cfg_i[(((PMPNumRegions - 1) - r) * 6) + 1])) | ((pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2] == 2'b10) & csr_pmp_cfg_i[((PMPNumRegions - 1) - r) * 6]);
				assign region_perm_check[(c * PMPNumRegions) + r] = perm_check_wrapper(csr_pmp_mseccfg_i[0], csr_pmp_cfg_i[((PMPNumRegions - 1) - r) * 6+:6], pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2], priv_mode_i[((PMPNumChan - 1) - c) * 2+:2], region_basic_perm_check[(c * PMPNumRegions) + r]);
				wire unused_sigs;
				assign unused_sigs = ^{region_start_addr[r][PMPGranularity + 1:0], pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + ((PMPGranularity + 1) >= 0 ? PMPGranularity + 1 : ((PMPGranularity + 1) + ((PMPGranularity + 1) >= 0 ? PMPGranularity + 2 : 1 - (PMPGranularity + 1))) - 1)-:((PMPGranularity + 1) >= 0 ? PMPGranularity + 2 : 1 - (PMPGranularity + 1))]};
			end
			assign debug_mode_allowed_access[c] = debug_mode_i & ((pmp_req_addr_i[(((PMPNumChan - 1) - c) * 34) + 31-:32] & ~DmAddrMask) == DmBaseAddr);
			assign pmp_req_err_o[c] = ~debug_mode_allowed_access[c] & access_fault_check(csr_pmp_mseccfg_i[1], csr_pmp_mseccfg_i[0], pmp_req_type_i[((PMPNumChan - 1) - c) * 2+:2], region_match_all[c * PMPNumRegions+:PMPNumRegions], priv_mode_i[((PMPNumChan - 1) - c) * 2+:2], region_perm_check[c * PMPNumRegions+:PMPNumRegions]);
		end
	endgenerate
	wire unused_csr_pmp_mseccfg_rlb;
	assign unused_csr_pmp_mseccfg_rlb = csr_pmp_mseccfg_i[2];
	initial _sv2v_0 = 0;
endmodule
module ibex_prefetch_buffer (
	clk_i,
	rst_ni,
	req_i,
	branch_i,
	addr_i,
	ready_i,
	valid_o,
	rdata_o,
	addr_o,
	err_o,
	err_plus2_o,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	instr_rvalid_i,
	busy_o
);
	parameter [0:0] ResetAll = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] addr_i;
	input wire ready_i;
	output wire valid_o;
	output wire [31:0] rdata_o;
	output wire [31:0] addr_o;
	output wire err_o;
	output wire err_plus2_o;
	output wire instr_req_o;
	input wire instr_gnt_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_err_i;
	input wire instr_rvalid_i;
	output wire busy_o;
	localparam [31:0] NUM_REQS = 2;
	wire valid_new_req;
	wire valid_req;
	wire valid_req_d;
	reg valid_req_q;
	wire discard_req_d;
	reg discard_req_q;
	wire [1:0] rdata_outstanding_n;
	wire [1:0] rdata_outstanding_s;
	reg [1:0] rdata_outstanding_q;
	wire [1:0] branch_discard_n;
	wire [1:0] branch_discard_s;
	reg [1:0] branch_discard_q;
	wire [1:0] rdata_outstanding_rev;
	wire [31:0] stored_addr_d;
	reg [31:0] stored_addr_q;
	wire stored_addr_en;
	wire [31:0] fetch_addr_d;
	reg [31:0] fetch_addr_q;
	wire fetch_addr_en;
	wire [31:0] instr_addr;
	wire [31:0] instr_addr_w_aligned;
	wire fifo_valid;
	wire [31:0] fifo_addr;
	wire fifo_ready;
	wire fifo_clear;
	wire [1:0] fifo_busy;
	assign busy_o = |rdata_outstanding_q | instr_req_o;
	assign fifo_clear = branch_i;
	genvar _gv_i_31;
	generate
		for (_gv_i_31 = 0; _gv_i_31 < NUM_REQS; _gv_i_31 = _gv_i_31 + 1) begin : gen_rd_rev
			localparam i = _gv_i_31;
			assign rdata_outstanding_rev[i] = rdata_outstanding_q[1 - i];
		end
	endgenerate
	assign fifo_ready = ~&(fifo_busy | rdata_outstanding_rev);
	ibex_fetch_fifo #(
		.NUM_REQS(NUM_REQS),
		.ResetAll(ResetAll)
	) fifo_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clear_i(fifo_clear),
		.busy_o(fifo_busy),
		.in_valid_i(fifo_valid),
		.in_addr_i(fifo_addr),
		.in_rdata_i(instr_rdata_i),
		.in_err_i(instr_err_i),
		.out_valid_o(valid_o),
		.out_ready_i(ready_i),
		.out_rdata_o(rdata_o),
		.out_addr_o(addr_o),
		.out_err_o(err_o),
		.out_err_plus2_o(err_plus2_o)
	);
	assign valid_new_req = (req_i & (fifo_ready | branch_i)) & ~rdata_outstanding_q[1];
	assign valid_req = valid_req_q | valid_new_req;
	assign valid_req_d = valid_req & ~instr_gnt_i;
	assign discard_req_d = valid_req_q & (branch_i | discard_req_q);
	assign stored_addr_en = (valid_new_req & ~valid_req_q) & ~instr_gnt_i;
	assign stored_addr_d = instr_addr;
	generate
		if (ResetAll) begin : g_stored_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					stored_addr_q <= 1'sb0;
				else if (stored_addr_en)
					stored_addr_q <= stored_addr_d;
		end
		else begin : g_stored_addr_nr
			always @(posedge clk_i)
				if (stored_addr_en)
					stored_addr_q <= stored_addr_d;
		end
	endgenerate
	assign fetch_addr_en = branch_i | (valid_new_req & ~valid_req_q);
	assign fetch_addr_d = (branch_i ? addr_i : {fetch_addr_q[31:2], 2'b00}) + {{29 {1'b0}}, valid_new_req & ~valid_req_q, 2'b00};
	generate
		if (ResetAll) begin : g_fetch_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					fetch_addr_q <= 1'sb0;
				else if (fetch_addr_en)
					fetch_addr_q <= fetch_addr_d;
		end
		else begin : g_fetch_addr_nr
			always @(posedge clk_i)
				if (fetch_addr_en)
					fetch_addr_q <= fetch_addr_d;
		end
	endgenerate
	assign instr_addr = (valid_req_q ? stored_addr_q : (branch_i ? addr_i : fetch_addr_q));
	assign instr_addr_w_aligned = {instr_addr[31:2], 2'b00};
	genvar _gv_i_32;
	generate
		for (_gv_i_32 = 0; _gv_i_32 < NUM_REQS; _gv_i_32 = _gv_i_32 + 1) begin : g_outstanding_reqs
			localparam i = _gv_i_32;
			if (i == 0) begin : g_req0
				assign rdata_outstanding_n[i] = (valid_req & instr_gnt_i) | rdata_outstanding_q[i];
				assign branch_discard_n[i] = (((valid_req & instr_gnt_i) & discard_req_d) | (branch_i & rdata_outstanding_q[i])) | branch_discard_q[i];
			end
			else begin : g_reqtop
				assign rdata_outstanding_n[i] = ((valid_req & instr_gnt_i) & rdata_outstanding_q[i - 1]) | rdata_outstanding_q[i];
				assign branch_discard_n[i] = ((((valid_req & instr_gnt_i) & discard_req_d) & rdata_outstanding_q[i - 1]) | (branch_i & rdata_outstanding_q[i])) | branch_discard_q[i];
			end
		end
	endgenerate
	assign rdata_outstanding_s = (instr_rvalid_i ? {1'b0, rdata_outstanding_n[1:1]} : rdata_outstanding_n);
	assign branch_discard_s = (instr_rvalid_i ? {1'b0, branch_discard_n[1:1]} : branch_discard_n);
	assign fifo_valid = instr_rvalid_i & ~branch_discard_q[0];
	assign fifo_addr = addr_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			valid_req_q <= 1'b0;
			discard_req_q <= 1'b0;
			rdata_outstanding_q <= 'b0;
			branch_discard_q <= 'b0;
		end
		else begin
			valid_req_q <= valid_req_d;
			discard_req_q <= discard_req_d;
			rdata_outstanding_q <= rdata_outstanding_s;
			branch_discard_q <= branch_discard_s;
		end
	assign instr_req_o = valid_req;
	assign instr_addr_o = instr_addr_w_aligned;
endmodule
module ibex_register_file_ff (
	clk_i,
	rst_ni,
	test_en_i,
	dummy_instr_id_i,
	dummy_instr_wb_i,
	raddr_a_i,
	rdata_a_o,
	raddr_b_i,
	rdata_b_o,
	waddr_a_i,
	wdata_a_i,
	we_a_i,
	err_o
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] DummyInstructions = 0;
	parameter [0:0] WrenCheck = 0;
	parameter [0:0] RdataMuxCheck = 0;
	parameter [DataWidth - 1:0] WordZeroVal = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire dummy_instr_id_i;
	input wire dummy_instr_wb_i;
	input wire [4:0] raddr_a_i;
	output wire [DataWidth - 1:0] rdata_a_o;
	input wire [4:0] raddr_b_i;
	output wire [DataWidth - 1:0] rdata_b_o;
	input wire [4:0] waddr_a_i;
	input wire [DataWidth - 1:0] wdata_a_i;
	input wire we_a_i;
	output wire err_o;
	localparam [31:0] ADDR_WIDTH = (RV32E ? 4 : 5);
	localparam [31:0] NUM_WORDS = 2 ** ADDR_WIDTH;
	wire [(NUM_WORDS * DataWidth) - 1:0] rf_reg;
	reg [NUM_WORDS - 1:0] we_a_dec;
	wire oh_raddr_a_err;
	wire oh_raddr_b_err;
	wire oh_we_err;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(*) begin : we_a_decoder
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < NUM_WORDS; i = i + 1)
				we_a_dec[i] = (waddr_a_i == sv2v_cast_5(i) ? we_a_i : 1'b0);
		end
	end
	generate
		if (WrenCheck) begin : gen_wren_check
			wire [NUM_WORDS - 1:0] we_a_dec_buf;
			prim_buf #(.Width(NUM_WORDS)) u_prim_buf(
				.in_i(we_a_dec),
				.out_o(we_a_dec_buf)
			);
			prim_onehot_check #(
				.AddrWidth(ADDR_WIDTH),
				.AddrCheck(1),
				.EnableCheck(1)
			) u_prim_onehot_check(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.oh_i(we_a_dec_buf),
				.addr_i(waddr_a_i),
				.en_i(we_a_i),
				.err_o(oh_we_err)
			);
		end
		else begin : gen_no_wren_check
			wire unused_strobe;
			assign unused_strobe = we_a_dec[0];
			assign oh_we_err = 1'b0;
		end
	endgenerate
	genvar _gv_i_33;
	generate
		for (_gv_i_33 = 1; _gv_i_33 < NUM_WORDS; _gv_i_33 = _gv_i_33 + 1) begin : g_rf_flops
			localparam i = _gv_i_33;
			reg [DataWidth - 1:0] rf_reg_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					rf_reg_q <= WordZeroVal;
				else if (we_a_dec[i])
					rf_reg_q <= wdata_a_i;
			assign rf_reg[((NUM_WORDS - 1) - i) * DataWidth+:DataWidth] = rf_reg_q;
		end
		if (DummyInstructions) begin : g_dummy_r0
			wire we_r0_dummy;
			reg [DataWidth - 1:0] rf_r0_q;
			assign we_r0_dummy = we_a_i & dummy_instr_wb_i;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					rf_r0_q <= WordZeroVal;
				else if (we_r0_dummy)
					rf_r0_q <= wdata_a_i;
			assign rf_reg[(NUM_WORDS - 1) * DataWidth+:DataWidth] = (dummy_instr_id_i ? rf_r0_q : WordZeroVal);
		end
		else begin : g_normal_r0
			wire unused_dummy_instr;
			assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
			assign rf_reg[(NUM_WORDS - 1) * DataWidth+:DataWidth] = WordZeroVal;
		end
		if (RdataMuxCheck) begin : gen_rdata_mux_check
			wire [NUM_WORDS - 1:0] raddr_onehot_a;
			wire [NUM_WORDS - 1:0] raddr_onehot_b;
			wire [NUM_WORDS - 1:0] raddr_onehot_a_buf;
			wire [NUM_WORDS - 1:0] raddr_onehot_b_buf;
			prim_onehot_enc #(.OneHotWidth(NUM_WORDS)) u_prim_onehot_enc_raddr_a(
				.in_i(raddr_a_i),
				.en_i(1'b1),
				.out_o(raddr_onehot_a)
			);
			prim_onehot_enc #(.OneHotWidth(NUM_WORDS)) u_prim_onehot_enc_raddr_b(
				.in_i(raddr_b_i),
				.en_i(1'b1),
				.out_o(raddr_onehot_b)
			);
			prim_buf #(.Width(NUM_WORDS)) u_prim_buf_raddr_a(
				.in_i(raddr_onehot_a),
				.out_o(raddr_onehot_a_buf)
			);
			prim_buf #(.Width(NUM_WORDS)) u_prim_buf_raddr_b(
				.in_i(raddr_onehot_b),
				.out_o(raddr_onehot_b_buf)
			);
			prim_onehot_check #(
				.AddrWidth(ADDR_WIDTH),
				.OneHotWidth(NUM_WORDS),
				.AddrCheck(1),
				.EnableCheck(1)
			) u_prim_onehot_check_raddr_a(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.oh_i(raddr_onehot_a_buf),
				.addr_i(raddr_a_i),
				.en_i(1'b1),
				.err_o(oh_raddr_a_err)
			);
			prim_onehot_check #(
				.AddrWidth(ADDR_WIDTH),
				.OneHotWidth(NUM_WORDS),
				.AddrCheck(1),
				.EnableCheck(1)
			) u_prim_onehot_check_raddr_b(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.oh_i(raddr_onehot_b_buf),
				.addr_i(raddr_b_i),
				.en_i(1'b1),
				.err_o(oh_raddr_b_err)
			);
			prim_onehot_mux #(
				.Width(DataWidth),
				.Inputs(NUM_WORDS)
			) u_rdata_a_mux(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.in_i(rf_reg),
				.sel_i(raddr_onehot_a),
				.out_o(rdata_a_o)
			);
			prim_onehot_mux #(
				.Width(DataWidth),
				.Inputs(NUM_WORDS)
			) u_rdata_b_mux(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.in_i(rf_reg),
				.sel_i(raddr_onehot_b),
				.out_o(rdata_b_o)
			);
		end
		else begin : gen_no_rdata_mux_check
			assign rdata_a_o = rf_reg[((NUM_WORDS - 1) - raddr_a_i) * DataWidth+:DataWidth];
			assign rdata_b_o = rf_reg[((NUM_WORDS - 1) - raddr_b_i) * DataWidth+:DataWidth];
			assign oh_raddr_a_err = 1'b0;
			assign oh_raddr_b_err = 1'b0;
		end
	endgenerate
	assign err_o = (oh_raddr_a_err || oh_raddr_b_err) || oh_we_err;
	wire unused_test_en;
	assign unused_test_en = test_en_i;
	initial _sv2v_0 = 0;
endmodule
module ibex_top (
	clk_i,
	rst_ni,
	test_en_i,
	ram_cfg_i,
	hart_id_i,
	boot_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	instr_rdata_intg_i,
	instr_err_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_wdata_intg_o,
	data_rdata_i,
	data_rdata_intg_i,
	data_err_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	scramble_key_valid_i,
	scramble_key_i,
	scramble_nonce_i,
	scramble_req_o,
	debug_req_i,
	crash_dump_o,
	double_fault_seen_o,
	fetch_enable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_sleep_o,
	scan_rst_ni
);
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter integer RegFile = 32'sd0;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] ICacheScramble = 1'b0;
	parameter [31:0] ICacheScrNumPrinceRoundsHalf = 2;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	localparam [31:0] ibex_pkg_SCRAMBLE_KEY_W = 128;
	localparam [127:0] ibex_pkg_RndCnstIbexKeyDefault = 128'h14e8cecae3040d5e12286bb3cc113298;
	parameter [127:0] RndCnstIbexKey = ibex_pkg_RndCnstIbexKeyDefault;
	localparam [31:0] ibex_pkg_SCRAMBLE_NONCE_W = 64;
	localparam [63:0] ibex_pkg_RndCnstIbexNonceDefault = 64'hf79780bc735f3843;
	parameter [63:0] RndCnstIbexNonce = ibex_pkg_RndCnstIbexNonceDefault;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire [9:0] ram_cfg_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire [6:0] instr_rdata_intg_i;
	input wire instr_err_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	output wire [6:0] data_wdata_intg_o;
	input wire [31:0] data_rdata_i;
	input wire [6:0] data_rdata_intg_i;
	input wire data_err_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	input wire scramble_key_valid_i;
	input wire [127:0] scramble_key_i;
	input wire [63:0] scramble_nonce_i;
	output wire scramble_req_o;
	input wire debug_req_i;
	output wire [159:0] crash_dump_o;
	output wire double_fault_seen_o;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] fetch_enable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	output wire core_sleep_o;
	input wire scan_rst_ni;
	localparam [0:0] Lockstep = SecureIbex;
	localparam [0:0] ResetAll = Lockstep;
	localparam [0:0] DummyInstructions = SecureIbex;
	localparam [0:0] RegFileECC = SecureIbex;
	localparam [0:0] RegFileWrenCheck = SecureIbex;
	localparam [0:0] RegFileRdataMuxCheck = SecureIbex;
	localparam [31:0] RegFileDataWidth = (RegFileECC ? 39 : 32);
	localparam [0:0] MemECC = SecureIbex;
	localparam [31:0] MemDataWidth = (MemECC ? 39 : 32);
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	localparam [31:0] BusSizeECC = (ICacheECC ? 39 : ibex_pkg_BUS_SIZE);
	localparam [31:0] ibex_pkg_BUS_BYTES = 4;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_LINE_BEATS = ibex_pkg_IC_LINE_BYTES / ibex_pkg_BUS_BYTES;
	localparam [31:0] LineSizeECC = BusSizeECC * ibex_pkg_IC_LINE_BEATS;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	localparam [31:0] TagSizeECC = (ICacheECC ? ibex_pkg_IC_TAG_SIZE + 6 : ibex_pkg_IC_TAG_SIZE);
	localparam [31:0] NumAddrScrRounds = (ICacheScramble ? 2 : 0);
	wire clk;
	wire [3:0] core_busy_d;
	reg [3:0] core_busy_q;
	wire clock_en;
	wire irq_pending;
	wire dummy_instr_id;
	wire dummy_instr_wb;
	wire [4:0] rf_raddr_a;
	wire [4:0] rf_raddr_b;
	wire [4:0] rf_waddr_wb;
	wire rf_we_wb;
	wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc;
	wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc;
	wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_buf;
	wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc;
	wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_buf;
	wire [MemDataWidth - 1:0] data_wdata_core;
	wire [MemDataWidth - 1:0] data_rdata_core;
	wire [MemDataWidth - 1:0] instr_rdata_core;
	wire [1:0] ic_tag_req;
	wire ic_tag_write;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr;
	wire [TagSizeECC - 1:0] ic_tag_wdata;
	wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata;
	wire [1:0] ic_data_req;
	wire ic_data_write;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr;
	wire [LineSizeECC - 1:0] ic_data_wdata;
	wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata;
	wire ic_scr_key_req;
	wire core_alert_major_internal;
	wire core_alert_major_bus;
	wire core_alert_minor;
	wire lockstep_alert_major_internal;
	wire lockstep_alert_major_bus;
	wire lockstep_alert_minor;
	reg [127:0] scramble_key_q;
	reg [63:0] scramble_nonce_q;
	wire scramble_key_valid_d;
	reg scramble_key_valid_q;
	wire scramble_req_d;
	reg scramble_req_q;
	wire [3:0] fetch_enable_buf;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	generate
		if (SecureIbex) begin : g_clock_en_secure
			prim_flop #(
				.Width(ibex_pkg_IbexMuBiWidth),
				.ResetValue(ibex_pkg_IbexMuBiOff)
			) u_prim_core_busy_flop(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.d_i(core_busy_d),
				.q_o(core_busy_q)
			);
			assign clock_en = (((core_busy_q != ibex_pkg_IbexMuBiOff) | debug_req_i) | irq_pending) | irq_nm_i;
		end
		else begin : g_clock_en_non_secure
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					core_busy_q <= ibex_pkg_IbexMuBiOff;
				else
					core_busy_q <= core_busy_d;
			assign clock_en = ((core_busy_q[0] | debug_req_i) | irq_pending) | irq_nm_i;
			wire unused_core_busy;
			assign unused_core_busy = ^core_busy_q[3:1];
		end
	endgenerate
	assign core_sleep_o = ~clock_en;
	assign clk = clk_i;
	prim_buf #(.Width(ibex_pkg_IbexMuBiWidth)) u_fetch_enable_buf(
		.in_i(fetch_enable_i),
		.out_o(fetch_enable_buf)
	);
	prim_buf #(.Width(RegFileDataWidth)) u_rf_rdata_a_ecc_buf(
		.in_i(rf_rdata_a_ecc),
		.out_o(rf_rdata_a_ecc_buf)
	);
	prim_buf #(.Width(RegFileDataWidth)) u_rf_rdata_b_ecc_buf(
		.in_i(rf_rdata_b_ecc),
		.out_o(rf_rdata_b_ecc_buf)
	);
	assign data_rdata_core[31:0] = data_rdata_i;
	assign instr_rdata_core[31:0] = instr_rdata_i;
	generate
		if (MemECC) begin : gen_mem_rdata_ecc
			assign data_rdata_core[38:32] = data_rdata_intg_i;
			assign instr_rdata_core[38:32] = instr_rdata_intg_i;
		end
		else begin : gen_non_mem_rdata_ecc
			wire unused_intg;
			assign unused_intg = ^{instr_rdata_intg_i, data_rdata_intg_i};
		end
	endgenerate
	ibex_core #(
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.ICache(ICache),
		.ICacheECC(ICacheECC),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.BranchPredictor(BranchPredictor),
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.WritebackStage(WritebackStage),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.SecureIbex(SecureIbex),
		.DummyInstructions(DummyInstructions),
		.RegFileECC(RegFileECC),
		.RegFileDataWidth(RegFileDataWidth),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.DmBaseAddr(DmBaseAddr),
		.DmAddrMask(DmAddrMask),
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr)
	) u_ibex_core(
		.clk_i(clk),
		.rst_ni(rst_ni),
		.hart_id_i(hart_id_i),
		.boot_addr_i(boot_addr_i),
		.instr_req_o(instr_req_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_addr_o(instr_addr_o),
		.instr_rdata_i(instr_rdata_core),
		.instr_err_i(instr_err_i),
		.data_req_o(data_req_o),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_addr_o(data_addr_o),
		.data_wdata_o(data_wdata_core),
		.data_rdata_i(data_rdata_core),
		.data_err_i(data_err_i),
		.dummy_instr_id_o(dummy_instr_id),
		.dummy_instr_wb_o(dummy_instr_wb),
		.rf_raddr_a_o(rf_raddr_a),
		.rf_raddr_b_o(rf_raddr_b),
		.rf_waddr_wb_o(rf_waddr_wb),
		.rf_we_wb_o(rf_we_wb),
		.rf_wdata_wb_ecc_o(rf_wdata_wb_ecc),
		.rf_rdata_a_ecc_i(rf_rdata_a_ecc_buf),
		.rf_rdata_b_ecc_i(rf_rdata_b_ecc_buf),
		.ic_tag_req_o(ic_tag_req),
		.ic_tag_write_o(ic_tag_write),
		.ic_tag_addr_o(ic_tag_addr),
		.ic_tag_wdata_o(ic_tag_wdata),
		.ic_tag_rdata_i(ic_tag_rdata),
		.ic_data_req_o(ic_data_req),
		.ic_data_write_o(ic_data_write),
		.ic_data_addr_o(ic_data_addr),
		.ic_data_wdata_o(ic_data_wdata),
		.ic_data_rdata_i(ic_data_rdata),
		.ic_scr_key_valid_i(scramble_key_valid_q),
		.ic_scr_key_req_o(ic_scr_key_req),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.irq_nm_i(irq_nm_i),
		.irq_pending_o(irq_pending),
		.debug_req_i(debug_req_i),
		.crash_dump_o(crash_dump_o),
		.double_fault_seen_o(double_fault_seen_o),
		.fetch_enable_i(fetch_enable_buf),
		.alert_minor_o(core_alert_minor),
		.alert_major_internal_o(core_alert_major_internal),
		.alert_major_bus_o(core_alert_major_bus),
		.core_busy_o(core_busy_d)
	);
	wire rf_alert_major_internal;
	localparam [38:0] prim_secded_pkg_SecdedInv3932ZeroWord = 39'h2a00000000;
	function automatic [RegFileDataWidth - 1:0] sv2v_cast_0BB25;
		input reg [RegFileDataWidth - 1:0] inp;
		sv2v_cast_0BB25 = inp;
	endfunction
	generate
		if (RegFile == 32'sd0) begin : gen_regfile_ff
			ibex_register_file_ff #(
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WrenCheck(RegFileWrenCheck),
				.RdataMuxCheck(RegFileRdataMuxCheck),
				.WordZeroVal(sv2v_cast_0BB25(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a_ecc),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b_ecc),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb_ecc),
				.we_a_i(rf_we_wb),
				.err_o(rf_alert_major_internal)
			);
		end
		else if (RegFile == 32'sd1) begin : gen_regfile_fpga
			ibex_register_file_fpga #(
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WrenCheck(RegFileWrenCheck),
				.RdataMuxCheck(RegFileRdataMuxCheck),
				.WordZeroVal(sv2v_cast_0BB25(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a_ecc),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b_ecc),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb_ecc),
				.we_a_i(rf_we_wb),
				.err_o(rf_alert_major_internal)
			);
		end
		else if (RegFile == 32'sd2) begin : gen_regfile_latch
			ibex_register_file_latch #(
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WrenCheck(RegFileWrenCheck),
				.RdataMuxCheck(RegFileRdataMuxCheck),
				.WordZeroVal(sv2v_cast_0BB25(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a_ecc),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b_ecc),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb_ecc),
				.we_a_i(rf_we_wb),
				.err_o(rf_alert_major_internal)
			);
		end
		if (ICacheScramble) begin : gen_scramble
			assign scramble_key_valid_d = (scramble_req_q ? scramble_key_valid_i : (ic_scr_key_req ? 1'b0 : scramble_key_valid_q));
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					scramble_key_q <= RndCnstIbexKey;
					scramble_nonce_q <= RndCnstIbexNonce;
				end
				else if (scramble_key_valid_i) begin
					scramble_key_q <= scramble_key_i;
					scramble_nonce_q <= scramble_nonce_i;
				end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					scramble_key_valid_q <= 1'b1;
					scramble_req_q <= 1'sb0;
				end
				else begin
					scramble_key_valid_q <= scramble_key_valid_d;
					scramble_req_q <= scramble_req_d;
				end
			assign scramble_req_d = (scramble_req_q ? ~scramble_key_valid_i : ic_scr_key_req);
			assign scramble_req_o = scramble_req_q;
		end
		else begin : gen_noscramble
			reg unused_scramble_inputs = (((((((scramble_key_valid_i & |scramble_key_i) & |RndCnstIbexKey) & |scramble_nonce_i) & |RndCnstIbexNonce) & scramble_req_q) & ic_scr_key_req) & scramble_key_valid_d) & scramble_req_d;
			assign scramble_req_d = 1'b0;
			wire [1:1] sv2v_tmp_2E9FB;
			assign sv2v_tmp_2E9FB = 1'b0;
			always @(*) scramble_req_q = sv2v_tmp_2E9FB;
			assign scramble_req_o = 1'b0;
			wire [128:1] sv2v_tmp_E270A;
			assign sv2v_tmp_E270A = 1'sb0;
			always @(*) scramble_key_q = sv2v_tmp_E270A;
			wire [64:1] sv2v_tmp_F758A;
			assign sv2v_tmp_F758A = 1'sb0;
			always @(*) scramble_nonce_q = sv2v_tmp_F758A;
			wire [1:1] sv2v_tmp_604FC;
			assign sv2v_tmp_604FC = 1'b1;
			always @(*) scramble_key_valid_q = sv2v_tmp_604FC;
			assign scramble_key_valid_d = 1'b1;
		end
	endgenerate
	wire [1:0] icache_tag_alert;
	wire [1:0] icache_data_alert;
	function automatic [TagSizeECC - 1:0] sv2v_cast_0CBAD;
		input reg [TagSizeECC - 1:0] inp;
		sv2v_cast_0CBAD = inp;
	endfunction
	function automatic [LineSizeECC - 1:0] sv2v_cast_033B0;
		input reg [LineSizeECC - 1:0] inp;
		sv2v_cast_033B0 = inp;
	endfunction
	generate
		if (ICache) begin : gen_rams
			genvar _gv_way_4;
			for (_gv_way_4 = 0; _gv_way_4 < ibex_pkg_IC_NUM_WAYS; _gv_way_4 = _gv_way_4 + 1) begin : gen_rams_inner
				localparam way = _gv_way_4;
				if (ICacheScramble) begin : gen_scramble_rams
					prim_ram_1p_scr #(
						.Width(TagSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(TagSizeECC),
						.EnableParity(0),
						.NumPrinceRoundsHalf(ICacheScrNumPrinceRoundsHalf),
						.NumAddrScrRounds(NumAddrScrRounds)
					) tag_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.key_valid_i(scramble_key_valid_q),
						.key_i(scramble_key_q),
						.nonce_i(scramble_nonce_q),
						.req_i(ic_tag_req[way]),
						.gnt_o(),
						.write_i(ic_tag_write),
						.addr_i(ic_tag_addr),
						.wdata_i(ic_tag_wdata),
						.wmask_i({TagSizeECC {1'b1}}),
						.intg_error_i(1'b0),
						.rdata_o(ic_tag_rdata[(1 - way) * TagSizeECC+:TagSizeECC]),
						.rvalid_o(),
						.raddr_o(),
						.rerror_o(),
						.cfg_i(ram_cfg_i),
						.wr_collision_o(),
						.write_pending_o(),
						.alert_o(icache_tag_alert[way])
					);
					prim_ram_1p_scr #(
						.Width(LineSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(LineSizeECC),
						.ReplicateKeyStream(1),
						.EnableParity(0),
						.NumPrinceRoundsHalf(ICacheScrNumPrinceRoundsHalf),
						.NumAddrScrRounds(NumAddrScrRounds)
					) data_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.key_valid_i(scramble_key_valid_q),
						.key_i(scramble_key_q),
						.nonce_i(scramble_nonce_q),
						.req_i(ic_data_req[way]),
						.gnt_o(),
						.write_i(ic_data_write),
						.addr_i(ic_data_addr),
						.wdata_i(ic_data_wdata),
						.wmask_i({LineSizeECC {1'b1}}),
						.intg_error_i(1'b0),
						.rdata_o(ic_data_rdata[(1 - way) * LineSizeECC+:LineSizeECC]),
						.rvalid_o(),
						.raddr_o(),
						.rerror_o(),
						.cfg_i(ram_cfg_i),
						.wr_collision_o(),
						.write_pending_o(),
						.alert_o(icache_data_alert[way])
					);
				end
				else begin : gen_noscramble_rams
					prim_ram_1p #(
						.Width(TagSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(TagSizeECC)
					) tag_bank(
						.clk_i(clk_i),
						.req_i(ic_tag_req[way]),
						.write_i(ic_tag_write),
						.addr_i(ic_tag_addr),
						.wdata_i(ic_tag_wdata),
						.wmask_i({TagSizeECC {1'b1}}),
						.rdata_o(ic_tag_rdata[(1 - way) * TagSizeECC+:TagSizeECC]),
						.cfg_i(ram_cfg_i)
					);
					prim_ram_1p #(
						.Width(LineSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(LineSizeECC)
					) data_bank(
						.clk_i(clk_i),
						.req_i(ic_data_req[way]),
						.write_i(ic_data_write),
						.addr_i(ic_data_addr),
						.wdata_i(ic_data_wdata),
						.wmask_i({LineSizeECC {1'b1}}),
						.rdata_o(ic_data_rdata[(1 - way) * LineSizeECC+:LineSizeECC]),
						.cfg_i(ram_cfg_i)
					);
					assign icache_tag_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
					assign icache_data_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
				end
			end
		end
		else begin : gen_norams
			wire [9:0] unused_ram_cfg;
			wire unused_ram_inputs;
			assign unused_ram_cfg = ram_cfg_i;
			assign unused_ram_inputs = ((((((((((((|ic_tag_req & ic_tag_write) & |ic_tag_addr) & |ic_tag_wdata) & |ic_data_req) & ic_data_write) & |ic_data_addr) & |ic_data_wdata) & |scramble_key_q) & |scramble_nonce_q) & scramble_key_valid_q) & scramble_key_valid_d) & |scramble_nonce_q) & |NumAddrScrRounds;
			assign ic_tag_rdata = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_0CBAD('b0)}};
			assign ic_data_rdata = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_033B0('b0)}};
			assign icache_tag_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
			assign icache_data_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
		end
	endgenerate
	assign data_wdata_o = data_wdata_core[31:0];
	generate
		if (MemECC) begin : gen_mem_wdata_ecc
			prim_buf #(.Width(7)) u_prim_buf_data_wdata_intg(
				.in_i(data_wdata_core[38:32]),
				.out_o(data_wdata_intg_o)
			);
		end
		else begin : gen_no_mem_ecc
			assign data_wdata_intg_o = 1'sb0;
		end
		if (Lockstep) begin : gen_lockstep
			localparam signed [31:0] NumBufferBits = ((((((((((((((((((99 + MemDataWidth) + 41) + MemDataWidth) + MemDataWidth) + 19) + RegFileDataWidth) + RegFileDataWidth) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 184) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth;
			wire [NumBufferBits - 1:0] buf_in;
			wire [NumBufferBits - 1:0] buf_out;
			wire [31:0] hart_id_local;
			wire [31:0] boot_addr_local;
			wire instr_req_local;
			wire instr_gnt_local;
			wire instr_rvalid_local;
			wire [31:0] instr_addr_local;
			wire [MemDataWidth - 1:0] instr_rdata_local;
			wire instr_err_local;
			wire data_req_local;
			wire data_gnt_local;
			wire data_rvalid_local;
			wire data_we_local;
			wire [3:0] data_be_local;
			wire [31:0] data_addr_local;
			wire [MemDataWidth - 1:0] data_wdata_local;
			wire [MemDataWidth - 1:0] data_rdata_local;
			wire data_err_local;
			wire dummy_instr_id_local;
			wire dummy_instr_wb_local;
			wire [4:0] rf_raddr_a_local;
			wire [4:0] rf_raddr_b_local;
			wire [4:0] rf_waddr_wb_local;
			wire rf_we_wb_local;
			wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc_local;
			wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_local;
			wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_local;
			wire [1:0] ic_tag_req_local;
			wire ic_tag_write_local;
			wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_local;
			wire [TagSizeECC - 1:0] ic_tag_wdata_local;
			wire [1:0] ic_data_req_local;
			wire ic_data_write_local;
			wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_local;
			wire [LineSizeECC - 1:0] ic_data_wdata_local;
			wire scramble_key_valid_local;
			wire ic_scr_key_req_local;
			wire irq_software_local;
			wire irq_timer_local;
			wire irq_external_local;
			wire [14:0] irq_fast_local;
			wire irq_nm_local;
			wire irq_pending_local;
			wire debug_req_local;
			wire [159:0] crash_dump_local;
			wire double_fault_seen_local;
			wire [3:0] fetch_enable_local;
			wire [3:0] core_busy_local;
			assign buf_in = {hart_id_i, boot_addr_i, instr_req_o, instr_gnt_i, instr_rvalid_i, instr_addr_o, instr_rdata_core, instr_err_i, data_req_o, data_gnt_i, data_rvalid_i, data_we_o, data_be_o, data_addr_o, data_wdata_core, data_rdata_core, data_err_i, dummy_instr_id, dummy_instr_wb, rf_raddr_a, rf_raddr_b, rf_waddr_wb, rf_we_wb, rf_wdata_wb_ecc, rf_rdata_a_ecc, rf_rdata_b_ecc, ic_tag_req, ic_tag_write, ic_tag_addr, ic_tag_wdata, ic_data_req, ic_data_write, ic_data_addr, ic_data_wdata, scramble_key_valid_q, ic_scr_key_req, irq_software_i, irq_timer_i, irq_external_i, irq_fast_i, irq_nm_i, irq_pending, debug_req_i, crash_dump_o, double_fault_seen_o, fetch_enable_i, core_busy_d};
			assign {hart_id_local, boot_addr_local, instr_req_local, instr_gnt_local, instr_rvalid_local, instr_addr_local, instr_rdata_local, instr_err_local, data_req_local, data_gnt_local, data_rvalid_local, data_we_local, data_be_local, data_addr_local, data_wdata_local, data_rdata_local, data_err_local, dummy_instr_id_local, dummy_instr_wb_local, rf_raddr_a_local, rf_raddr_b_local, rf_waddr_wb_local, rf_we_wb_local, rf_wdata_wb_ecc_local, rf_rdata_a_ecc_local, rf_rdata_b_ecc_local, ic_tag_req_local, ic_tag_write_local, ic_tag_addr_local, ic_tag_wdata_local, ic_data_req_local, ic_data_write_local, ic_data_addr_local, ic_data_wdata_local, scramble_key_valid_local, ic_scr_key_req_local, irq_software_local, irq_timer_local, irq_external_local, irq_fast_local, irq_nm_local, irq_pending_local, debug_req_local, crash_dump_local, double_fault_seen_local, fetch_enable_local, core_busy_local} = buf_out;
			prim_buf #(.Width(NumBufferBits)) u_signals_prim_buf(
				.in_i(buf_in),
				.out_o(buf_out)
			);
			wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_local;
			wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_local;
			genvar _gv_k_2;
			for (_gv_k_2 = 0; _gv_k_2 < ibex_pkg_IC_NUM_WAYS; _gv_k_2 = _gv_k_2 + 1) begin : gen_ways
				localparam k = _gv_k_2;
				prim_buf #(.Width(TagSizeECC)) u_tag_prim_buf(
					.in_i(ic_tag_rdata[(1 - k) * TagSizeECC+:TagSizeECC]),
					.out_o(ic_tag_rdata_local[(1 - k) * TagSizeECC+:TagSizeECC])
				);
				prim_buf #(.Width(LineSizeECC)) u_data_prim_buf(
					.in_i(ic_data_rdata[(1 - k) * LineSizeECC+:LineSizeECC]),
					.out_o(ic_data_rdata_local[(1 - k) * LineSizeECC+:LineSizeECC])
				);
			end
			wire lockstep_alert_minor_local;
			wire lockstep_alert_major_internal_local;
			wire lockstep_alert_major_bus_local;
			ibex_lockstep #(
				.PMPEnable(PMPEnable),
				.PMPGranularity(PMPGranularity),
				.PMPNumRegions(PMPNumRegions),
				.PMPRstCfg(PMPRstCfg),
				.PMPRstAddr(PMPRstAddr),
				.PMPRstMsecCfg(PMPRstMsecCfg),
				.MHPMCounterNum(MHPMCounterNum),
				.MHPMCounterWidth(MHPMCounterWidth),
				.RV32E(RV32E),
				.RV32M(RV32M),
				.RV32B(RV32B),
				.BranchTargetALU(BranchTargetALU),
				.ICache(ICache),
				.ICacheECC(ICacheECC),
				.BusSizeECC(BusSizeECC),
				.TagSizeECC(TagSizeECC),
				.LineSizeECC(LineSizeECC),
				.BranchPredictor(BranchPredictor),
				.DbgTriggerEn(DbgTriggerEn),
				.DbgHwBreakNum(DbgHwBreakNum),
				.WritebackStage(WritebackStage),
				.ResetAll(ResetAll),
				.RndCnstLfsrSeed(RndCnstLfsrSeed),
				.RndCnstLfsrPerm(RndCnstLfsrPerm),
				.SecureIbex(SecureIbex),
				.DummyInstructions(DummyInstructions),
				.RegFileECC(RegFileECC),
				.RegFileDataWidth(RegFileDataWidth),
				.MemECC(MemECC),
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.DmHaltAddr(DmHaltAddr),
				.DmExceptionAddr(DmExceptionAddr)
			) u_ibex_lockstep(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.hart_id_i(hart_id_local),
				.boot_addr_i(boot_addr_local),
				.instr_req_i(instr_req_local),
				.instr_gnt_i(instr_gnt_local),
				.instr_rvalid_i(instr_rvalid_local),
				.instr_addr_i(instr_addr_local),
				.instr_rdata_i(instr_rdata_local),
				.instr_err_i(instr_err_local),
				.data_req_i(data_req_local),
				.data_gnt_i(data_gnt_local),
				.data_rvalid_i(data_rvalid_local),
				.data_we_i(data_we_local),
				.data_be_i(data_be_local),
				.data_addr_i(data_addr_local),
				.data_wdata_i(data_wdata_local),
				.data_rdata_i(data_rdata_local),
				.data_err_i(data_err_local),
				.dummy_instr_id_i(dummy_instr_id_local),
				.dummy_instr_wb_i(dummy_instr_wb_local),
				.rf_raddr_a_i(rf_raddr_a_local),
				.rf_raddr_b_i(rf_raddr_b_local),
				.rf_waddr_wb_i(rf_waddr_wb_local),
				.rf_we_wb_i(rf_we_wb_local),
				.rf_wdata_wb_ecc_i(rf_wdata_wb_ecc_local),
				.rf_rdata_a_ecc_i(rf_rdata_a_ecc_local),
				.rf_rdata_b_ecc_i(rf_rdata_b_ecc_local),
				.ic_tag_req_i(ic_tag_req_local),
				.ic_tag_write_i(ic_tag_write_local),
				.ic_tag_addr_i(ic_tag_addr_local),
				.ic_tag_wdata_i(ic_tag_wdata_local),
				.ic_tag_rdata_i(ic_tag_rdata_local),
				.ic_data_req_i(ic_data_req_local),
				.ic_data_write_i(ic_data_write_local),
				.ic_data_addr_i(ic_data_addr_local),
				.ic_data_wdata_i(ic_data_wdata_local),
				.ic_data_rdata_i(ic_data_rdata_local),
				.ic_scr_key_valid_i(scramble_key_valid_local),
				.ic_scr_key_req_i(ic_scr_key_req_local),
				.irq_software_i(irq_software_local),
				.irq_timer_i(irq_timer_local),
				.irq_external_i(irq_external_local),
				.irq_fast_i(irq_fast_local),
				.irq_nm_i(irq_nm_local),
				.irq_pending_i(irq_pending_local),
				.debug_req_i(debug_req_local),
				.crash_dump_i(crash_dump_local),
				.double_fault_seen_i(double_fault_seen_local),
				.fetch_enable_i(fetch_enable_local),
				.alert_minor_o(lockstep_alert_minor_local),
				.alert_major_internal_o(lockstep_alert_major_internal_local),
				.alert_major_bus_o(lockstep_alert_major_bus_local),
				.core_busy_i(core_busy_local),
				.test_en_i(test_en_i),
				.scan_rst_ni(scan_rst_ni)
			);
			prim_buf u_prim_buf_alert_minor(
				.in_i(lockstep_alert_minor_local),
				.out_o(lockstep_alert_minor)
			);
			prim_buf u_prim_buf_alert_major_internal(
				.in_i(lockstep_alert_major_internal_local),
				.out_o(lockstep_alert_major_internal)
			);
			prim_buf u_prim_buf_alert_major_bus(
				.in_i(lockstep_alert_major_bus_local),
				.out_o(lockstep_alert_major_bus)
			);
		end
		else begin : gen_no_lockstep
			assign lockstep_alert_major_internal = 1'b0;
			assign lockstep_alert_major_bus = 1'b0;
			assign lockstep_alert_minor = 1'b0;
			wire unused_scan;
			assign unused_scan = scan_rst_ni;
		end
	endgenerate
	wire icache_alert_major_internal;
	assign icache_alert_major_internal = |icache_tag_alert | (|icache_data_alert);
	assign alert_major_internal_o = ((core_alert_major_internal | lockstep_alert_major_internal) | rf_alert_major_internal) | icache_alert_major_internal;
	assign alert_major_bus_o = core_alert_major_bus | lockstep_alert_major_bus;
	assign alert_minor_o = core_alert_minor | lockstep_alert_minor;
endmodule
module areset_sync (
	clk_i,
	i_rst_async,
	o_rst_sync
);
	parameter [31:0] NumRegs = 4;
	input wire clk_i;
	input wire i_rst_async;
	output wire o_rst_sync;
	reg [NumRegs - 1:0] synch_regs_q;
	always @(posedge clk_i or negedge i_rst_async)
		if (~i_rst_async)
			synch_regs_q <= 1'sb0;
		else
			synch_regs_q <= {synch_regs_q[NumRegs - 2:0], 1'b1};
	assign o_rst_sync = synch_regs_q[NumRegs - 1];
endmodule
module gpio_top (
	wb_clk_i,
	wb_rst_i_n,
	wb_cyc_i,
	wb_adr_i,
	wb_dat_i,
	wb_sel_i,
	wb_we_i,
	wb_stb_i,
	wb_dat_o,
	wb_ack_o,
	wb_err_o,
	wb_inta_o,
	aux_i,
	ext_pad_i,
	ext_pad_o,
	ext_padoe_o
);
	parameter dw = 32;
	parameter aw = 8;
	parameter gw = 2;
	input wb_clk_i;
	input wb_rst_i_n;
	input wb_cyc_i;
	input [aw - 1:0] wb_adr_i;
	input [dw - 1:0] wb_dat_i;
	input [3:0] wb_sel_i;
	input wb_we_i;
	input wb_stb_i;
	output reg [dw - 1:0] wb_dat_o;
	output reg wb_ack_o;
	output reg wb_err_o;
	output reg wb_inta_o;
	input [gw - 1:0] aux_i;
	input [gw - 1:0] ext_pad_i;
	output wire [gw - 1:0] ext_pad_o;
	output wire [gw - 1:0] ext_padoe_o;
	reg [gw - 1:0] rgpio_in;
	reg [gw - 1:0] rgpio_out;
	reg [gw - 1:0] rgpio_oe;
	reg [gw - 1:0] rgpio_inte;
	reg [gw - 1:0] rgpio_ptrig;
	reg [gw - 1:0] rgpio_aux;
	reg [1:0] rgpio_ctrl;
	reg [gw - 1:0] rgpio_ints;
	wire [gw - 1:0] rgpio_eclk;
	wire [gw - 1:0] rgpio_nec;
	reg [gw - 1:0] sync;
	reg [gw - 1:0] ext_pad_s;
	wire rgpio_out_sel;
	wire rgpio_oe_sel;
	wire rgpio_inte_sel;
	wire rgpio_ptrig_sel;
	wire rgpio_aux_sel;
	wire rgpio_ctrl_sel;
	wire rgpio_ints_sel;
	wire rgpio_eclk_sel;
	wire rgpio_nec_sel;
	wire full_decoding;
	wire [gw - 1:0] in_muxed;
	wire wb_ack;
	wire wb_err;
	wire wb_inta;
	reg [dw - 1:0] wb_dat;
	wire [gw - 1:0] out_pad;
	assign wb_ack = (wb_cyc_i & wb_stb_i) & !wb_err_o;
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			wb_ack_o <= #(1) 1'b0;
		else
			wb_ack_o <= #(1) (wb_ack & ~wb_ack_o) & !wb_err;
	assign wb_err = (wb_cyc_i & wb_stb_i) & (wb_sel_i != 4'b1111);
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			wb_err_o <= #(1) 1'b0;
		else
			wb_err_o <= #(1) wb_err & ~wb_err_o;
	assign full_decoding = 1'b1;
	assign rgpio_out_sel = ((wb_cyc_i & wb_stb_i) & (wb_adr_i[5:2] == 4'h1)) & full_decoding;
	assign rgpio_oe_sel = ((wb_cyc_i & wb_stb_i) & (wb_adr_i[5:2] == 4'h2)) & full_decoding;
	assign rgpio_inte_sel = ((wb_cyc_i & wb_stb_i) & (wb_adr_i[5:2] == 4'h3)) & full_decoding;
	assign rgpio_ptrig_sel = ((wb_cyc_i & wb_stb_i) & (wb_adr_i[5:2] == 4'h4)) & full_decoding;
	assign rgpio_aux_sel = ((wb_cyc_i & wb_stb_i) & (wb_adr_i[5:2] == 4'h5)) & full_decoding;
	assign rgpio_ctrl_sel = ((wb_cyc_i & wb_stb_i) & (wb_adr_i[5:2] == 4'h6)) & full_decoding;
	assign rgpio_ints_sel = ((wb_cyc_i & wb_stb_i) & (wb_adr_i[5:2] == 4'h7)) & full_decoding;
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_ctrl <= #(1) 2'b00;
		else if (rgpio_ctrl_sel && wb_we_i)
			rgpio_ctrl <= #(1) wb_dat_i[1:0];
		else if (rgpio_ctrl[0])
			rgpio_ctrl[1] <= #(1) rgpio_ctrl[1] | wb_inta_o;
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_out <= #(1) {gw {1'b0}};
		else if (rgpio_out_sel && wb_we_i)
			rgpio_out <= #(1) wb_dat_i[gw - 1:0];
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_oe <= #(1) {gw {1'b0}};
		else if (rgpio_oe_sel && wb_we_i)
			rgpio_oe <= #(1) wb_dat_i[gw - 1:0];
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_inte <= #(1) {gw {1'b0}};
		else if (rgpio_inte_sel && wb_we_i)
			rgpio_inte <= #(1) wb_dat_i[gw - 1:0];
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_ptrig <= #(1) {gw {1'b0}};
		else if (rgpio_ptrig_sel && wb_we_i)
			rgpio_ptrig <= #(1) wb_dat_i[gw - 1:0];
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_aux <= #(1) {gw {1'b0}};
		else if (rgpio_aux_sel && wb_we_i)
			rgpio_aux <= #(1) wb_dat_i[gw - 1:0];
	assign rgpio_eclk = 2'h0;
	assign rgpio_nec = 2'h0;
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n) begin
			sync <= #(1) {gw {1'b0}};
			ext_pad_s <= #(1) {gw {1'b0}};
		end
		else begin
			sync <= #(1) ext_pad_i;
			ext_pad_s <= #(1) sync;
		end
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_in <= #(1) {gw {1'b0}};
		else
			rgpio_in <= #(1) in_muxed;
	assign in_muxed = ext_pad_s;
	always @(wb_adr_i or rgpio_in or rgpio_out or rgpio_oe or rgpio_inte or rgpio_ptrig or rgpio_aux or rgpio_ctrl or rgpio_ints or rgpio_eclk or rgpio_nec)
		case (wb_adr_i[5:2])
			4'h1: wb_dat[dw - 1:0] = rgpio_out;
			4'h2: wb_dat[dw - 1:0] = rgpio_oe;
			4'h3: wb_dat[dw - 1:0] = rgpio_inte;
			4'h4: wb_dat[dw - 1:0] = rgpio_ptrig;
			4'h5: wb_dat[dw - 1:0] = rgpio_aux;
			4'h6: begin
				wb_dat[1:0] = rgpio_ctrl;
				wb_dat[dw - 1:2] = {dw - 2 {1'b0}};
			end
			4'h7: wb_dat[dw - 1:0] = rgpio_ints;
			default: wb_dat[dw - 1:0] = rgpio_in;
		endcase
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			wb_dat_o <= #(1) {dw {1'b0}};
		else
			wb_dat_o <= #(1) wb_dat;
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			rgpio_ints <= #(1) {gw {1'b0}};
		else if (rgpio_ints_sel && wb_we_i)
			rgpio_ints <= #(1) wb_dat_i[gw - 1:0];
		else if (rgpio_ctrl[0])
			rgpio_ints <= #(1) rgpio_ints | (((in_muxed ^ rgpio_in) & ~(in_muxed ^ rgpio_ptrig)) & rgpio_inte);
	assign wb_inta = (|rgpio_ints ? rgpio_ctrl[0] : 1'b0);
	always @(posedge wb_clk_i or negedge wb_rst_i_n)
		if (!wb_rst_i_n)
			wb_inta_o <= #(1) 1'b0;
		else
			wb_inta_o <= #(1) wb_inta;
	assign ext_padoe_o = rgpio_oe;
	assign out_pad = (rgpio_out & ~rgpio_aux) | (aux_i & rgpio_aux);
	assign ext_pad_o = out_pad;
endmodule
module i2c_master_top (
	wb_clk_i,
	arst_i,
	wb_adr_i,
	wb_dat_i,
	wb_dat_o,
	wb_we_i,
	wb_stb_i,
	wb_cyc_i,
	wb_ack_o,
	wb_inta_o,
	scl_pad_i,
	scl_pad_o,
	scl_padoen_o,
	sda_pad_i,
	sda_pad_o,
	sda_padoen_o
);
	parameter ARST_LVL = 1'b0;
	parameter BOOT_I2C_PRESCALER = 16'd15;
	input wb_clk_i;
	input arst_i;
	input [2:0] wb_adr_i;
	input [7:0] wb_dat_i;
	output reg [7:0] wb_dat_o;
	input wb_we_i;
	input wb_stb_i;
	input wb_cyc_i;
	output reg wb_ack_o;
	output reg wb_inta_o;
	input scl_pad_i;
	output wire scl_pad_o;
	output wire scl_padoen_o;
	input sda_pad_i;
	output wire sda_pad_o;
	output wire sda_padoen_o;
	reg [15:0] prer;
	reg [7:0] ctr;
	reg [7:0] txr;
	wire [7:0] rxr;
	reg [7:0] cr;
	wire [7:0] sr;
	wire done;
	wire core_en;
	wire ien;
	wire irxack;
	reg rxack;
	reg tip;
	reg irq_flag;
	wire i2c_busy;
	wire i2c_al;
	reg al;
	wire rst_i = arst_i ^ ARST_LVL;
	wire wb_wacc = wb_we_i & wb_ack_o;
	always @(posedge wb_clk_i) wb_ack_o <= #(1) (wb_cyc_i & wb_stb_i) & ~wb_ack_o;
	always @(posedge wb_clk_i)
		case (wb_adr_i)
			3'b000: wb_dat_o <= #(1) prer[7:0];
			3'b001: wb_dat_o <= #(1) prer[15:8];
			3'b010: wb_dat_o <= #(1) ctr;
			3'b011: wb_dat_o <= #(1) rxr;
			3'b100: wb_dat_o <= #(1) sr;
			3'b101: wb_dat_o <= #(1) txr;
			3'b110: wb_dat_o <= #(1) cr;
			3'b111: wb_dat_o <= #(1) 0;
		endcase
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i) begin
			prer <= #(1) BOOT_I2C_PRESCALER;
			ctr <= #(1) 8'h00;
			txr <= #(1) 8'h00;
		end
		else if (wb_wacc)
			case (wb_adr_i)
				3'b000: prer[7:0] <= #(1) wb_dat_i;
				3'b001: prer[15:8] <= #(1) wb_dat_i;
				3'b010: ctr <= #(1) wb_dat_i;
				3'b011: txr <= #(1) wb_dat_i;
				default:
					;
			endcase
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i)
			cr <= #(1) 8'h00;
		else if (wb_wacc) begin
			if (core_en & (wb_adr_i == 3'b100))
				cr <= #(1) wb_dat_i;
		end
		else begin
			if (done | i2c_al)
				cr[7:4] <= #(1) 4'h0;
			cr[2:1] <= #(1) 2'b00;
			cr[0] <= #(1) 1'b0;
		end
	wire sta = cr[7];
	wire sto = cr[6];
	wire rd = cr[5];
	wire wr = cr[4];
	wire ack = cr[3];
	wire iack = cr[0];
	assign core_en = ctr[7];
	assign ien = ctr[6];
	i2c_master_byte_ctrl byte_controller(
		.clk(wb_clk_i),
		.nReset(rst_i),
		.ena(core_en),
		.clk_cnt(prer),
		.start(sta),
		.stop(sto),
		.read(rd),
		.write(wr),
		.ack_in(ack),
		.din(txr),
		.cmd_ack(done),
		.ack_out(irxack),
		.dout(rxr),
		.i2c_busy(i2c_busy),
		.i2c_al(i2c_al),
		.scl_i(scl_pad_i),
		.scl_o(scl_pad_o),
		.scl_oen(scl_padoen_o),
		.sda_i(sda_pad_i),
		.sda_o(sda_pad_o),
		.sda_oen(sda_padoen_o)
	);
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i) begin
			al <= #(1) 1'b0;
			rxack <= #(1) 1'b0;
			tip <= #(1) 1'b0;
			irq_flag <= #(1) 1'b0;
		end
		else begin
			al <= #(1) i2c_al | (al & ~sta);
			rxack <= #(1) irxack;
			tip <= #(1) rd | wr;
			irq_flag <= #(1) ((done | i2c_al) | irq_flag) & ~iack;
		end
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i)
			wb_inta_o <= #(1) 1'b0;
		else
			wb_inta_o <= #(1) irq_flag && ien;
	assign sr[7] = rxack;
	assign sr[6] = i2c_busy;
	assign sr[5] = al;
	assign sr[4:2] = 3'h0;
	assign sr[1] = tip;
	assign sr[0] = irq_flag;
endmodule
module i2c_master_byte_ctrl (
	clk,
	nReset,
	ena,
	clk_cnt,
	start,
	stop,
	read,
	write,
	ack_in,
	din,
	cmd_ack,
	ack_out,
	dout,
	i2c_busy,
	i2c_al,
	scl_i,
	scl_o,
	scl_oen,
	sda_i,
	sda_o,
	sda_oen
);
	input clk;
	input nReset;
	input ena;
	input [15:0] clk_cnt;
	input start;
	input stop;
	input read;
	input write;
	input ack_in;
	input [7:0] din;
	output reg cmd_ack;
	output reg ack_out;
	output wire i2c_busy;
	output wire i2c_al;
	output wire [7:0] dout;
	input scl_i;
	output wire scl_o;
	output wire scl_oen;
	input sda_i;
	output wire sda_o;
	output wire sda_oen;
	parameter [4:0] ST_IDLE = 5'b00000;
	parameter [4:0] ST_START = 5'b00001;
	parameter [4:0] ST_READ = 5'b00010;
	parameter [4:0] ST_WRITE = 5'b00100;
	parameter [4:0] ST_ACK = 5'b01000;
	parameter [4:0] ST_STOP = 5'b10000;
	reg [3:0] core_cmd;
	reg core_txd;
	wire core_ack;
	wire core_rxd;
	reg [7:0] sr;
	reg shift;
	reg ld;
	wire go;
	reg [2:0] dcnt;
	wire cnt_done;
	i2c_master_bit_ctrl bit_controller(
		.clk(clk),
		.nReset(nReset),
		.ena(ena),
		.clk_cnt(clk_cnt),
		.cmd(core_cmd),
		.cmd_ack(core_ack),
		.busy(i2c_busy),
		.al(i2c_al),
		.din(core_txd),
		.dout(core_rxd),
		.scl_i(scl_i),
		.scl_o(scl_o),
		.scl_oen(scl_oen),
		.sda_i(sda_i),
		.sda_o(sda_o),
		.sda_oen(sda_oen)
	);
	assign go = ((read | write) | stop) & ~cmd_ack;
	assign dout = sr;
	always @(posedge clk or negedge nReset)
		if (!nReset)
			sr <= #(1) 8'h00;
		else if (ld)
			sr <= #(1) din;
		else if (shift)
			sr <= #(1) {sr[6:0], core_rxd};
	always @(posedge clk or negedge nReset)
		if (!nReset)
			dcnt <= #(1) 3'h0;
		else if (ld)
			dcnt <= #(1) 3'h7;
		else if (shift)
			dcnt <= #(1) dcnt - 3'h1;
	assign cnt_done = ~(|dcnt);
	reg [4:0] c_state;
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			core_cmd <= #(1) 4'b0000;
			core_txd <= #(1) 1'b0;
			shift <= #(1) 1'b0;
			ld <= #(1) 1'b0;
			cmd_ack <= #(1) 1'b0;
			c_state <= #(1) ST_IDLE;
			ack_out <= #(1) 1'b0;
		end
		else if (i2c_al) begin
			core_cmd <= #(1) 4'b0000;
			core_txd <= #(1) 1'b0;
			shift <= #(1) 1'b0;
			ld <= #(1) 1'b0;
			cmd_ack <= #(1) 1'b0;
			c_state <= #(1) ST_IDLE;
			ack_out <= #(1) 1'b0;
		end
		else begin
			core_txd <= #(1) sr[7];
			shift <= #(1) 1'b0;
			ld <= #(1) 1'b0;
			cmd_ack <= #(1) 1'b0;
			case (c_state)
				ST_IDLE:
					if (go) begin
						if (start) begin
							c_state <= #(1) ST_START;
							core_cmd <= #(1) 4'b0001;
						end
						else if (read) begin
							c_state <= #(1) ST_READ;
							core_cmd <= #(1) 4'b1000;
						end
						else if (write) begin
							c_state <= #(1) ST_WRITE;
							core_cmd <= #(1) 4'b0100;
						end
						else begin
							c_state <= #(1) ST_STOP;
							core_cmd <= #(1) 4'b0010;
						end
						ld <= #(1) 1'b1;
					end
				ST_START:
					if (core_ack) begin
						if (read) begin
							c_state <= #(1) ST_READ;
							core_cmd <= #(1) 4'b1000;
						end
						else begin
							c_state <= #(1) ST_WRITE;
							core_cmd <= #(1) 4'b0100;
						end
						ld <= #(1) 1'b1;
					end
				ST_WRITE:
					if (core_ack) begin
						if (cnt_done) begin
							c_state <= #(1) ST_ACK;
							core_cmd <= #(1) 4'b1000;
						end
						else begin
							c_state <= #(1) ST_WRITE;
							core_cmd <= #(1) 4'b0100;
							shift <= #(1) 1'b1;
						end
					end
				ST_READ:
					if (core_ack) begin
						if (cnt_done) begin
							c_state <= #(1) ST_ACK;
							core_cmd <= #(1) 4'b0100;
						end
						else begin
							c_state <= #(1) ST_READ;
							core_cmd <= #(1) 4'b1000;
						end
						shift <= #(1) 1'b1;
						core_txd <= #(1) ack_in;
					end
				ST_ACK:
					if (core_ack) begin
						if (stop) begin
							c_state <= #(1) ST_STOP;
							core_cmd <= #(1) 4'b0010;
						end
						else begin
							c_state <= #(1) ST_IDLE;
							core_cmd <= #(1) 4'b0000;
							cmd_ack <= #(1) 1'b1;
						end
						ack_out <= #(1) core_rxd;
						core_txd <= #(1) 1'b1;
					end
					else
						core_txd <= #(1) ack_in;
				ST_STOP:
					if (core_ack) begin
						c_state <= #(1) ST_IDLE;
						core_cmd <= #(1) 4'b0000;
						cmd_ack <= #(1) 1'b1;
					end
			endcase
		end
endmodule
module i2c_master_bit_ctrl (
	clk,
	nReset,
	ena,
	clk_cnt,
	cmd,
	cmd_ack,
	busy,
	al,
	din,
	dout,
	scl_i,
	scl_o,
	scl_oen,
	sda_i,
	sda_o,
	sda_oen
);
	input clk;
	input nReset;
	input ena;
	input [15:0] clk_cnt;
	input [3:0] cmd;
	output reg cmd_ack;
	output reg busy;
	output reg al;
	input din;
	output reg dout;
	input scl_i;
	output wire scl_o;
	output reg scl_oen;
	input sda_i;
	output wire sda_o;
	output reg sda_oen;
	reg [1:0] cSCL;
	reg [1:0] cSDA;
	reg [2:0] fSCL;
	reg [2:0] fSDA;
	reg sSCL;
	reg sSDA;
	reg dSCL;
	reg dSDA;
	reg dscl_oen;
	reg sda_chk;
	reg clk_en;
	reg slave_wait;
	reg [15:0] cnt;
	reg [13:0] filter_cnt;
	reg [17:0] c_state;
	always @(posedge clk) dscl_oen <= #(1) scl_oen;
	always @(posedge clk or negedge nReset)
		if (!nReset)
			slave_wait <= 1'b0;
		else
			slave_wait <= ((scl_oen & ~dscl_oen) & ~sSCL) | (slave_wait & ~sSCL);
	wire scl_sync = (dSCL & ~sSCL) & scl_oen;
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			cnt <= #(1) 16'h0000;
			clk_en <= #(1) 1'b1;
		end
		else if ((~|cnt || !ena) || scl_sync) begin
			cnt <= #(1) clk_cnt;
			clk_en <= #(1) 1'b1;
		end
		else if (slave_wait) begin
			cnt <= #(1) cnt;
			clk_en <= #(1) 1'b0;
		end
		else begin
			cnt <= #(1) cnt - 16'h0001;
			clk_en <= #(1) 1'b0;
		end
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			cSCL <= #(1) 2'b00;
			cSDA <= #(1) 2'b00;
		end
		else begin
			cSCL <= {cSCL[0], scl_i};
			cSDA <= {cSDA[0], sda_i};
		end
	always @(posedge clk or negedge nReset)
		if (!nReset)
			filter_cnt <= 14'h0000;
		else if (!ena)
			filter_cnt <= 14'h0000;
		else if (~|filter_cnt)
			filter_cnt <= clk_cnt >> 2;
		else
			filter_cnt <= filter_cnt - 1;
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			fSCL <= 3'b111;
			fSDA <= 3'b111;
		end
		else if (~|filter_cnt) begin
			fSCL <= {fSCL[1:0], cSCL[1]};
			fSDA <= {fSDA[1:0], cSDA[1]};
		end
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			sSCL <= #(1) 1'b1;
			sSDA <= #(1) 1'b1;
			dSCL <= #(1) 1'b1;
			dSDA <= #(1) 1'b1;
		end
		else begin
			sSCL <= #(1) (&fSCL[2:1] | &fSCL[1:0]) | (fSCL[2] & fSCL[0]);
			sSDA <= #(1) (&fSDA[2:1] | &fSDA[1:0]) | (fSDA[2] & fSDA[0]);
			dSCL <= #(1) sSCL;
			dSDA <= #(1) sSDA;
		end
	reg sta_condition;
	reg sto_condition;
	always @(posedge clk or negedge nReset)
		if (~nReset) begin
			sta_condition <= #(1) 1'b0;
			sto_condition <= #(1) 1'b0;
		end
		else begin
			sta_condition <= #(1) (~sSDA & dSDA) & sSCL;
			sto_condition <= #(1) (sSDA & ~dSDA) & sSCL;
		end
	always @(posedge clk or negedge nReset)
		if (!nReset)
			busy <= #(1) 1'b0;
		else
			busy <= #(1) (sta_condition | busy) & ~sto_condition;
	reg cmd_stop;
	always @(posedge clk or negedge nReset)
		if (!nReset)
			cmd_stop <= #(1) 1'b0;
		else if (clk_en)
			cmd_stop <= #(1) cmd == 4'b0010;
	always @(posedge clk or negedge nReset)
		if (!nReset)
			al <= #(1) 1'b0;
		else
			al <= #(1) ((sda_chk & ~sSDA) & sda_oen) | ((|c_state & sto_condition) & ~cmd_stop);
	always @(posedge clk)
		if (sSCL & ~dSCL)
			dout <= #(1) sSDA;
	parameter [17:0] idle = 18'b000000000000000000;
	parameter [17:0] start_a = 18'b000000000000000001;
	parameter [17:0] start_b = 18'b000000000000000010;
	parameter [17:0] start_c = 18'b000000000000000100;
	parameter [17:0] start_d = 18'b000000000000001000;
	parameter [17:0] start_e = 18'b000000000000010000;
	parameter [17:0] stop_a = 18'b000000000000100000;
	parameter [17:0] stop_b = 18'b000000000001000000;
	parameter [17:0] stop_c = 18'b000000000010000000;
	parameter [17:0] stop_d = 18'b000000000100000000;
	parameter [17:0] rd_a = 18'b000000001000000000;
	parameter [17:0] rd_b = 18'b000000010000000000;
	parameter [17:0] rd_c = 18'b000000100000000000;
	parameter [17:0] rd_d = 18'b000001000000000000;
	parameter [17:0] wr_a = 18'b000010000000000000;
	parameter [17:0] wr_b = 18'b000100000000000000;
	parameter [17:0] wr_c = 18'b001000000000000000;
	parameter [17:0] wr_d = 18'b010000000000000000;
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			c_state <= #(1) idle;
			cmd_ack <= #(1) 1'b0;
			scl_oen <= #(1) 1'b1;
			sda_oen <= #(1) 1'b1;
			sda_chk <= #(1) 1'b0;
		end
		else if (al) begin
			c_state <= #(1) idle;
			cmd_ack <= #(1) 1'b0;
			scl_oen <= #(1) 1'b1;
			sda_oen <= #(1) 1'b1;
			sda_chk <= #(1) 1'b0;
		end
		else begin
			cmd_ack <= #(1) 1'b0;
			if (clk_en)
				case (c_state)
					idle: begin
						case (cmd)
							4'b0001: c_state <= #(1) start_a;
							4'b0010: c_state <= #(1) stop_a;
							4'b0100: c_state <= #(1) wr_a;
							4'b1000: c_state <= #(1) rd_a;
							default: c_state <= #(1) idle;
						endcase
						scl_oen <= #(1) scl_oen;
						sda_oen <= #(1) sda_oen;
						sda_chk <= #(1) 1'b0;
					end
					start_a: begin
						c_state <= #(1) start_b;
						scl_oen <= #(1) scl_oen;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					start_b: begin
						c_state <= #(1) start_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					start_c: begin
						c_state <= #(1) start_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					start_d: begin
						c_state <= #(1) start_e;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					start_e: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_a: begin
						c_state <= #(1) stop_b;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_b: begin
						c_state <= #(1) stop_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_c: begin
						c_state <= #(1) stop_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_d: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_a: begin
						c_state <= #(1) rd_b;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_b: begin
						c_state <= #(1) rd_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_c: begin
						c_state <= #(1) rd_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_d: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					wr_a: begin
						c_state <= #(1) wr_b;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b0;
					end
					wr_b: begin
						c_state <= #(1) wr_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b0;
					end
					wr_c: begin
						c_state <= #(1) wr_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b1;
					end
					wr_d: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b0;
					end
				endcase
		end
	assign scl_o = 1'b0;
	assign sda_o = 1'b0;
endmodule
module pit_count (
	cnt_n,
	cnt_flag_o,
	pit_o,
	async_rst_b,
	bus_clk,
	counter_sync,
	prescale_out,
	pit_flg_clr,
	mod_value
);
	parameter COUNT_SIZE = 16;
	output reg [COUNT_SIZE - 1:0] cnt_n;
	output reg cnt_flag_o;
	output reg pit_o;
	input async_rst_b;
	input bus_clk;
	input counter_sync;
	input prescale_out;
	input pit_flg_clr;
	input [COUNT_SIZE - 1:0] mod_value;
	wire rollover;
	wire no_div;
	wire clear_counter;
	assign no_div = (mod_value == 1) || ~|mod_value;
	assign rollover = ((cnt_n == mod_value) || no_div) && prescale_out;
	assign clear_counter = !counter_sync;
	always @(posedge bus_clk or negedge async_rst_b)
		if (!async_rst_b)
			cnt_n <= 1;
		else if ((clear_counter || rollover) || no_div)
			cnt_n <= 1;
		else if (prescale_out)
			cnt_n <= cnt_n + 1;
	always @(posedge bus_clk or negedge async_rst_b)
		if (!async_rst_b)
			cnt_flag_o <= 0;
		else if (clear_counter || pit_flg_clr)
			cnt_flag_o <= 0;
		else if (rollover)
			cnt_flag_o <= 1;
	always @(posedge bus_clk or negedge async_rst_b)
		if (!async_rst_b)
			pit_o <= 0;
		else
			pit_o <= rollover && counter_sync;
endmodule
module pit_prescale (
	prescale_out,
	counter_sync,
	async_rst_b,
	bus_clk,
	cnt_sync_o,
	ext_sync_i,
	pit_slave,
	divisor
);
	parameter COUNT_SIZE = 15;
	parameter DECADE_CNTR = 1;
	parameter NO_PRESCALE = 0;
	output wire prescale_out;
	output wire counter_sync;
	input async_rst_b;
	input bus_clk;
	input cnt_sync_o;
	input ext_sync_i;
	input pit_slave;
	input [3:0] divisor;
	reg [COUNT_SIZE - 1:0] cnt_n;
	reg [COUNT_SIZE - 1:0] end_count;
	wire div_1;
	wire rollover;
	always @(*)
		if (DECADE_CNTR)
			case (divisor)
				0: end_count = 1;
				1: end_count = 2;
				2: end_count = 4;
				3: end_count = 8;
				4: end_count = 10;
				5: end_count = 100;
				6: end_count = 1000;
				7: end_count = 10000;
				8: end_count = 20000;
				default: end_count = 20000;
			endcase
		else
			case (divisor)
				0: end_count = 1;
				1: end_count = 2;
				2: end_count = 4;
				3: end_count = 8;
				4: end_count = 16;
				5: end_count = 32;
				6: end_count = 64;
				7: end_count = 128;
				8: end_count = 256;
				9: end_count = 512;
				10: end_count = 1024;
				11: end_count = 2048;
				12: end_count = 4096;
				13: end_count = 8192;
				14: end_count = 16384;
				15: end_count = 32768;
			endcase
	assign counter_sync = (pit_slave ? ext_sync_i : cnt_sync_o);
	assign div_1 = end_count == 1;
	assign rollover = NO_PRESCALE || (cnt_n == end_count);
	assign prescale_out = ((pit_slave && div_1) && ext_sync_i) || rollover;
	always @(posedge bus_clk or negedge async_rst_b)
		if (!async_rst_b)
			cnt_n <= 1;
		else if (!counter_sync || rollover)
			cnt_n <= 1;
		else
			cnt_n <= cnt_n + 1;
endmodule
module pit_regs (
	mod_value,
	pit_pre_scl,
	pit_slave,
	pit_flg_clr,
	pit_ien,
	cnt_sync_o,
	pit_irq_o,
	bus_clk,
	async_rst_b,
	write_bus,
	write_regs,
	cnt_flag_o
);
	parameter ARST_LVL = 1'b0;
	parameter COUNT_SIZE = 16;
	parameter NO_PRESCALE = 1'b0;
	parameter DWIDTH = 16;
	output reg [COUNT_SIZE - 1:0] mod_value;
	output wire [3:0] pit_pre_scl;
	output reg pit_slave;
	output reg pit_flg_clr;
	output reg pit_ien;
	output reg cnt_sync_o;
	output reg pit_irq_o;
	input bus_clk;
	input async_rst_b;
	input [DWIDTH - 1:0] write_bus;
	input [3:0] write_regs;
	input cnt_flag_o;
	reg [3:0] pit_pre;
	wire [15:0] write_data;
	assign write_data = (DWIDTH == 8 ? {write_bus[7:0], write_bus[7:0]} : write_bus);
	assign pit_pre_scl = (NO_PRESCALE ? 4'b0000 : pit_pre);
	always @(posedge bus_clk or negedge async_rst_b)
		if (!async_rst_b) begin
			pit_slave <= 1'b0;
			pit_pre <= 4'b0000;
			pit_flg_clr <= 1'b0;
			pit_ien <= 1'b0;
			cnt_sync_o <= 1'b0;
			mod_value <= 0;
		end
		else
			case (write_regs)
				4'b0011: begin
					pit_slave <= write_data[15];
					pit_pre <= write_data[11:8];
					pit_flg_clr <= write_data[2];
					pit_ien <= write_data[1];
					cnt_sync_o <= write_data[0];
				end
				4'b0001: begin
					pit_flg_clr <= write_data[2];
					pit_ien <= write_data[1];
					cnt_sync_o <= write_data[0];
				end
				4'b0010: begin
					pit_slave <= write_data[7];
					pit_pre <= write_data[3:0];
				end
				4'b1100: mod_value <= write_data;
				4'b0100: mod_value[7:0] <= write_data[7:0];
				4'b1000: mod_value[15:8] <= write_data[7:0];
				default: pit_flg_clr <= 1'b0;
			endcase
	always @(posedge bus_clk or negedge async_rst_b)
		if (!async_rst_b)
			pit_irq_o <= 0;
		else
			pit_irq_o <= cnt_flag_o && pit_ien;
endmodule
module pit_top (
	wb_dat_o,
	wb_ack_o,
	wb_clk_i,
	arst_i,
	wb_adr_i,
	wb_dat_i,
	wb_we_i,
	wb_stb_i,
	wb_cyc_i,
	wb_sel_i,
	pit_o,
	pit_irq_o,
	cnt_flag_o,
	cnt_sync_o,
	ext_sync_i
);
	parameter ARST_LVL = 1'b0;
	parameter PRE_COUNT_SIZE = 15;
	parameter COUNT_SIZE = 16;
	parameter DECADE_CNTR = 1'b1;
	parameter NO_PRESCALE = 1'b0;
	parameter SINGLE_CYCLE = 1'b0;
	parameter DWIDTH = 16;
	output wire [DWIDTH - 1:0] wb_dat_o;
	output wire wb_ack_o;
	input wb_clk_i;
	input arst_i;
	input [2:0] wb_adr_i;
	input [DWIDTH - 1:0] wb_dat_i;
	input wb_we_i;
	input wb_stb_i;
	input wb_cyc_i;
	input [1:0] wb_sel_i;
	output wire pit_o;
	output wire pit_irq_o;
	output wire cnt_flag_o;
	output wire cnt_sync_o;
	input ext_sync_i;
	wire [COUNT_SIZE - 1:0] mod_value;
	wire [COUNT_SIZE - 1:0] cnt_n;
	wire async_rst_b;
	wire sync_reset;
	wire [3:0] write_regs;
	wire prescale_out;
	wire pit_flg_clr;
	wire pit_slave;
	wire [3:0] pit_pre_scl;
	wire counter_sync;
	pit_wb_bus #(
		.ARST_LVL(ARST_LVL),
		.SINGLE_CYCLE(SINGLE_CYCLE),
		.DWIDTH(DWIDTH)
	) wishbone(
		.wb_dat_o(wb_dat_o),
		.wb_ack_o(wb_ack_o),
		.wb_clk_i(wb_clk_i),
		.arst_i(arst_i),
		.wb_adr_i(wb_adr_i),
		.wb_dat_i(wb_dat_i),
		.wb_we_i(wb_we_i),
		.wb_stb_i(wb_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_sel_i(wb_sel_i),
		.write_regs(write_regs),
		.async_rst_b(async_rst_b),
		.irq_source(cnt_flag_o),
		.read_regs({cnt_n, mod_value, pit_slave, DECADE_CNTR, NO_PRESCALE, 1'b0, pit_pre_scl, 5'b00000, cnt_flag_o, pit_ien, cnt_sync_o})
	);
	wire pit_ien;
	pit_regs #(
		.ARST_LVL(ARST_LVL),
		.COUNT_SIZE(COUNT_SIZE),
		.NO_PRESCALE(NO_PRESCALE),
		.DWIDTH(DWIDTH)
	) regs(
		.mod_value(mod_value),
		.pit_pre_scl(pit_pre_scl),
		.pit_slave(pit_slave),
		.pit_flg_clr(pit_flg_clr),
		.pit_ien(pit_ien),
		.cnt_sync_o(cnt_sync_o),
		.pit_irq_o(pit_irq_o),
		.async_rst_b(async_rst_b),
		.bus_clk(wb_clk_i),
		.write_bus(wb_dat_i),
		.write_regs(write_regs),
		.cnt_flag_o(cnt_flag_o)
	);
	pit_prescale #(
		.COUNT_SIZE(PRE_COUNT_SIZE),
		.DECADE_CNTR(DECADE_CNTR),
		.NO_PRESCALE(NO_PRESCALE)
	) prescale(
		.prescale_out(prescale_out),
		.counter_sync(counter_sync),
		.async_rst_b(async_rst_b),
		.bus_clk(wb_clk_i),
		.cnt_sync_o(cnt_sync_o),
		.ext_sync_i(ext_sync_i),
		.pit_slave(pit_slave),
		.divisor(pit_pre_scl)
	);
	pit_count #(.COUNT_SIZE(COUNT_SIZE)) counter(
		.cnt_n(cnt_n),
		.cnt_flag_o(cnt_flag_o),
		.pit_o(pit_o),
		.async_rst_b(async_rst_b),
		.bus_clk(wb_clk_i),
		.counter_sync(counter_sync),
		.prescale_out(prescale_out),
		.pit_flg_clr(pit_flg_clr),
		.mod_value(mod_value)
	);
endmodule
module pit_wb_bus (
	wb_dat_o,
	wb_ack_o,
	wb_clk_i,
	arst_i,
	wb_adr_i,
	wb_dat_i,
	wb_we_i,
	wb_stb_i,
	wb_cyc_i,
	wb_sel_i,
	write_regs,
	async_rst_b,
	irq_source,
	read_regs
);
	parameter ARST_LVL = 1'b0;
	parameter DWIDTH = 16;
	parameter SINGLE_CYCLE = 1'b0;
	output reg [DWIDTH - 1:0] wb_dat_o;
	output wire wb_ack_o;
	input wb_clk_i;
	input arst_i;
	input [2:0] wb_adr_i;
	input [DWIDTH - 1:0] wb_dat_i;
	input wb_we_i;
	input wb_stb_i;
	input wb_cyc_i;
	input [1:0] wb_sel_i;
	output reg [3:0] write_regs;
	output wire async_rst_b;
	input irq_source;
	input [47:0] read_regs;
	reg bus_wait_state;
	reg [2:0] addr_latch;
	wire eight_bit_bus;
	wire module_sel;
	wire wb_wacc;
	wire wb_racc;
	wire [2:0] address;
	assign eight_bit_bus = DWIDTH == 8;
	assign async_rst_b = arst_i ^ ARST_LVL;
	assign module_sel = wb_cyc_i && wb_stb_i;
	assign wb_wacc = (module_sel && wb_we_i) && (wb_ack_o || SINGLE_CYCLE);
	assign wb_racc = module_sel && !wb_we_i;
	assign wb_ack_o = (SINGLE_CYCLE ? module_sel : bus_wait_state && module_sel);
	assign address = (SINGLE_CYCLE ? wb_adr_i : addr_latch);
	always @(posedge wb_clk_i or negedge async_rst_b)
		if (!async_rst_b)
			bus_wait_state <= 1'b0;
		else
			bus_wait_state <= module_sel && !bus_wait_state;
	always @(posedge wb_clk_i)
		if (module_sel)
			addr_latch <= wb_adr_i;
	always @(*)
		case ({eight_bit_bus, address})
			4'b1000: wb_dat_o = read_regs[7:0];
			4'b1001: wb_dat_o = read_regs[15:8];
			4'b1010: wb_dat_o = read_regs[23:16];
			4'b1011: wb_dat_o = read_regs[31:24];
			4'b1100: wb_dat_o = read_regs[39:32];
			4'b1101: wb_dat_o = read_regs[47:40];
			4'b0000: wb_dat_o = read_regs[15:0];
			4'b0001: wb_dat_o = read_regs[31:16];
			4'b0010: wb_dat_o = read_regs[47:32];
			default: wb_dat_o = 0;
		endcase
	always @(*) begin
		write_regs = 0;
		if (wb_wacc)
			case ({eight_bit_bus, address})
				4'b1000: write_regs = 4'b0001;
				4'b1001: write_regs = 4'b0010;
				4'b1010: write_regs = 4'b0100;
				4'b1011: write_regs = 4'b1000;
				4'b0000: write_regs = 4'b0011;
				4'b0001: write_regs = 4'b1100;
				default:
					;
			endcase
	end
endmodule
module wbuart (
	i_clk,
	i_reset_n,
	i_wb_cyc,
	i_wb_stb,
	i_wb_we,
	i_wb_addr,
	i_wb_data,
	i_wb_sel,
	o_wb_stall,
	o_wb_ack,
	o_wb_data,
	i_uart_rx,
	o_uart_tx,
	o_uart_rx_int,
	o_uart_tx_int
);
	parameter [29:0] INITIAL_SETUP = 31'd868;
	input wire i_clk;
	input wire i_reset_n;
	input wire i_wb_cyc;
	input wire i_wb_stb;
	input wire i_wb_we;
	input wire [1:0] i_wb_addr;
	input wire [31:0] i_wb_data;
	input wire [3:0] i_wb_sel;
	output wire o_wb_stall;
	output reg o_wb_ack;
	output reg [31:0] o_wb_data;
	input wire i_uart_rx;
	output wire o_uart_tx;
	output wire o_uart_rx_int;
	output wire o_uart_tx_int;
	localparam [1:0] UART_SETUP = 2'b00;
	localparam [1:0] UART_CRREG = 2'b01;
	localparam [1:0] UART_RXREG = 2'b10;
	localparam [1:0] UART_TXREG = 2'b11;
	wire tx_busy;
	reg tx_busy_d;
	reg [29:0] uart_setup;
	wire [5:0] cr_reg;
	reg uart_tx_en;
	reg uart_rx_en;
	wire rx_stb;
	wire rx_break;
	wire rx_perr;
	wire rx_ferr;
	wire ck_uart;
	wire [7:0] rx_uart_data;
	reg rx_uart_reset;
	reg rx_empty;
	reg rx_empty_d;
	reg r_rx_perr;
	reg r_rx_overflow;
	wire w_uart_rx;
	wire [13:0] rx_reg;
	wire tx_break;
	wire [7:0] tx_data;
	reg [7:0] r_tx_data;
	reg tx_uart_reset;
	wire w_uart_tx;
	reg tx_empty_n;
	wire [11:0] tx_reg;
	reg tx_int_en;
	reg rx_int_en;
	reg [1:0] r_wb_addr;
	reg r_wb_ack;
	assign o_uart_tx = (uart_tx_en ? w_uart_tx : 1'bz);
	assign w_uart_rx = (uart_rx_en ? i_uart_rx : 1'b1);
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			uart_setup <= INITIAL_SETUP;
		else if ((i_wb_stb && (i_wb_addr[1:0] == UART_SETUP)) && i_wb_we) begin
			if (i_wb_sel[0])
				uart_setup[7:0] <= i_wb_data[7:0];
			if (i_wb_sel[1])
				uart_setup[15:8] <= i_wb_data[15:8];
			if (i_wb_sel[2])
				uart_setup[23:16] <= i_wb_data[23:16];
			if (i_wb_sel[3])
				uart_setup[29:24] <= i_wb_data[29:24];
		end
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			uart_rx_en <= 1'b0;
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_CRREG)) && i_wb_we) && i_wb_sel[0])
			uart_rx_en <= i_wb_data[0];
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			uart_tx_en <= 1'b0;
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_CRREG)) && i_wb_we) && i_wb_sel[0])
			uart_tx_en <= i_wb_data[3];
	assign cr_reg = {tx_uart_reset, tx_int_en, uart_tx_en, rx_uart_reset, rx_int_en, uart_rx_en};
	rxuart #(.INITIAL_SETUP(INITIAL_SETUP)) rx(
		.i_clk(i_clk),
		.i_reset_n(i_reset_n && ~rx_uart_reset),
		.i_setup({1'b0, uart_setup}),
		.i_uart_rx(w_uart_rx),
		.o_wr(rx_stb),
		.o_data(rx_uart_data),
		.o_break(rx_break),
		.o_parity_err(rx_perr),
		.o_frame_err(rx_ferr),
		.o_ck_uart(ck_uart)
	);
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			rx_int_en <= 1'b0;
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_CRREG)) && i_wb_we) && i_wb_sel[0])
			rx_int_en <= i_wb_data[1];
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n) begin
			rx_empty <= 1'b0;
			rx_empty_d <= 1'b0;
			r_rx_overflow <= 1'b0;
		end
		else if (rx_stb && !rx_empty_d)
			rx_empty_d <= 1'b1;
		else if (rx_stb && rx_empty_d)
			r_rx_overflow <= 1'b0;
		else if ((rx_empty && !r_wb_ack) && (r_wb_addr[1:0] == UART_RXREG)) begin
			rx_empty <= 1'b0;
			rx_empty_d <= 1'b0;
			r_rx_overflow <= 1'b0;
		end
		else if ((!rx_empty && i_wb_stb) && (i_wb_addr[1:0] == UART_RXREG))
			rx_empty <= rx_empty_d;
	assign o_uart_rx_int = (rx_int_en ? rx_empty_d : 1'b0);
	always @(posedge i_clk)
		if (rx_uart_reset || rx_break)
			r_rx_perr <= 1'b0;
		else if ((i_wb_stb && (i_wb_addr[1:0] == UART_RXREG)) && i_wb_we) begin
			if (i_wb_sel[1])
				r_rx_perr <= r_rx_perr && ~i_wb_data[9];
		end
		else if (rx_stb)
			r_rx_perr <= r_rx_perr || rx_perr;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			rx_uart_reset <= 1'b1;
		else if ((i_wb_stb && (i_wb_addr[1:0] == UART_SETUP)) && i_wb_we)
			rx_uart_reset <= 1'b1;
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_CRREG)) && i_wb_we) && i_wb_sel[0])
			rx_uart_reset <= i_wb_data[2];
		else
			rx_uart_reset <= 1'b0;
	assign rx_reg = {ck_uart, rx_break, r_rx_overflow, rx_ferr, r_rx_perr, rx_empty, rx_uart_data};
	reg r_tx_break;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			r_tx_break <= 1'b0;
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_TXREG)) && i_wb_we) && i_wb_sel[1])
			r_tx_break <= i_wb_data[10];
	assign tx_break = r_tx_break;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			tx_uart_reset <= 1'b1;
		else if ((i_wb_stb && (i_wb_addr[1:0] == UART_SETUP)) && i_wb_we)
			tx_uart_reset <= 1'b1;
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_CRREG)) && i_wb_we) && i_wb_sel[0])
			tx_uart_reset <= i_wb_data[5];
		else
			tx_uart_reset <= 1'b0;
	txuart #(.INITIAL_SETUP(INITIAL_SETUP)) tx(
		.i_clk(i_clk),
		.i_reset_n(i_reset_n),
		.i_setup({1'b0, uart_setup}),
		.i_break(r_tx_break),
		.i_wr(tx_empty_n),
		.i_data(tx_data),
		.i_cts_n(1'b0),
		.o_uart_tx(w_uart_tx),
		.o_busy(tx_busy)
	);
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			tx_int_en <= 1'b0;
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_CRREG)) && i_wb_we) && i_wb_sel[0])
			tx_int_en <= i_wb_data[4];
	assign o_uart_tx_int = (tx_int_en ? ~tx_busy : 1'b0);
	always @(posedge i_clk) tx_busy_d <= tx_busy;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n) begin
			tx_empty_n <= 1'b0;
			r_tx_data <= 8'b00000000;
		end
		else if (((i_wb_stb && (i_wb_addr[1:0] == UART_TXREG)) && i_wb_we) && i_wb_sel[0]) begin
			r_tx_data <= i_wb_data[7:0];
			tx_empty_n <= 1'b1;
		end
		else if (!tx_busy_d && tx_busy)
			tx_empty_n <= 1'b0;
	assign tx_data = r_tx_data;
	assign tx_reg = {w_uart_tx, tx_break, tx_busy, tx_empty_n, r_tx_data};
	always @(posedge i_clk) r_wb_addr <= i_wb_addr;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			r_wb_ack <= 1'b0;
		else
			r_wb_ack <= i_wb_stb;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			o_wb_ack <= 1'b0;
		else
			o_wb_ack <= r_wb_ack && i_wb_cyc;
	always @(posedge i_clk)
		casez (r_wb_addr)
			UART_SETUP: o_wb_data <= uart_setup;
			UART_CRREG: o_wb_data <= {26'b00000000000000000000000000, cr_reg};
			UART_RXREG: o_wb_data <= {18'b000000000000000000, rx_reg};
			UART_TXREG: o_wb_data <= {20'b00000000000000000000, tx_reg};
		endcase
	assign o_wb_stall = 1'b0;
	wire unused;
	assign unused = &{1'b0, i_wb_data[31]};
endmodule
module rxuart (
	i_clk,
	i_reset_n,
	i_setup,
	i_uart_rx,
	o_wr,
	o_data,
	o_break,
	o_parity_err,
	o_frame_err,
	o_ck_uart
);
	parameter [30:0] INITIAL_SETUP = 31'd868;
	localparam [3:0] RXU_BIT_ZERO = 4'h0;
	localparam [3:0] RXU_BIT_ONE = 4'h1;
	localparam [3:0] RXU_BIT_TWO = 4'h2;
	localparam [3:0] RXU_BIT_THREE = 4'h3;
	localparam [3:0] RXU_BIT_SEVEN = 4'h7;
	localparam [3:0] RXU_PARITY = 4'h8;
	localparam [3:0] RXU_STOP = 4'h9;
	localparam [3:0] RXU_SECOND_STOP = 4'ha;
	localparam [3:0] RXU_BREAK = 4'hd;
	localparam [3:0] RXU_RESET_IDLE = 4'he;
	localparam [3:0] RXU_IDLE = 4'hf;
	input wire i_clk;
	input wire i_reset_n;
	input wire [30:0] i_setup;
	input wire i_uart_rx;
	output reg o_wr;
	output reg [7:0] o_data;
	output reg o_break;
	output reg o_parity_err;
	output reg o_frame_err;
	output wire o_ck_uart;
	wire [23:0] clocks_per_baud;
	wire [23:0] half_baud;
	wire [1:0] data_bits;
	wire use_parity;
	wire parity_even;
	wire dblstop;
	wire fixd_parity;
	reg [29:0] r_setup;
	reg [3:0] state;
	reg [23:0] baud_counter;
	reg zero_baud_counter;
	reg q_uart;
	reg qq_uart;
	reg ck_uart;
	reg [27:0] chg_counter;
	wire [27:0] break_condition;
	reg line_synch;
	reg half_baud_time;
	reg [7:0] data_reg;
	reg calc_parity;
	reg pre_wr;
	assign clocks_per_baud = r_setup[23:0];
	assign data_bits = r_setup[29:28];
	assign dblstop = r_setup[27];
	assign use_parity = r_setup[26];
	assign fixd_parity = r_setup[25];
	assign parity_even = r_setup[24];
	assign break_condition = {r_setup[23:0], 4'h0};
	assign half_baud = {1'h0, r_setup[23:1]} - 24'h000001;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			{ck_uart, qq_uart, q_uart} <= 3'h0;
		else
			{ck_uart, qq_uart, q_uart} <= {qq_uart, q_uart, i_uart_rx};
	assign o_ck_uart = ck_uart;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			chg_counter <= 0;
		else if (qq_uart != ck_uart)
			chg_counter <= 0;
		else if (chg_counter < break_condition)
			chg_counter <= chg_counter + 1;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			o_break <= 1'b0;
		else
			o_break <= ((chg_counter >= break_condition) && ~ck_uart ? 1'b1 : 1'b0);
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			line_synch <= 1'b0;
		else
			line_synch <= (chg_counter >= break_condition) && ck_uart;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			half_baud_time <= 1'b0;
		else
			half_baud_time <= ~ck_uart && (chg_counter >= {4'h0, half_baud});
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			r_setup <= INITIAL_SETUP[29:0];
		else if (state >= RXU_RESET_IDLE)
			r_setup <= i_setup[29:0];
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			state <= RXU_RESET_IDLE;
		else if (state == RXU_RESET_IDLE) begin
			if (line_synch)
				state <= RXU_IDLE;
			else
				state <= RXU_RESET_IDLE;
		end
		else if (o_break)
			state <= RXU_BREAK;
		else if (state == RXU_BREAK) begin
			if (ck_uart)
				state <= RXU_IDLE;
			else
				state <= RXU_BREAK;
		end
		else if (state == RXU_IDLE) begin
			if (!ck_uart && half_baud_time)
				case (data_bits)
					2'b00: state <= RXU_BIT_ZERO;
					2'b01: state <= RXU_BIT_ONE;
					2'b10: state <= RXU_BIT_TWO;
					2'b11: state <= RXU_BIT_THREE;
				endcase
			else
				state <= RXU_IDLE;
		end
		else if (zero_baud_counter) begin
			if (state < RXU_BIT_SEVEN)
				state <= state + 1;
			else if (state == RXU_BIT_SEVEN)
				state <= (use_parity ? RXU_PARITY : RXU_STOP);
			else if (state == RXU_PARITY)
				state <= RXU_STOP;
			else if (state == RXU_STOP) begin
				if (!ck_uart)
					state <= RXU_RESET_IDLE;
				else if (dblstop)
					state <= RXU_SECOND_STOP;
				else
					state <= RXU_IDLE;
			end
			else if (!ck_uart)
				state <= RXU_RESET_IDLE;
			else
				state <= RXU_IDLE;
		end
	always @(posedge i_clk)
		if (zero_baud_counter && (state != RXU_PARITY))
			data_reg <= {ck_uart, data_reg[7:1]};
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			calc_parity <= 0;
		else if (state == RXU_IDLE)
			calc_parity <= 0;
		else if (zero_baud_counter)
			calc_parity <= calc_parity ^ ck_uart;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			o_parity_err <= 1'b0;
		else if (zero_baud_counter && (state == RXU_PARITY)) begin
			if (fixd_parity)
				o_parity_err <= ck_uart ^ parity_even;
			else if (parity_even)
				o_parity_err <= calc_parity != ck_uart;
			else
				o_parity_err <= calc_parity == ck_uart;
		end
		else if (state >= RXU_BREAK)
			o_parity_err <= 1'b0;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			o_frame_err <= 1'b0;
		else if (zero_baud_counter && ((state == RXU_STOP) || (state == RXU_SECOND_STOP)))
			o_frame_err <= o_frame_err || ~ck_uart;
		else if (zero_baud_counter || (state >= RXU_BREAK))
			o_frame_err <= 1'b0;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n) begin
			pre_wr <= 1'b0;
			o_data <= 8'h00;
		end
		else if (zero_baud_counter && (state == RXU_STOP)) begin
			pre_wr <= 1'b1;
			case (data_bits)
				2'b00: o_data <= data_reg;
				2'b01: o_data <= {1'b0, data_reg[7:1]};
				2'b10: o_data <= {2'b00, data_reg[7:2]};
				2'b11: o_data <= {3'b000, data_reg[7:3]};
			endcase
		end
		else if (zero_baud_counter || (state == RXU_IDLE))
			pre_wr <= 1'b0;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			o_wr <= 1'b0;
		else if (zero_baud_counter || (state == RXU_IDLE))
			o_wr <= pre_wr;
		else
			o_wr <= 1'b0;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			baud_counter <= INITIAL_SETUP[23:0] - 1;
		else if (zero_baud_counter)
			baud_counter <= clocks_per_baud - 1;
		else
			case (state)
				RXU_RESET_IDLE: baud_counter <= clocks_per_baud - 1;
				RXU_BREAK: baud_counter <= clocks_per_baud - 1;
				RXU_IDLE: baud_counter <= clocks_per_baud - 1;
				default: baud_counter <= baud_counter - 1;
			endcase
	always @(posedge i_clk)
		if (state == RXU_IDLE)
			zero_baud_counter <= 1'b0;
		else
			zero_baud_counter <= baud_counter == 1;
endmodule
module txuart (
	i_clk,
	i_reset_n,
	i_setup,
	i_break,
	i_wr,
	i_data,
	i_cts_n,
	o_uart_tx,
	o_busy
);
	parameter [30:0] INITIAL_SETUP = 31'd868;
	localparam [3:0] TXU_BIT_ZERO = 4'h0;
	localparam [3:0] TXU_BIT_ONE = 4'h1;
	localparam [3:0] TXU_BIT_TWO = 4'h2;
	localparam [3:0] TXU_BIT_THREE = 4'h3;
	localparam [3:0] TXU_BIT_SEVEN = 4'h7;
	localparam [3:0] TXU_PARITY = 4'h8;
	localparam [3:0] TXU_STOP = 4'h9;
	localparam [3:0] TXU_SECOND_STOP = 4'ha;
	localparam [3:0] TXU_BREAK = 4'he;
	localparam [3:0] TXU_IDLE = 4'hf;
	input wire i_clk;
	input wire i_reset_n;
	input wire [30:0] i_setup;
	input wire i_break;
	input wire i_wr;
	input wire [7:0] i_data;
	input wire i_cts_n;
	output reg o_uart_tx;
	output wire o_busy;
	wire [27:0] clocks_per_baud;
	wire [27:0] break_condition;
	wire [1:0] i_data_bits;
	wire [1:0] data_bits;
	wire use_parity;
	wire parity_odd;
	wire dblstop;
	wire fixd_parity;
	wire fixdp_value;
	wire hw_flow_control;
	wire i_parity_odd;
	reg [30:0] r_setup;
	assign clocks_per_baud = {4'h0, r_setup[23:0]};
	assign break_condition = {r_setup[23:0], 4'h0};
	assign hw_flow_control = !r_setup[30];
	assign i_data_bits = i_setup[29:28];
	assign data_bits = r_setup[29:28];
	assign dblstop = r_setup[27];
	assign use_parity = r_setup[26];
	assign fixd_parity = r_setup[25];
	assign i_parity_odd = i_setup[24];
	assign parity_odd = r_setup[24];
	assign fixdp_value = r_setup[24];
	reg [27:0] baud_counter;
	reg [3:0] state;
	reg [7:0] lcl_data;
	reg calc_parity;
	reg r_busy;
	reg zero_baud_counter;
	reg last_state;
	reg q_cts_n;
	reg qq_cts_n;
	reg ck_cts;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			{qq_cts_n, q_cts_n} <= 2'b11;
		else
			{qq_cts_n, q_cts_n} <= {q_cts_n, i_cts_n};
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			ck_cts <= 1'b0;
		else
			ck_cts <= !qq_cts_n || !hw_flow_control;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n) begin
			r_busy <= 1'b1;
			state <= TXU_IDLE;
		end
		else if (i_break) begin
			state <= TXU_BREAK;
			r_busy <= 1'b1;
		end
		else if (!zero_baud_counter)
			r_busy <= 1'b1;
		else if (state == TXU_BREAK) begin
			state <= TXU_IDLE;
			r_busy <= !ck_cts;
		end
		else if (state == TXU_IDLE) begin
			if (i_wr && !r_busy) begin
				r_busy <= 1'b1;
				case (i_data_bits)
					2'b00: state <= TXU_BIT_ZERO;
					2'b01: state <= TXU_BIT_ONE;
					2'b10: state <= TXU_BIT_TWO;
					2'b11: state <= TXU_BIT_THREE;
				endcase
			end
			else
				r_busy <= !ck_cts;
		end
		else begin
			r_busy <= 1'b1;
			if (state[3] == 0) begin
				if (state == TXU_BIT_SEVEN)
					state <= (use_parity ? TXU_PARITY : TXU_STOP);
				else
					state <= state + 1;
			end
			else if (state == TXU_PARITY)
				state <= TXU_STOP;
			else if (state == TXU_STOP) begin
				if (dblstop)
					state <= TXU_SECOND_STOP;
				else
					state <= TXU_IDLE;
			end
			else
				state <= TXU_IDLE;
		end
	assign o_busy = r_busy;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			r_setup <= INITIAL_SETUP;
		else if (!o_busy)
			r_setup <= i_setup;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			lcl_data <= 8'hff;
		else if (!r_busy)
			lcl_data <= i_data;
		else if (zero_baud_counter)
			lcl_data <= {1'b0, lcl_data[7:1]};
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			o_uart_tx <= 1'b1;
		else if (i_break || (i_wr && !r_busy))
			o_uart_tx <= 1'b0;
		else if (zero_baud_counter)
			casez (state)
				4'b0zzz: o_uart_tx <= lcl_data[0];
				TXU_PARITY: o_uart_tx <= calc_parity;
				default: o_uart_tx <= 1'b1;
			endcase
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			calc_parity <= 1'b0;
		else if (!o_busy)
			calc_parity <= i_setup[24];
		else if (fixd_parity)
			calc_parity <= fixdp_value;
		else if (zero_baud_counter) begin
			if (state[3] == 0)
				calc_parity <= calc_parity ^ lcl_data[0];
			else if (state == TXU_IDLE)
				calc_parity <= parity_odd;
		end
		else if (!r_busy)
			calc_parity <= parity_odd;
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n) begin
			baud_counter <= {INITIAL_SETUP[23:0], 4'h0};
			zero_baud_counter <= 1'b0;
		end
		else if (i_break) begin
			baud_counter <= break_condition;
			zero_baud_counter <= 1'b0;
		end
		else begin
			zero_baud_counter <= baud_counter == 28'h0000001;
			if (!zero_baud_counter)
				baud_counter <= baud_counter - 28'h0000001;
			else if (state == TXU_BREAK) begin
				baud_counter <= 0;
				zero_baud_counter <= 1'b1;
			end
			else if (state == TXU_IDLE) begin
				baud_counter <= 28'h0000000;
				zero_baud_counter <= 1'b1;
				if (i_wr && !r_busy) begin
					baud_counter <= {4'h0, i_setup[23:0]} - 28'h0000001;
					zero_baud_counter <= 1'b0;
				end
			end
			else if (last_state)
				baud_counter <= clocks_per_baud - 28'h0000002;
			else
				baud_counter <= clocks_per_baud - 28'h0000001;
		end
	always @(posedge i_clk or negedge i_reset_n)
		if (!i_reset_n)
			last_state <= 1'b0;
		else if (dblstop)
			last_state <= state == TXU_SECOND_STOP;
		else
			last_state <= state == TXU_STOP;
	wire unused;
	assign unused = &{1'b0, i_parity_odd, data_bits};
endmodule
module qflexpress (
	i_clk,
	i_reset,
	i_wb_cyc,
	i_wb_stb,
	i_cfg_stb,
	i_wb_we,
	i_wb_addr,
	i_wb_data,
	o_wb_stall,
	o_wb_ack,
	o_wb_data,
	o_qspi_sck,
	o_qspi_cs_n,
	o_qspi_mod,
	o_qspi_dat,
	i_qspi_dat
);
	parameter LGFLASHSZ = 24;
	parameter [0:0] OPT_PIPE = 1'b1;
	parameter [0:0] OPT_CFG = 1'b1;
	parameter [0:0] OPT_STARTUP = 1'b1;
	localparam [0:0] OPT_ADDR32 = LGFLASHSZ > 24;
	parameter OPT_CLKDIV = 0;
	parameter [0:0] OPT_ENDIANSWAP = 1'b1;
	localparam [0:0] OPT_ODDR = OPT_CLKDIV == 0;
	localparam CKDV_BITS = (OPT_CLKDIV == 0 ? 0 : (OPT_CLKDIV < 2 ? 1 : (OPT_CLKDIV < 4 ? 2 : (OPT_CLKDIV < 8 ? 3 : (OPT_CLKDIV < 16 ? 4 : (OPT_CLKDIV < 32 ? 5 : (OPT_CLKDIV < 64 ? 6 : (OPT_CLKDIV < 128 ? 7 : (OPT_CLKDIV < 256 ? 8 : 9)))))))));
	parameter RDDELAY = 0;
	parameter NDUMMY = 6;
	parameter OPT_STARTUP_FILE = "";
	localparam [4:0] CFG_MODE = 12;
	localparam [4:0] QSPEED_BIT = 11;
	localparam [4:0] DSPEED_BIT = 10;
	localparam [4:0] DIR_BIT = 9;
	localparam [4:0] USER_CS_n = 8;
	localparam [1:0] NORMAL_SPI = 2'b00;
	localparam [1:0] QUAD_WRITE = 2'b10;
	localparam [1:0] QUAD_READ = 2'b11;
	localparam [7:0] QIO_READ_CMD = (OPT_ADDR32 ? 8'hec : 8'heb);
	localparam AW = LGFLASHSZ - 2;
	localparam DW = 32;
	input wire i_clk;
	input wire i_reset;
	input wire i_wb_cyc;
	input wire i_wb_stb;
	input wire i_cfg_stb;
	input wire i_wb_we;
	input wire [AW - 1:0] i_wb_addr;
	input wire [31:0] i_wb_data;
	output reg o_wb_stall;
	output reg o_wb_ack;
	output reg [31:0] o_wb_data;
	output reg o_qspi_sck;
	output reg o_qspi_cs_n;
	output reg [1:0] o_qspi_mod;
	output wire [3:0] o_qspi_dat;
	input wire [3:0] i_qspi_dat;
	reg dly_ack;
	reg read_sck;
	reg xtra_stall;
	reg [4:0] clk_ctr;
	reg cfg_mode;
	reg cfg_speed;
	reg cfg_dir;
	reg cfg_cs;
	wire cfg_write;
	wire cfg_hs_write;
	wire cfg_ls_write;
	wire cfg_hs_read;
	wire user_request;
	wire bus_request;
	wire pipe_req;
	wire cfg_noop;
	wire cfg_stb;
	assign bus_request = ((i_wb_stb && !o_wb_stall) && !i_wb_we) && !cfg_mode;
	assign cfg_stb = (OPT_CFG && i_cfg_stb) && !o_wb_stall;
	assign cfg_noop = (cfg_stb && ((!i_wb_we || !i_wb_data[CFG_MODE]) || i_wb_data[USER_CS_n])) || ((!OPT_CFG && i_cfg_stb) && !o_wb_stall);
	assign user_request = (cfg_stb && i_wb_we) && i_wb_data[CFG_MODE];
	assign cfg_write = user_request && !i_wb_data[USER_CS_n];
	assign cfg_hs_write = (cfg_write && i_wb_data[QSPEED_BIT]) && i_wb_data[DIR_BIT];
	assign cfg_hs_read = (cfg_write && i_wb_data[QSPEED_BIT]) && !i_wb_data[DIR_BIT];
	assign cfg_ls_write = cfg_write && !i_wb_data[QSPEED_BIT];
	reg ckstb;
	reg ckpos;
	reg ckneg;
	reg ckpre;
	reg maintenance;
	reg [1:0] m_mod;
	reg m_cs_n;
	reg m_clk;
	reg [3:0] m_dat;
	reg [((32 + (OPT_ADDR32 ? 8 : 0)) + (4 * (OPT_ODDR ? 0 : 1))) - 1:0] data_pipe;
	reg pre_ack = 1'b0;
	reg actual_sck;
	generate
		if (OPT_ODDR) begin : genblk1
			wire [1:1] sv2v_tmp_768DC;
			assign sv2v_tmp_768DC = 1'b1;
			always @(*) ckstb = sv2v_tmp_768DC;
			wire [1:1] sv2v_tmp_A3375;
			assign sv2v_tmp_A3375 = 1'b1;
			always @(*) ckpos = sv2v_tmp_A3375;
			wire [1:1] sv2v_tmp_19D35;
			assign sv2v_tmp_19D35 = 1'b1;
			always @(*) ckneg = sv2v_tmp_19D35;
			wire [1:1] sv2v_tmp_741DE;
			assign sv2v_tmp_741DE = 1'b1;
			always @(*) ckpre = sv2v_tmp_741DE;
		end
		else if (OPT_CLKDIV == 1) begin : CKSTB_ONE
			reg clk_counter;
			initial clk_counter = 1'b1;
			always @(posedge i_clk)
				if (i_reset)
					clk_counter <= 1'b1;
				else if (clk_counter != 0)
					clk_counter <= 1'b0;
				else if (bus_request)
					clk_counter <= pipe_req;
				else if (maintenance || (!o_qspi_cs_n && o_wb_stall))
					clk_counter <= 1'b1;
			always @(*) begin
				ckpre = clk_counter == 1;
				ckstb = clk_counter == 0;
				ckpos = clk_counter == 1;
				ckneg = clk_counter == 0;
			end
		end
		else begin : CKSTB_GEN
			reg [CKDV_BITS - 1:0] clk_counter;
			initial clk_counter = OPT_CLKDIV;
			always @(posedge i_clk)
				if (i_reset)
					clk_counter <= OPT_CLKDIV;
				else if (clk_counter != 0)
					clk_counter <= clk_counter - 1;
				else if (bus_request)
					clk_counter <= (pipe_req ? OPT_CLKDIV : 0);
				else if (maintenance || (!o_qspi_cs_n && o_wb_stall))
					clk_counter <= OPT_CLKDIV;
			initial ckpre = OPT_CLKDIV == 1;
			initial ckstb = 1'b0;
			initial ckpos = OPT_CLKDIV == 1;
			always @(posedge i_clk)
				if (i_reset) begin
					ckpre <= OPT_CLKDIV == 1;
					ckstb <= 1'b0;
					ckpos <= OPT_CLKDIV == 1;
				end
				else begin
					ckpre <= clk_counter == 2;
					ckstb <= clk_counter == 1;
					ckpos <= clk_counter == (((OPT_CLKDIV + 1) / 2) + 1);
				end
			always @(*) ckneg = ckstb;
		end
		if (OPT_STARTUP) begin : GEN_STARTUP
			localparam M_WAITBIT = 10;
			localparam M_LGADDR = 5;
			localparam M_FIRSTIDX = 0;
			reg [M_WAITBIT:0] m_this_word;
			reg [M_WAITBIT:0] m_cmd_word [0:31];
			reg [4:0] m_cmd_index;
			reg [9:0] m_counter;
			reg m_midcount;
			reg [3:0] m_bitcount;
			reg [7:0] m_byte;
			integer k;
			initial begin
				for (k = 0; k < 32; k = k + 1)
					m_cmd_word[k] = -1;
				m_cmd_word[5'h07] = -1;
				m_cmd_word[5'h08] = {1'b0, NORMAL_SPI, 8'hff};
				m_cmd_word[5'h09] = {1'b0, NORMAL_SPI, 8'hff};
				m_cmd_word[5'h0a] = {1'b0, NORMAL_SPI, 8'hff};
				m_cmd_word[5'h0b] = 11'h43f;
				m_cmd_word[5'h0c] = {1'b0, NORMAL_SPI, 8'h06};
				m_cmd_word[5'h0d] = 11'h7ff;
				m_cmd_word[5'h0e] = {1'b0, NORMAL_SPI, 8'h01};
				m_cmd_word[5'h0f] = {1'b0, NORMAL_SPI, 8'h00};
				m_cmd_word[5'h10] = {1'b0, NORMAL_SPI, 8'h02};
				m_cmd_word[5'h11] = 11'h7ff;
				m_cmd_word[5'h12] = 11'h7ff;
				m_cmd_word[5'h13] = {1'b0, NORMAL_SPI, 8'h04};
				m_cmd_word[5'h14] = 11'h7ff;
				m_cmd_word[5'h15] = {1'b0, NORMAL_SPI, 8'heb};
				m_cmd_word[5'h16] = {1'b0, QUAD_WRITE, 8'h00};
				m_cmd_word[5'h17] = {1'b0, QUAD_WRITE, 8'h00};
				m_cmd_word[5'h18] = {1'b0, QUAD_WRITE, 8'h00};
				m_cmd_word[5'h19] = {1'b0, QUAD_WRITE, 8'ha0};
				m_cmd_word[5'h1a] = {1'b0, QUAD_WRITE, 8'h00};
				m_cmd_word[5'h1b] = {1'b0, QUAD_WRITE, 8'h00};
				m_cmd_word[5'h1c] = {1'b0, QUAD_READ, 8'h00};
				m_cmd_word[5'h1d] = -1;
				m_cmd_word[5'h1e] = -1;
				m_cmd_word[5'h1f] = -1;
			end
			reg m_final;
			wire m_ce;
			wire new_word;
			assign m_ce = !m_midcount && ckstb;
			assign new_word = m_ce && (m_bitcount == 0);
			initial maintenance = 1'b1;
			initial m_cmd_index = M_FIRSTIDX;
			always @(posedge i_clk)
				if (i_reset) begin
					m_cmd_index <= M_FIRSTIDX;
					maintenance <= 1'b1;
				end
				else if (new_word) begin
					maintenance <= maintenance && !m_final;
					if (!(&m_cmd_index))
						m_cmd_index <= m_cmd_index + 1'b1;
				end
			initial m_this_word = -1;
			always @(posedge i_clk)
				if (new_word)
					m_this_word <= m_cmd_word[m_cmd_index];
			initial m_final = 1'b0;
			always @(posedge i_clk)
				if (i_reset)
					m_final <= 1'b0;
				else if (new_word)
					m_final <= m_final || &m_cmd_index;
			initial m_midcount = 1;
			initial m_counter = -1;
			always @(posedge i_clk)
				if (i_reset) begin
					m_midcount <= 1'b1;
					m_counter <= -1;
				end
				else if (new_word) begin
					m_midcount <= m_this_word[M_WAITBIT] && |m_this_word[9:0];
					if (m_this_word[M_WAITBIT])
						m_counter <= m_this_word[9:0];
				end
				else begin
					m_midcount <= m_counter > 1;
					if (m_counter > 0)
						m_counter <= m_counter - 1'b1;
				end
			initial m_mod = NORMAL_SPI;
			always @(posedge i_clk)
				if (i_reset) begin
					m_cs_n <= 1'b1;
					m_mod <= NORMAL_SPI;
					m_bitcount <= 0;
				end
				else if (ckstb) begin
					if (m_bitcount != 0)
						m_bitcount <= m_bitcount - 1;
					else if (m_ce && m_final) begin
						m_cs_n <= 1'b1;
						m_mod <= NORMAL_SPI;
						m_bitcount <= 0;
					end
					else if (m_midcount || m_this_word[M_WAITBIT]) begin
						m_cs_n <= 1'b1;
						m_mod <= NORMAL_SPI;
						m_bitcount <= 0;
					end
					else begin
						m_cs_n <= 1'b0;
						m_mod <= m_this_word[9:8];
						m_bitcount <= (!OPT_ODDR && m_cs_n ? 4'h2 : 4'h1);
						if (!m_this_word[9])
							m_bitcount <= (!OPT_ODDR && m_cs_n ? 4'h8 : 4'h7);
					end
				end
			initial m_dat = 0;
			always @(posedge i_clk)
				if (m_ce) begin
					if (m_bitcount == 0) begin
						if (!OPT_ODDR && m_cs_n) begin
							m_dat <= {4 {m_this_word[7]}};
							m_byte <= m_this_word[7:0];
						end
						else begin
							m_dat <= m_this_word[7:4];
							m_byte <= {m_this_word[3:0], 4'h0};
							if (!m_this_word[9]) begin
								m_dat[0] <= m_this_word[7];
								m_byte <= {m_this_word[6:0], 1'b0};
							end
						end
					end
					else begin
						m_dat <= m_byte[7:4];
						m_byte <= {m_byte[3:0], 4'h0};
						if (!m_mod[1]) begin
							m_dat[0] <= m_byte[7];
							m_byte <= {m_byte[6:0], 1'b0};
						end
						else
							m_byte <= {m_byte[3:0], 4'b0000};
					end
				end
			if (OPT_ODDR) begin : genblk1
				always @(*) m_clk = !m_cs_n;
			end
			else begin : genblk1
				always @(posedge i_clk)
					if (i_reset)
						m_clk <= 1'b1;
					else if (m_cs_n)
						m_clk <= 1'b1;
					else if (!m_clk && ckpos)
						m_clk <= 1'b1;
					else if (m_midcount)
						m_clk <= 1'b1;
					else if (new_word && m_this_word[M_WAITBIT])
						m_clk <= 1'b1;
					else if (ckneg)
						m_clk <= 1'b0;
			end
		end
		else begin : NO_STARTUP_OPT
			always @(*) begin
				maintenance = 0;
				m_mod = 2'b00;
				m_cs_n = 1'b1;
				m_clk = 1'b0;
				m_dat = 4'h0;
			end
			wire unused_maintenance;
			assign unused_maintenance = &{1'b0, maintenance, m_mod, m_cs_n, m_clk, m_dat};
		end
	endgenerate
	initial data_pipe = 0;
	always @(posedge i_clk) begin
		if (!o_wb_stall) begin
			data_pipe <= 0;
			data_pipe[(8 + LGFLASHSZ) - 1:0] <= {i_wb_addr, 10'h0a0};
			if (i_cfg_stb)
				data_pipe[24 + (OPT_ADDR32 ? 8 : 0)+:8] <= i_wb_data[7:0];
			if (i_cfg_stb && !i_wb_data[QSPEED_BIT]) begin
				data_pipe[28 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[7];
				data_pipe[24 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[6];
			end
			if (i_cfg_stb) begin
				data_pipe[20 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[5];
				data_pipe[16 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[4];
				data_pipe[12 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[3];
				data_pipe[8 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[2];
				data_pipe[4 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[1];
				data_pipe[0 + (OPT_ADDR32 ? 8 : 0)] <= i_wb_data[0];
			end
		end
		else if (ckstb)
			data_pipe <= {data_pipe[((32 + (OPT_ADDR32 ? 8 : 0)) + (4 * ((OPT_ODDR ? 0 : 1) - 1))) - 1:0], 4'h0};
		if (maintenance)
			data_pipe[(28 + (OPT_ADDR32 ? 8 : 0)) + (4 * (OPT_ODDR ? 0 : 1))+:4] <= m_dat;
	end
	assign o_qspi_dat = data_pipe[(28 + (OPT_ADDR32 ? 8 : 0)) + (4 * (OPT_ODDR ? 0 : 1))+:4];
	always @(posedge i_clk)
		if (i_reset || !i_wb_cyc)
			pre_ack <= 1'b0;
		else if (bus_request || cfg_write)
			pre_ack <= 1'b1;
	generate
		if (OPT_PIPE) begin : OPT_PIPE_BLOCK
			reg r_pipe_req;
			wire w_pipe_condition;
			reg [AW - 1:0] next_addr;
			always @(posedge i_clk)
				if (!o_wb_stall)
					next_addr <= i_wb_addr + 1'b1;
			assign w_pipe_condition = ((((((i_wb_stb && !i_wb_we) && pre_ack) && !maintenance) && !cfg_mode) && !o_qspi_cs_n) && |clk_ctr[2:0]) && (next_addr == i_wb_addr);
			initial r_pipe_req = 1'b0;
			always @(posedge i_clk)
				if ((clk_ctr == 1) && ckstb)
					r_pipe_req <= 1'b0;
				else
					r_pipe_req <= w_pipe_condition;
			assign pipe_req = r_pipe_req;
		end
		else begin : genblk3
			assign pipe_req = 1'b0;
		end
	endgenerate
	initial clk_ctr = 0;
	always @(posedge i_clk)
		if (i_reset || maintenance)
			clk_ctr <= 0;
		else if (bus_request && !pipe_req)
			clk_ctr <= ((5'd14 + NDUMMY) + (OPT_ADDR32 ? 2 : 0)) + (OPT_ODDR ? 0 : 1);
		else if (bus_request)
			clk_ctr <= 5'd8;
		else if (cfg_ls_write)
			clk_ctr <= 5'd8 + (OPT_ODDR ? 0 : 1);
		else if (cfg_write)
			clk_ctr <= 5'd2 + (OPT_ODDR ? 0 : 1);
		else if (ckstb && |clk_ctr)
			clk_ctr <= clk_ctr - 1'b1;
	initial o_qspi_sck = !OPT_ODDR;
	always @(posedge i_clk)
		if (i_reset)
			o_qspi_sck <= !OPT_ODDR;
		else if (maintenance)
			o_qspi_sck <= m_clk;
		else if ((!OPT_ODDR && bus_request) && pipe_req)
			o_qspi_sck <= 1'b0;
		else if (bus_request || cfg_write)
			o_qspi_sck <= 1'b1;
		else if (OPT_ODDR) begin
			if (cfg_mode && (clk_ctr <= 1))
				o_qspi_sck <= 1'b0;
			else if (clk_ctr[4:0] > 5'd1)
				o_qspi_sck <= 1'b1;
			else
				o_qspi_sck <= 1'b0;
		end
		else if ((ckpos && !o_qspi_sck) || o_qspi_cs_n)
			o_qspi_sck <= 1'b1;
		else if (ckneg && o_qspi_sck) begin
			if (cfg_mode && (clk_ctr <= 1))
				o_qspi_sck <= 1'b1;
			else if (clk_ctr[4:0] > 5'd1)
				o_qspi_sck <= 1'b0;
			else
				o_qspi_sck <= 1'b1;
		end
	initial o_qspi_cs_n = 1'b1;
	always @(posedge i_clk)
		if (i_reset)
			o_qspi_cs_n <= 1'b1;
		else if (maintenance)
			o_qspi_cs_n <= m_cs_n;
		else if (cfg_stb && i_wb_we)
			o_qspi_cs_n <= !i_wb_data[CFG_MODE] || i_wb_data[USER_CS_n];
		else if (OPT_CFG && cfg_cs)
			o_qspi_cs_n <= 1'b0;
		else if (bus_request || cfg_write)
			o_qspi_cs_n <= 1'b0;
		else if (ckstb)
			o_qspi_cs_n <= clk_ctr <= 1;
	initial o_qspi_mod = NORMAL_SPI;
	always @(posedge i_clk)
		if (i_reset)
			o_qspi_mod <= NORMAL_SPI;
		else if (maintenance)
			o_qspi_mod <= m_mod;
		else if (bus_request && !pipe_req)
			o_qspi_mod <= QUAD_WRITE;
		else if (bus_request || cfg_hs_read)
			o_qspi_mod <= QUAD_READ;
		else if (cfg_hs_write)
			o_qspi_mod <= QUAD_WRITE;
		else if (cfg_ls_write || (cfg_mode && !cfg_speed))
			o_qspi_mod <= NORMAL_SPI;
		else if ((ckstb && (clk_ctr <= 5'd9)) && (!cfg_mode || !cfg_dir))
			o_qspi_mod <= QUAD_READ;
	initial o_wb_stall = 1'b1;
	always @(posedge i_clk)
		if (i_reset)
			o_wb_stall <= 1'b1;
		else if (maintenance)
			o_wb_stall <= 1'b1;
		else if (((RDDELAY > 0) && (i_cfg_stb || i_wb_stb)) && !o_wb_stall)
			o_wb_stall <= 1'b1;
		else if ((RDDELAY == 0) && (cfg_write || bus_request))
			o_wb_stall <= 1'b1;
		else if (ckstb || (clk_ctr == 0)) begin
			if (((ckpre && i_wb_stb) && pipe_req) && (clk_ctr == 5'd2))
				o_wb_stall <= 1'b0;
			else if ((clk_ctr > 1) || xtra_stall)
				o_wb_stall <= 1'b1;
			else
				o_wb_stall <= 1'b0;
		end
		else if (((ckpre && i_wb_stb) && pipe_req) && (clk_ctr == 5'd1))
			o_wb_stall <= 1'b0;
	always @(posedge i_clk)
		if (i_reset)
			dly_ack <= 1'b0;
		else if (ckstb && (clk_ctr == 1))
			dly_ack <= i_wb_cyc && pre_ack;
		else if ((i_wb_stb && !o_wb_stall) && !bus_request)
			dly_ack <= 1'b1;
		else if (cfg_noop)
			dly_ack <= 1'b1;
		else
			dly_ack <= 1'b0;
	generate
		if (OPT_ODDR) begin : SCK_ACTUAL
			always @(*) actual_sck = o_qspi_sck;
		end
		else if (OPT_CLKDIV == 1) begin : SCK_ONE
			initial actual_sck = 1'b0;
			always @(posedge i_clk)
				if (i_reset)
					actual_sck <= 1'b0;
				else
					actual_sck <= !o_qspi_sck && (clk_ctr > 0);
		end
		else begin : SCK_ANY
			initial actual_sck = 1'b0;
			always @(posedge i_clk)
				if (i_reset)
					actual_sck <= 1'b0;
				else
					actual_sck <= (o_qspi_sck && ckpre) && (clk_ctr > 0);
		end
		if (RDDELAY == 0) begin : RDDELAY_NONE
			always @(*) begin
				read_sck = actual_sck;
				o_wb_ack = dly_ack;
				xtra_stall = 1'b0;
			end
		end
		else begin : RDDELAY_NONZERO
			reg [RDDELAY - 1:0] sck_pipe;
			reg [RDDELAY - 1:0] ack_pipe;
			reg [RDDELAY - 1:0] stall_pipe;
			reg not_done;
			initial sck_pipe = 0;
			initial ack_pipe = 0;
			initial stall_pipe = -1;
			if (RDDELAY > 1) begin : genblk1
				always @(posedge i_clk)
					if (i_reset)
						sck_pipe <= 0;
					else
						sck_pipe <= {sck_pipe[RDDELAY - 2:0], actual_sck};
				always @(posedge i_clk)
					if (i_reset || !i_wb_cyc)
						ack_pipe <= 0;
					else
						ack_pipe <= {ack_pipe[RDDELAY - 2:0], dly_ack};
				always @(posedge i_clk)
					if (i_reset)
						stall_pipe <= -1;
					else
						stall_pipe <= {stall_pipe[RDDELAY - 2:0], not_done};
			end
			else begin : genblk1
				always @(posedge i_clk)
					if (i_reset)
						sck_pipe <= 0;
					else
						sck_pipe <= actual_sck;
				always @(posedge i_clk)
					if (i_reset || !i_wb_cyc)
						ack_pipe <= 0;
					else
						ack_pipe <= dly_ack;
				always @(posedge i_clk)
					if (i_reset)
						stall_pipe <= -1;
					else
						stall_pipe <= not_done;
			end
			always @(*) begin
				not_done = (i_wb_stb || i_cfg_stb) && !o_wb_stall;
				if (clk_ctr > 1)
					not_done = 1'b1;
				if ((clk_ctr == 1) && !ckstb)
					not_done = 1'b1;
			end
			always @(*) o_wb_ack = ack_pipe[RDDELAY - 1];
			always @(*) read_sck = sck_pipe[RDDELAY - 1];
			always @(*) xtra_stall = |stall_pipe;
		end
	endgenerate
	always @(posedge i_clk) begin
		if (read_sck) begin
			if (OPT_ENDIANSWAP) begin
				if (!o_qspi_mod[1])
					o_wb_data <= {o_wb_data[30:24], i_qspi_dat[1], o_wb_data[22:16], o_wb_data[31], o_wb_data[14:8], o_wb_data[23], o_wb_data[6:0], o_wb_data[15]};
				else
					o_wb_data <= {o_wb_data[27:24], i_qspi_dat, o_wb_data[19:16], o_wb_data[31:28], o_wb_data[11:8], o_wb_data[23:20], o_wb_data[3:0], o_wb_data[15:12]};
				if (cfg_mode) begin
					if (!o_qspi_mod[1])
						o_wb_data[7:0] <= {o_wb_data[6:0], i_qspi_dat[1]};
					else
						o_wb_data[7:0] <= {o_wb_data[3:0], i_qspi_dat};
				end
			end
			else if (!o_qspi_mod[1])
				o_wb_data <= {o_wb_data[30:0], i_qspi_dat[1]};
			else
				o_wb_data <= {o_wb_data[27:0], i_qspi_dat};
		end
		if (OPT_CFG && cfg_mode)
			o_wb_data[16:8] <= {4'b0000, cfg_mode, cfg_speed, 1'b0, cfg_dir, cfg_cs};
	end
	initial cfg_mode = 1'b0;
	always @(posedge i_clk)
		if (i_reset || !OPT_CFG)
			cfg_mode <= 1'b0;
		else if ((i_cfg_stb && !o_wb_stall) && i_wb_we)
			cfg_mode <= i_wb_data[CFG_MODE];
	initial cfg_cs = 1'b0;
	always @(posedge i_clk)
		if (i_reset || !OPT_CFG)
			cfg_cs <= 1'b0;
		else if ((i_cfg_stb && !o_wb_stall) && i_wb_we)
			cfg_cs <= !i_wb_data[USER_CS_n] && i_wb_data[CFG_MODE];
	initial cfg_speed = 1'b0;
	initial cfg_dir = 1'b0;
	always @(posedge i_clk)
		if (!OPT_CFG) begin
			cfg_speed <= 1'b0;
			cfg_dir <= 1'b0;
		end
		else if ((i_cfg_stb && !o_wb_stall) && i_wb_we) begin
			cfg_speed <= i_wb_data[QSPEED_BIT];
			cfg_dir <= i_wb_data[DIR_BIT];
		end
	wire unused;
	assign unused = &{1'b0, i_wb_data[31:12]};
endmodule
module ibex_simple_system (
	clk_sys,
	rst_async_n,
	scl_pad_i,
	scl_pad_o,
	scl_padoen_o,
	sda_pad_i,
	sda_pad_o,
	sda_padoen_o,
	ext_pad_i,
	gpio_o,
	gpio_oe,
	o_qspi_sck,
	o_qspi_cs_n,
	o_qspi_mod,
	o_qspi_dat,
	i_qspi_dat
);
	parameter [0:0] ICache = 1'b0;
	parameter IMEM_1_InitFile = "";
	parameter IMEM_2_InitFile = "";
	parameter DMEM_InitFile = "";
	input wire clk_sys;
	input wire rst_async_n;
	input wire scl_pad_i;
	output wire scl_pad_o;
	output wire scl_padoen_o;
	input wire sda_pad_i;
	output wire sda_pad_o;
	output wire sda_padoen_o;
	input wire [1:0] ext_pad_i;
	output wire [1:0] gpio_o;
	output wire [1:0] gpio_oe;
	output wire o_qspi_sck;
	output wire o_qspi_cs_n;
	output wire [1:0] o_qspi_mod;
	output wire [3:0] o_qspi_dat;
	input wire [3:0] i_qspi_dat;
	wire rst_sync_n;
	wire rst_core_n;
	wire gpio_int;
	wire [1:0] gpio_aux;
	wire i2c_int;
	wire uart_rx_int_o;
	wire uart_tx_int_o;
	wire uart_rx_i;
	wire uart_tx_o;
	wire pit_irq;
	localparam signed [31:0] NUM_MASTERS = 3;
	localparam signed [31:0] NUM_SLAVES = 5;
	localparam signed [31:0] PIT_SLAVE_PORT_NUM = 4;
	localparam [31:0] imem_base_addr = 32'ha0000000;
	localparam [31:0] imem_size = 'h2000;
	localparam [31:0] dmem_base_addr = 32'h90000000;
	localparam [31:0] dmem_size = 'h1000;
	localparam [31:0] uart_base_addr = 32'h50000000;
	localparam [31:0] uart_size = 'h10;
	localparam [31:0] gpio_base_addr = 32'h40000000;
	localparam [31:0] gpio_size = 'h40;
	localparam [31:0] i2c_base_addr = 32'h30000000;
	localparam [31:0] i2c_size = 'h14;
	localparam [31:0] pit_base_addr = 32'h20000000;
	localparam [31:0] pit_size = 'h10;
	localparam [31:0] spi_flash_base_addr = 32'h80000000;
	localparam [31:0] spi_flash_size = 'h2000;
	areset_sync #(.NumRegs(4)) u_areset_sync(
		.clk_i(clk_sys),
		.i_rst_async(rst_async_n),
		.o_rst_sync(rst_sync_n)
	);
	genvar _arr_55720;
	generate
		for (_arr_55720 = 0; _arr_55720 <= 2; _arr_55720 = _arr_55720 + 1) begin : wbm
			wire rst;
			wire clk;
			wire ack;
			wire [31:0] adr;
			wire cyc;
			wire stall;
			wire stb;
			wire we;
			wire [3:0] sel;
			wire err;
			wire [31:0] dat_m;
			wire [31:0] dat_s;
		end
		for (_arr_55720 = 0; _arr_55720 <= 2; _arr_55720 = _arr_55720 + 1) begin : wbm_port_bindings
			assign wbm[_arr_55720].rst = rst_sync_n;
			assign wbm[_arr_55720].clk = clk_sys;
		end
	endgenerate
	genvar _arr_3103E;
	generate
		for (_arr_3103E = 0; _arr_3103E <= 4; _arr_3103E = _arr_3103E + 1) begin : wbs
			wire rst;
			wire clk;
			reg ack;
			wire [31:0] adr;
			wire cyc;
			wire stall;
			wire stb;
			wire we;
			wire [3:0] sel;
			wire err;
			wire [31:0] dat_m;
			wire [31:0] dat_s;
		end
		for (_arr_3103E = 0; _arr_3103E <= 4; _arr_3103E = _arr_3103E + 1) begin : wbs_port_bindings
			assign wbs[_arr_3103E].rst = rst_sync_n;
			assign wbs[_arr_3103E].clk = clk_sys;
		end
	endgenerate
	localparam _bbase_3E301_wb = 0;
	generate
		if (1) begin : u_bootloader
			reg _sv2v_0;
			localparam _mbase_wb = _bbase_3E301_wb;
			wire clk;
			reg rst_core_n;
			reg [3:0] state;
			reg [3:0] next_state;
			reg next_rst_core_n;
			reg sram_access;
			reg [31:0] mem_index;
			reg [31:0] next_mem_index;
			wire [31:0] mem_addr;
			reg [31:0] mem_addr_reg;
			reg [4:0] page_buffer_index;
			reg [4:0] next_page_buffer_index;
			reg [15:0] addr_pointer;
			reg [15:0] next_addr_pointer;
			reg [31:0] data_word;
			reg start;
			reg we;
			reg [31:0] wdata;
			wire [31:0] rdata;
			wire done;
			wire busy;
			reg generate_STA;
			reg generate_NACK;
			reg generate_STO;
			localparam _bbase_50FD7_wb = 0;
			if (1) begin : i_i2c_fsm
				reg _sv2v_0;
				wire clk;
				wire start;
				wire [31:0] w_data;
				wire we;
				wire busy;
				wire done;
				reg [31:0] r_data;
				wire generate_STA;
				wire last_read;
				wire generate_NACK;
				wire generate_STO;
				wire sram_access;
				wire [31:0] mem_addr;
				localparam _mbase_wb = _bbase_50FD7_wb;
				reg [3:0] state;
				reg [3:0] next_state;
				reg wb_start;
				reg [31:0] wb_addr;
				reg [31:0] wb_wdata;
				wire [31:0] wb_rdata;
				reg wb_we;
				wire wb_done;
				wire wb_busy;
				reg [31:0] next_rdata;
				localparam _bbase_CD147_wb = 0;
				if (1) begin : i_wb_access
					reg _sv2v_0;
					wire clk;
					wire start;
					wire [31:0] addr;
					wire [31:0] wdata;
					wire we;
					wire done;
					wire [31:0] rdata;
					wire busy;
					localparam _mbase_wb = _bbase_CD147_wb;
					reg [1:0] state;
					reg [1:0] next_state;
					reg [31:0] rdata_reg;
					always @(posedge clk or negedge ibex_simple_system.wbm[_mbase_wb].rst)
						if (!ibex_simple_system.wbm[_mbase_wb].rst)
							state <= 2'd0;
						else
							state <= next_state;
					always @(posedge clk)
						if (((state == 2'd2) && ibex_simple_system.wbm[_mbase_wb].ack) && !we)
							rdata_reg <= ibex_simple_system.wbm[_mbase_wb].dat_s;
					assign ibex_simple_system.wbm[_mbase_wb].sel = 4'b1111;
					assign ibex_simple_system.wbm[_mbase_wb].adr = ((state == 2'd1) || (state == 2'd2) ? addr : 32'd0);
					assign ibex_simple_system.wbm[_mbase_wb].dat_m = wdata;
					assign ibex_simple_system.wbm[_mbase_wb].we = ((state == 2'd1) || (state == 2'd2) ? we : 1'b0);
					assign ibex_simple_system.wbm[_mbase_wb].cyc = (state == 2'd1) || (state == 2'd2);
					assign ibex_simple_system.wbm[_mbase_wb].stb = (state == 2'd1) || (state == 2'd2);
					assign rdata = rdata_reg;
					assign busy = (state != 2'd0) && (state != 2'd3);
					assign done = state == 2'd3;
					always @(*) begin
						if (_sv2v_0)
							;
						next_state = state;
						case (state)
							2'd0:
								if (start)
									next_state = 2'd1;
							2'd1: next_state = 2'd2;
							2'd2:
								if (ibex_simple_system.wbm[_mbase_wb].ack)
									next_state = 2'd3;
							2'd3: next_state = 2'd0;
						endcase
					end
					initial _sv2v_0 = 0;
				end
				assign i_wb_access.clk = clk;
				assign i_wb_access.start = wb_start;
				assign i_wb_access.addr = wb_addr;
				assign i_wb_access.wdata = wb_wdata;
				assign i_wb_access.we = wb_we;
				assign wb_done = i_wb_access.done;
				assign wb_rdata = i_wb_access.rdata;
				assign wb_busy = i_wb_access.busy;
				assign busy = state != 4'd1;
				assign done = state == 4'd11;
				always @(posedge clk or negedge ibex_simple_system.wbm[_mbase_wb].rst)
					if (!ibex_simple_system.wbm[_mbase_wb].rst) begin
						state <= 4'd0;
						r_data <= 32'd0;
					end
					else begin
						state <= next_state;
						r_data <= next_rdata;
					end
				always @(*) begin
					if (_sv2v_0)
						;
					next_state = state;
					wb_start = 0;
					wb_addr = 32'd0;
					wb_wdata = 32'd0;
					wb_we = 0;
					next_rdata = 32'd0;
					case (state)
						4'd0: begin
							wb_addr = 32'h30000000 + 32'h00000008;
							wb_wdata = 32'b00000000000000000000000010000000;
							wb_we = 1;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done)
								next_state = 4'd1;
						end
						4'd1:
							if (start) begin
								if (sram_access)
									next_state = (we ? 4'd9 : 4'd10);
								else
									next_state = (we ? 4'd2 : 4'd4);
							end
						4'd2: begin
							wb_addr = 32'h30000000 + 32'h0000000c;
							wb_wdata = w_data;
							wb_we = 1;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done)
								next_state = 4'd3;
						end
						4'd3: begin
							wb_addr = 32'h30000000 + 32'h00000010;
							wb_wdata = 32'b00000000000000000000000000010000;
							wb_wdata = wb_wdata | (generate_STA ? 32'b00000000000000000000000010000000 : 1'b0);
							wb_wdata = wb_wdata | (generate_STO ? 32'b00000000000000000000000001000000 : 1'b0);
							wb_we = 1;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done)
								next_state = 4'd5;
						end
						4'd4: begin
							wb_addr = 32'h30000000 + 32'h00000010;
							wb_wdata = (generate_NACK ? 32'b00000000000000000000000000100000 | 32'b00000000000000000000000000001000 : 32'b00000000000000000000000000100000);
							wb_we = 1;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done)
								next_state = 4'd5;
						end
						4'd5: begin
							wb_addr = 32'h30000000 + 32'h00000010;
							wb_we = 0;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done) begin
								if (wb_rdata & 32'b00000000000000000000000000000010)
									next_state = 4'd5;
								else
									next_state = (we ? 4'd6 : 4'd7);
							end
						end
						4'd6: begin
							wb_addr = 32'h30000000 + 32'h00000010;
							wb_we = 0;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done) begin
								if (wb_rdata & 32'b00000000000000000000000010000000)
									next_state = 4'd2;
								else
									next_state = 4'd11;
							end
						end
						4'd7: begin
							wb_addr = 32'h30000000 + 32'h0000000c;
							wb_we = 0;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done) begin
								next_rdata = wb_rdata;
								next_state = 4'd11;
							end
						end
						4'd8: begin
							wb_addr = 32'h30000000 + 32'h00000010;
							wb_wdata = 32'b00000000000000000000000001000000;
							wb_we = 1;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done)
								next_state = 4'd11;
						end
						4'd9: begin
							wb_addr = mem_addr;
							wb_wdata = w_data;
							wb_we = 1;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done)
								next_state = (last_read ? 4'd8 : 4'd11);
						end
						4'd10: begin
							wb_addr = mem_addr;
							wb_we = 0;
							if (!wb_busy && !wb_done)
								wb_start = 1;
							else if (wb_done) begin
								next_rdata = wb_rdata;
								next_state = 4'd11;
							end
						end
						4'd11: next_state = 4'd1;
					endcase
				end
				initial _sv2v_0 = 0;
			end
			assign i_i2c_fsm.clk = clk;
			assign i_i2c_fsm.start = start;
			assign i_i2c_fsm.w_data = wdata;
			assign i_i2c_fsm.we = we;
			assign busy = i_i2c_fsm.busy;
			assign done = i_i2c_fsm.done;
			assign rdata = i_i2c_fsm.r_data;
			assign i_i2c_fsm.generate_STA = generate_STA;
			assign i_i2c_fsm.last_read = last_read;
			assign i_i2c_fsm.generate_NACK = generate_NACK;
			assign i_i2c_fsm.generate_STO = generate_STO;
			assign i_i2c_fsm.sram_access = sram_access;
			assign i_i2c_fsm.mem_addr = mem_addr;
			assign mem_addr = mem_addr_reg;
			wire last_read;
			assign last_read = mem_index == ((32'd8192 + 32'd4096) - 4);
			always @(posedge clk or negedge ibex_simple_system.wbm[_mbase_wb].rst)
				if (!ibex_simple_system.wbm[_mbase_wb].rst) begin
					state <= 4'd15;
					mem_index <= 1'sb0;
					rst_core_n <= 0;
					data_word <= 32'd0;
					page_buffer_index <= 1'sb0;
					addr_pointer <= 16'h0000;
				end
				else begin
					state <= next_state;
					mem_index <= next_mem_index;
					page_buffer_index <= next_page_buffer_index;
					addr_pointer <= next_addr_pointer;
					rst_core_n <= next_rst_core_n;
					case (state)
						4'd4:
							if (done)
								data_word[7:0] <= rdata[7:0];
						4'd5:
							if (done)
								data_word[15:8] <= rdata[7:0];
						4'd6:
							if (done)
								data_word[23:16] <= rdata[7:0];
						4'd7:
							if (done)
								data_word[31:24] <= rdata[7:0];
						4'd9:
							if (done)
								data_word <= rdata;
					endcase
				end
			always @(*) begin
				if (_sv2v_0)
					;
				next_state = state;
				next_mem_index = mem_index;
				next_page_buffer_index = page_buffer_index;
				next_rst_core_n = rst_core_n;
				start = 0;
				wdata = 1'sb0;
				we = 0;
				sram_access = 0;
				mem_addr_reg = 1'sb0;
				generate_STA = 0;
				generate_NACK = 0;
				generate_STO = 0;
				next_addr_pointer = addr_pointer;
				case (state)
					4'd0: begin
						we = 1;
						wdata = 32'b00000000000000000000000010100000;
						generate_STA = 1;
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd1;
					end
					4'd1: begin
						we = 1;
						wdata = addr_pointer[15:8];
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd2;
					end
					4'd2: begin
						we = 1;
						wdata = addr_pointer[7:0];
						if (!busy && !done)
							start = 1;
						else if (done) begin
							if (mem_index > 0) begin
								next_state = 4'd9;
								if (mem_index == (32'd8192 + 32'd4096))
									next_mem_index = 0;
							end
							else
								next_state = 4'd3;
						end
					end
					4'd3: begin
						we = 1;
						wdata = 32'b00000000000000000000000010100001;
						generate_STA = 1;
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd4;
					end
					4'd4: begin
						we = 0;
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd5;
					end
					4'd5: begin
						we = 0;
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd6;
					end
					4'd6: begin
						we = 0;
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd7;
					end
					4'd7: begin
						we = 0;
						generate_NACK = (last_read ? 1 : 0);
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd8;
					end
					4'd8: begin
						if (mem_index < 32'd8192)
							mem_addr_reg = 32'h80000000 + mem_index;
						else
							mem_addr_reg = (32'h90000000 + mem_index) - 32'd8192;
						we = 1;
						sram_access = 1;
						wdata = data_word;
						if (!busy && !done)
							start = 1;
						else if (done) begin
							next_mem_index = mem_index + 4;
							next_addr_pointer = 16'h3000;
							next_state = (last_read ? 4'd15 : 4'd4);
						end
					end
					4'd9: begin
						if (mem_index < 32'd8192)
							mem_addr_reg = 32'h80000000 + mem_index;
						else
							mem_addr_reg = (32'h90000000 + mem_index) - 32'd8192;
						we = 0;
						sram_access = 1;
						if (!busy && !done)
							start = 1;
						else if (done) begin
							next_mem_index = mem_index + 4;
							next_state = 4'd11;
						end
					end
					4'd11: begin
						we = 1;
						wdata = data_word[7:0];
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd12;
					end
					4'd12: begin
						we = 1;
						wdata = data_word[15:8];
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd13;
					end
					4'd13: begin
						we = 1;
						wdata = data_word[23:16];
						if (!busy && !done)
							start = 1;
						else if (done)
							next_state = 4'd14;
					end
					4'd14: begin
						we = 1;
						wdata = data_word[31:24];
						generate_STO = (page_buffer_index == {'d5 {1'b1}} ? 1'b1 : 1'b0);
						if (!busy && !done)
							start = 1;
						else if (done) begin
							if (mem_index == (32'd8192 + 32'd4096))
								next_state = 4'd15;
							else if (page_buffer_index == {'d5 {1'b1}}) begin
								next_page_buffer_index = 0;
								next_state = 4'd0;
								next_addr_pointer = (addr_pointer + {7 {1'b1}}) + 1;
							end
							else begin
								next_page_buffer_index = page_buffer_index + 1;
								next_state = 4'd9;
							end
						end
					end
					4'd15: next_rst_core_n = 1;
				endcase
			end
			initial _sv2v_0 = 0;
		end
	endgenerate
	assign u_bootloader.clk = clk_sys;
	assign rst_core_n = u_bootloader.rst_core_n;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	localparam _bbase_4E807_instr_wb = 2;
	localparam _bbase_4E807_data_wb = 1;
	localparam _param_4E807_ICache = ICache;
	generate
		if (1) begin : u_wb_ibex_top
			localparam [0:0] PMPEnable = 1'b0;
			localparam [31:0] PMPGranularity = 0;
			localparam [31:0] PMPNumRegions = 4;
			localparam [31:0] MHPMCounterNum = 0;
			localparam [31:0] MHPMCounterWidth = 40;
			localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
			localparam [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
			localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
			localparam [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
			localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
			localparam [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
			localparam [0:0] RV32E = 1'b0;
			localparam integer RV32M = 32'sd2;
			localparam integer RV32B = 32'sd0;
			localparam integer RegFile = 32'sd0;
			localparam [0:0] BranchTargetALU = 1'b0;
			localparam [0:0] WritebackStage = 1'b0;
			localparam [0:0] ICache = _param_4E807_ICache;
			localparam [0:0] ICacheECC = 1'b0;
			localparam [0:0] BranchPredictor = 1'b0;
			localparam [0:0] DbgTriggerEn = 1'b1;
			localparam [31:0] DbgHwBreakNum = 1;
			localparam [0:0] SecureIbex = 1'b0;
			localparam [0:0] ICacheScramble = 1'b0;
			localparam [31:0] ICacheScrNumPrinceRoundsHalf = 2;
			localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
			localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
			localparam [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
			localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
			localparam [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
			localparam [31:0] DmBaseAddr = 32'h1a110000;
			localparam [31:0] DmAddrMask = 32'h00000fff;
			localparam [31:0] DmHaltAddr = 32'h1a110800;
			localparam [31:0] DmExceptionAddr = 32'h1a110808;
			localparam [31:0] ibex_pkg_SCRAMBLE_KEY_W = 128;
			localparam [127:0] ibex_pkg_RndCnstIbexKeyDefault = 128'h14e8cecae3040d5e12286bb3cc113298;
			localparam [127:0] RndCnstIbexKey = ibex_pkg_RndCnstIbexKeyDefault;
			localparam [31:0] ibex_pkg_SCRAMBLE_NONCE_W = 64;
			localparam [63:0] ibex_pkg_RndCnstIbexNonceDefault = 64'hf79780bc735f3843;
			localparam [63:0] RndCnstIbexNonce = ibex_pkg_RndCnstIbexNonceDefault;
			wire clk;
			wire rst_n;
			localparam _mbase_instr_wb = _bbase_4E807_instr_wb;
			localparam _mbase_data_wb = _bbase_4E807_data_wb;
			wire test_en;
			wire [9:0] ram_cfg;
			wire [31:0] hart_id;
			wire [31:0] boot_addr;
			wire irq_software;
			wire irq_timer;
			wire irq_external;
			wire [14:0] irq_fast;
			wire irq_nm;
			wire scramble_key_valid;
			wire [127:0] scramble_key;
			wire [63:0] scramble_nonce;
			wire scramble_req;
			wire debug_req;
			wire [159:0] crash_dump;
			wire double_fault_seen;
			localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
			wire [3:0] fetch_enable;
			wire alert_minor;
			wire alert_major_internal;
			wire alert_major_bus;
			wire core_sleep;
			wire scan_rst_n;
			if (1) begin : instr_core
				wire clk;
				wire rst_n;
				wire req;
				wire gnt;
				wire rvalid;
				wire we;
				wire [3:0] be;
				wire [31:0] addr;
				wire [31:0] wdata;
				wire [31:0] rdata;
				wire err;
			end
			assign instr_core.rst_n = rst_n;
			assign instr_core.clk = clk;
			if (1) begin : data_core
				wire clk;
				wire rst_n;
				wire req;
				wire gnt;
				wire rvalid;
				wire we;
				wire [3:0] be;
				wire [31:0] addr;
				wire [31:0] wdata;
				wire [31:0] rdata;
				wire err;
			end
			assign data_core.rst_n = rst_n;
			assign data_core.clk = clk;
			localparam [6:0] sv2v_uu_inst_ibex_top_ext_instr_rdata_intg_i_0 = 1'sb0;
			localparam [6:0] sv2v_uu_inst_ibex_top_ext_data_rdata_intg_i_0 = 1'sb0;
			ibex_top #(
				.PMPEnable(PMPEnable),
				.PMPGranularity(PMPGranularity),
				.PMPNumRegions(PMPNumRegions),
				.MHPMCounterNum(MHPMCounterNum),
				.MHPMCounterWidth(MHPMCounterWidth),
				.PMPRstCfg(PMPRstCfg),
				.PMPRstAddr(PMPRstAddr),
				.PMPRstMsecCfg(PMPRstMsecCfg),
				.RV32E(RV32E),
				.RV32M(RV32M),
				.RV32B(RV32B),
				.RegFile(RegFile),
				.BranchTargetALU(BranchTargetALU),
				.WritebackStage(WritebackStage),
				.ICache(ICache),
				.ICacheECC(ICacheECC),
				.BranchPredictor(BranchPredictor),
				.DbgTriggerEn(DbgTriggerEn),
				.DbgHwBreakNum(DbgHwBreakNum),
				.SecureIbex(SecureIbex),
				.ICacheScramble(ICacheScramble),
				.ICacheScrNumPrinceRoundsHalf(ICacheScrNumPrinceRoundsHalf),
				.RndCnstLfsrSeed(RndCnstLfsrSeed),
				.RndCnstLfsrPerm(RndCnstLfsrPerm),
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.DmHaltAddr(DmHaltAddr),
				.DmExceptionAddr(DmExceptionAddr)
			) inst_ibex_top(
				.clk_i(clk),
				.rst_ni(rst_n),
				.test_en_i(test_en),
				.ram_cfg_i(ram_cfg),
				.hart_id_i(hart_id),
				.boot_addr_i(boot_addr),
				.instr_req_o(instr_core.req),
				.instr_gnt_i(instr_core.gnt),
				.instr_rvalid_i(instr_core.rvalid),
				.instr_addr_o(instr_core.addr),
				.instr_rdata_i(instr_core.rdata),
				.instr_rdata_intg_i(sv2v_uu_inst_ibex_top_ext_instr_rdata_intg_i_0),
				.instr_err_i(instr_core.err),
				.data_req_o(data_core.req),
				.data_gnt_i(data_core.gnt),
				.data_rvalid_i(data_core.rvalid),
				.data_we_o(data_core.we),
				.data_be_o(data_core.be),
				.data_addr_o(data_core.addr),
				.data_wdata_o(data_core.wdata),
				.data_wdata_intg_o(),
				.data_rdata_i(data_core.rdata),
				.data_rdata_intg_i(sv2v_uu_inst_ibex_top_ext_data_rdata_intg_i_0),
				.data_err_i(data_core.err),
				.irq_software_i(irq_software),
				.irq_timer_i(irq_timer),
				.irq_external_i(irq_external),
				.irq_fast_i(irq_fast),
				.irq_nm_i(irq_nm),
				.scramble_key_valid_i(scramble_key_valid),
				.scramble_key_i(scramble_key),
				.scramble_nonce_i(scramble_nonce),
				.scramble_req_o(scramble_req),
				.debug_req_i(debug_req),
				.crash_dump_o(crash_dump),
				.double_fault_seen_o(double_fault_seen),
				.fetch_enable_i(fetch_enable),
				.alert_minor_o(alert_minor),
				.alert_major_internal_o(alert_major_internal),
				.alert_major_bus_o(alert_major_bus),
				.core_sleep_o(core_sleep),
				.scan_rst_ni(scan_rst_n)
			);
			assign instr_core.we = 1'b0;
			assign instr_core.be = 1'sb0;
			assign instr_core.wdata = 1'sb0;
			localparam _bbase_56B76_wb = 2;
			if (1) begin : instr_core2wb
				localparam pending = 16;
				localparam _mbase_wb = _bbase_56B76_wb;
				reg signed [4:0] counts;
				assign ibex_simple_system.u_wb_ibex_top.instr_core.gnt = ibex_simple_system.u_wb_ibex_top.instr_core.req & ~ibex_simple_system.wbm[_mbase_wb].stall;
				assign ibex_simple_system.u_wb_ibex_top.instr_core.rvalid = ibex_simple_system.wbm[_mbase_wb].cyc & (ibex_simple_system.wbm[_mbase_wb].ack | ibex_simple_system.wbm[_mbase_wb].err);
				assign ibex_simple_system.u_wb_ibex_top.instr_core.err = ibex_simple_system.wbm[_mbase_wb].err;
				assign ibex_simple_system.wbm[_mbase_wb].stb = ibex_simple_system.u_wb_ibex_top.instr_core.req;
				assign ibex_simple_system.wbm[_mbase_wb].adr = ibex_simple_system.u_wb_ibex_top.instr_core.addr;
				assign ibex_simple_system.wbm[_mbase_wb].we = ibex_simple_system.u_wb_ibex_top.instr_core.we;
				assign ibex_simple_system.wbm[_mbase_wb].sel = (ibex_simple_system.u_wb_ibex_top.instr_core.we ? ibex_simple_system.u_wb_ibex_top.instr_core.be : {4 {1'sb1}});
				assign ibex_simple_system.u_wb_ibex_top.instr_core.rdata = ibex_simple_system.wbm[_mbase_wb].dat_s;
				assign ibex_simple_system.wbm[_mbase_wb].dat_m = ibex_simple_system.u_wb_ibex_top.instr_core.wdata;
				always @(posedge ibex_simple_system.u_wb_ibex_top.instr_core.clk or negedge ibex_simple_system.u_wb_ibex_top.instr_core.rst_n)
					if (!ibex_simple_system.u_wb_ibex_top.instr_core.rst_n)
						counts <= 0;
					else if (ibex_simple_system.u_wb_ibex_top.instr_core.req && ibex_simple_system.u_wb_ibex_top.instr_core.gnt)
						counts <= (ibex_simple_system.wbm[_mbase_wb].cyc && ibex_simple_system.wbm[_mbase_wb].ack ? counts : counts + 1);
					else if (ibex_simple_system.wbm[_mbase_wb].cyc && ibex_simple_system.wbm[_mbase_wb].ack)
						counts <= counts - 1;
				assign ibex_simple_system.wbm[_mbase_wb].cyc = ibex_simple_system.u_wb_ibex_top.instr_core.req || (counts > 0);
			end
			localparam _bbase_3F487_wb = 1;
			if (1) begin : data_core2wb
				localparam pending = 16;
				localparam _mbase_wb = _bbase_3F487_wb;
				reg signed [4:0] counts;
				assign ibex_simple_system.u_wb_ibex_top.data_core.gnt = ibex_simple_system.u_wb_ibex_top.data_core.req & ~ibex_simple_system.wbm[_mbase_wb].stall;
				assign ibex_simple_system.u_wb_ibex_top.data_core.rvalid = ibex_simple_system.wbm[_mbase_wb].cyc & (ibex_simple_system.wbm[_mbase_wb].ack | ibex_simple_system.wbm[_mbase_wb].err);
				assign ibex_simple_system.u_wb_ibex_top.data_core.err = ibex_simple_system.wbm[_mbase_wb].err;
				assign ibex_simple_system.wbm[_mbase_wb].stb = ibex_simple_system.u_wb_ibex_top.data_core.req;
				assign ibex_simple_system.wbm[_mbase_wb].adr = ibex_simple_system.u_wb_ibex_top.data_core.addr;
				assign ibex_simple_system.wbm[_mbase_wb].we = ibex_simple_system.u_wb_ibex_top.data_core.we;
				assign ibex_simple_system.wbm[_mbase_wb].sel = (ibex_simple_system.u_wb_ibex_top.data_core.we ? ibex_simple_system.u_wb_ibex_top.data_core.be : {4 {1'sb1}});
				assign ibex_simple_system.u_wb_ibex_top.data_core.rdata = ibex_simple_system.wbm[_mbase_wb].dat_s;
				assign ibex_simple_system.wbm[_mbase_wb].dat_m = ibex_simple_system.u_wb_ibex_top.data_core.wdata;
				always @(posedge ibex_simple_system.u_wb_ibex_top.data_core.clk or negedge ibex_simple_system.u_wb_ibex_top.data_core.rst_n)
					if (!ibex_simple_system.u_wb_ibex_top.data_core.rst_n)
						counts <= 0;
					else if (ibex_simple_system.u_wb_ibex_top.data_core.req && ibex_simple_system.u_wb_ibex_top.data_core.gnt)
						counts <= (ibex_simple_system.wbm[_mbase_wb].cyc && ibex_simple_system.wbm[_mbase_wb].ack ? counts : counts + 1);
					else if (ibex_simple_system.wbm[_mbase_wb].cyc && ibex_simple_system.wbm[_mbase_wb].ack)
						counts <= counts - 1;
				assign ibex_simple_system.wbm[_mbase_wb].cyc = ibex_simple_system.u_wb_ibex_top.data_core.req || (counts > 0);
			end
		end
	endgenerate
	assign u_wb_ibex_top.clk = clk_sys;
	assign u_wb_ibex_top.rst_n = rst_core_n;
	assign u_wb_ibex_top.test_en = 1'b0;
	assign u_wb_ibex_top.ram_cfg = 1'sb0;
	assign u_wb_ibex_top.hart_id = 32'h00000000;
	assign u_wb_ibex_top.boot_addr = 32'h80000000;
	assign u_wb_ibex_top.irq_software = 1'b0;
	assign u_wb_ibex_top.irq_timer = pit_irq;
	assign u_wb_ibex_top.irq_external = gpio_int;
	assign u_wb_ibex_top.irq_fast = {9'b000000000, uart_tx_int_o, uart_rx_int_o, 2'b00, i2c_int, 1'b0};
	assign u_wb_ibex_top.irq_nm = 1'b0;
	assign u_wb_ibex_top.scramble_key_valid = 1'b0;
	assign u_wb_ibex_top.scramble_key = 1'sb0;
	assign u_wb_ibex_top.scramble_nonce = 1'sb0;
	assign u_wb_ibex_top.debug_req = 1'b0;
	assign u_wb_ibex_top.fetch_enable = ibex_pkg_IbexMuBiOn;
	assign u_wb_ibex_top.scan_rst_n = 1'b0;
	localparam _bbase_AF6D0_wb = 0;
	generate
		if (1) begin : u_gpio
			localparam _mbase_wb = _bbase_AF6D0_wb;
			wire int_o;
			wire [1:0] aux_i;
			wire [1:0] ext_pad_i;
			wire [1:0] ext_pad_o;
			wire [1:0] ext_padoe_o;
			assign ibex_simple_system.wbs[_mbase_wb].stall = 1'b0;
			wire [1:1] sv2v_tmp_u_wb_gpio_wb_ack_o;
			always @(*) ibex_simple_system.wbs[_mbase_wb].ack = sv2v_tmp_u_wb_gpio_wb_ack_o;
			gpio_top u_wb_gpio(
				.wb_clk_i(ibex_simple_system.wbs[_mbase_wb].clk),
				.wb_rst_i_n(ibex_simple_system.wbs[_mbase_wb].rst),
				.wb_cyc_i(ibex_simple_system.wbs[_mbase_wb].cyc),
				.wb_adr_i(ibex_simple_system.wbs[_mbase_wb].adr[7:0]),
				.wb_dat_i(ibex_simple_system.wbs[_mbase_wb].dat_m),
				.wb_dat_o(ibex_simple_system.wbs[_mbase_wb].dat_s),
				.wb_sel_i(ibex_simple_system.wbs[_mbase_wb].sel),
				.wb_we_i(ibex_simple_system.wbs[_mbase_wb].we),
				.wb_stb_i(ibex_simple_system.wbs[_mbase_wb].stb),
				.wb_ack_o(sv2v_tmp_u_wb_gpio_wb_ack_o),
				.wb_err_o(ibex_simple_system.wbs[_mbase_wb].err),
				.wb_inta_o(int_o),
				.aux_i(aux_i),
				.ext_pad_i(ext_pad_i),
				.ext_pad_o(ext_pad_o),
				.ext_padoe_o(ext_padoe_o)
			);
		end
	endgenerate
	assign gpio_int = u_gpio.int_o;
	assign u_gpio.aux_i = gpio_aux;
	assign u_gpio.ext_pad_i = ext_pad_i;
	assign gpio_o = u_gpio.ext_pad_o;
	assign gpio_oe = u_gpio.ext_padoe_o;
	assign gpio_aux = {uart_tx_o, 1'b0};
	localparam _bbase_5EA00_wb = 3;
	generate
		if (1) begin : u_uart
			localparam _mbase_wb = _bbase_5EA00_wb;
			wire o_uart_rx_int;
			wire o_uart_tx_int;
			wire i_uart_rx;
			wire o_uart_tx;
			localparam [31:0] INITIAL_SETUP = 31'd868;
			assign ibex_simple_system.wbs[_mbase_wb].err = 1'b0;
			wire [1:1] sv2v_tmp_u_wb_uart_o_wb_ack;
			always @(*) ibex_simple_system.wbs[_mbase_wb].ack = sv2v_tmp_u_wb_uart_o_wb_ack;
			wbuart #(.INITIAL_SETUP(INITIAL_SETUP)) u_wb_uart(
				.i_clk(ibex_simple_system.wbs[_mbase_wb].clk),
				.i_reset_n(ibex_simple_system.wbs[_mbase_wb].rst),
				.i_wb_cyc(ibex_simple_system.wbs[_mbase_wb].cyc),
				.i_wb_stb(ibex_simple_system.wbs[_mbase_wb].stb),
				.i_wb_we(ibex_simple_system.wbs[_mbase_wb].we),
				.i_wb_addr(ibex_simple_system.wbs[_mbase_wb].adr[3:2]),
				.i_wb_sel(ibex_simple_system.wbs[_mbase_wb].sel),
				.o_wb_stall(ibex_simple_system.wbs[_mbase_wb].stall),
				.o_wb_ack(sv2v_tmp_u_wb_uart_o_wb_ack),
				.i_wb_data(ibex_simple_system.wbs[_mbase_wb].dat_m),
				.o_wb_data(ibex_simple_system.wbs[_mbase_wb].dat_s),
				.i_uart_rx(i_uart_rx),
				.o_uart_tx(o_uart_tx),
				.o_uart_rx_int(o_uart_rx_int),
				.o_uart_tx_int(o_uart_tx_int)
			);
		end
	endgenerate
	assign uart_rx_int_o = u_uart.o_uart_rx_int;
	assign uart_tx_int_o = u_uart.o_uart_tx_int;
	assign u_uart.i_uart_rx = ext_pad_i[0];
	assign uart_tx_o = u_uart.o_uart_tx;
	localparam _bbase_BCA4E_wb = 1;
	localparam _param_BCA4E_BOOT_I2C_PRESCALER = 16'd15;
	generate
		if (1) begin : u_i2c
			localparam _mbase_wb = _bbase_BCA4E_wb;
			wire int_o;
			wire scl_pad_i;
			wire scl_pad_o;
			wire scl_padoen_o;
			wire sda_pad_i;
			wire sda_pad_o;
			wire sda_padoen_o;
			localparam BOOT_I2C_PRESCALER = _param_BCA4E_BOOT_I2C_PRESCALER;
			wire [7:0] wb_dat_o_8;
			assign ibex_simple_system.wbs[_mbase_wb].stall = 1'b0;
			assign ibex_simple_system.wbs[_mbase_wb].err = 1'b0;
			assign ibex_simple_system.wbs[_mbase_wb].dat_s = {{24 {1'b0}}, wb_dat_o_8};
			wire [29:0] wb_adr_8;
			assign wb_adr_8 = ibex_simple_system.wbs[_mbase_wb].adr >> 2;
			wire [1:1] sv2v_tmp_u_wb_i2c_wb_ack_o;
			always @(*) ibex_simple_system.wbs[_mbase_wb].ack = sv2v_tmp_u_wb_i2c_wb_ack_o;
			i2c_master_top #(.BOOT_I2C_PRESCALER(BOOT_I2C_PRESCALER)) u_wb_i2c(
				.wb_clk_i(ibex_simple_system.wbs[_mbase_wb].clk),
				.wb_adr_i(wb_adr_8[2:0]),
				.wb_dat_i(ibex_simple_system.wbs[_mbase_wb].dat_m[7:0]),
				.wb_dat_o(wb_dat_o_8),
				.wb_we_i(ibex_simple_system.wbs[_mbase_wb].we),
				.wb_stb_i(ibex_simple_system.wbs[_mbase_wb].stb),
				.wb_cyc_i(ibex_simple_system.wbs[_mbase_wb].cyc),
				.wb_ack_o(sv2v_tmp_u_wb_i2c_wb_ack_o),
				.wb_inta_o(int_o),
				.arst_i(ibex_simple_system.wbs[_mbase_wb].rst),
				.scl_pad_i(scl_pad_i),
				.scl_pad_o(scl_pad_o),
				.scl_padoen_o(scl_padoen_o),
				.sda_pad_i(sda_pad_i),
				.sda_pad_o(sda_pad_o),
				.sda_padoen_o(sda_padoen_o)
			);
		end
	endgenerate
	assign i2c_int = u_i2c.int_o;
	assign u_i2c.scl_pad_i = scl_pad_i;
	assign scl_pad_o = u_i2c.scl_pad_o;
	assign scl_padoen_o = u_i2c.scl_padoen_o;
	assign u_i2c.sda_pad_i = sda_pad_i;
	assign sda_pad_o = u_i2c.sda_pad_o;
	assign sda_padoen_o = u_i2c.sda_padoen_o;
	localparam _bbase_3A12E_wb = 2;
	generate
		if (1) begin : u_pit
			localparam _mbase_wb = _bbase_3A12E_wb;
			wire pit_irq_o;
			wire [1:0] sel_to_pit;
			wire [15:0] data_to_pit;
			wire [15:0] data_from_pit;
			wire delayed_pit_ack;
			assign sel_to_pit = ibex_simple_system.wbs[_mbase_wb].sel[1:0];
			assign data_to_pit = ibex_simple_system.wbs[_mbase_wb].dat_m[15:0];
			assign ibex_simple_system.wbs[_mbase_wb].dat_s = {16'h0000, data_from_pit};
			assign ibex_simple_system.wbs[_mbase_wb].stall = 1'b0;
			assign ibex_simple_system.wbs[_mbase_wb].err = 1'b0;
			always @(posedge ibex_simple_system.wbs[_mbase_wb].clk or negedge ibex_simple_system.wbs[_mbase_wb].rst)
				if (!ibex_simple_system.wbs[_mbase_wb].rst)
					ibex_simple_system.wbs[_mbase_wb].ack <= 0;
				else
					ibex_simple_system.wbs[_mbase_wb].ack <= delayed_pit_ack;
			pit_top #(
				.DWIDTH(16),
				.SINGLE_CYCLE(1'b1)
			) u_wb_pit(
				.wb_clk_i(ibex_simple_system.wbs[_mbase_wb].clk),
				.arst_i(ibex_simple_system.wbs[_mbase_wb].rst),
				.wb_cyc_i(ibex_simple_system.wbs[_mbase_wb].cyc),
				.wb_stb_i(ibex_simple_system.wbs[_mbase_wb].stb),
				.wb_we_i(ibex_simple_system.wbs[_mbase_wb].we),
				.wb_adr_i(ibex_simple_system.wbs[_mbase_wb].adr[4:2]),
				.wb_sel_i(sel_to_pit),
				.wb_dat_i(data_to_pit),
				.wb_dat_o(data_from_pit),
				.wb_ack_o(delayed_pit_ack),
				.pit_irq_o(pit_irq_o),
				.pit_o(),
				.cnt_flag_o(),
				.cnt_sync_o(),
				.ext_sync_i(1'b0)
			);
		end
	endgenerate
	assign pit_irq = u_pit.pit_irq_o;
	localparam _bbase_08BBA_wb = 4;
	generate
		if (1) begin : u_spi_flash
			localparam _mbase_wb = _bbase_08BBA_wb;
			wire o_qspi_sck;
			wire o_qspi_cs_n;
			wire [1:0] o_qspi_mod;
			wire [3:0] o_qspi_dat;
			wire [3:0] i_qspi_dat;
			assign ibex_simple_system.wbs[_mbase_wb].err = 1'b0;
			wire stall;
			assign ibex_simple_system.wbs[_mbase_wb].stall = (ibex_simple_system.wbs[_mbase_wb].cyc & ibex_simple_system.wbs[_mbase_wb].stb ? stall : 1'b0);
			wire [1:1] sv2v_tmp_u_wb_spi_flash_o_wb_ack;
			always @(*) ibex_simple_system.wbs[_mbase_wb].ack = sv2v_tmp_u_wb_spi_flash_o_wb_ack;
			qflexpress #(
				.LGFLASHSZ(24),
				.OPT_STARTUP(1),
				.OPT_CLKDIV(1)
			) u_wb_spi_flash(
				.i_clk(ibex_simple_system.wbs[_mbase_wb].clk),
				.i_reset(~ibex_simple_system.wbs[_mbase_wb].rst),
				.i_wb_cyc(ibex_simple_system.wbs[_mbase_wb].cyc),
				.i_wb_stb(ibex_simple_system.wbs[_mbase_wb].stb),
				.i_cfg_stb(1'b0),
				.i_wb_we(ibex_simple_system.wbs[_mbase_wb].we),
				.i_wb_addr({2'b00, ibex_simple_system.wbs[_mbase_wb].adr[21:2]}),
				.o_wb_stall(stall),
				.o_wb_ack(sv2v_tmp_u_wb_spi_flash_o_wb_ack),
				.i_wb_data(ibex_simple_system.wbs[_mbase_wb].dat_m),
				.o_wb_data(ibex_simple_system.wbs[_mbase_wb].dat_s),
				.o_qspi_sck(o_qspi_sck),
				.o_qspi_cs_n(o_qspi_cs_n),
				.o_qspi_mod(o_qspi_mod),
				.o_qspi_dat(o_qspi_dat),
				.i_qspi_dat(i_qspi_dat)
			);
		end
	endgenerate
	assign o_qspi_sck = u_spi_flash.o_qspi_sck;
	assign o_qspi_cs_n = u_spi_flash.o_qspi_cs_n;
	assign o_qspi_mod = u_spi_flash.o_qspi_mod;
	assign o_qspi_dat = u_spi_flash.o_qspi_dat;
	assign u_spi_flash.i_qspi_dat = i_qspi_dat;
	localparam _bbase_C42A7_wbm = 0;
	localparam _bbase_C42A7_wbs = 0;
	localparam _param_C42A7_numm = NUM_MASTERS;
	localparam _param_C42A7_nums = NUM_SLAVES;
	localparam _param_C42A7_base_addr = {gpio_base_addr, i2c_base_addr, pit_base_addr, uart_base_addr, spi_flash_base_addr};
	localparam _param_C42A7_size = {gpio_size, i2c_size, pit_size, uart_size, spi_flash_size};
	generate
		if (1) begin : u_wb_interconnect
			reg _sv2v_0;
			localparam numm = _param_C42A7_numm;
			localparam nums = _param_C42A7_nums;
			localparam [159:0] base_addr = _param_C42A7_base_addr;
			localparam [159:0] size = _param_C42A7_size;
			localparam _mbase_wbm = 0;
			localparam _mbase_wbs = 0;
			reg cyc;
			reg stb;
			reg we;
			reg ack;
			reg err;
			reg stall;
			reg [31:0] adr;
			reg [3:0] sel;
			reg [31:0] dat_wr;
			reg [31:0] dat_rd;
			reg [2:0] gnt;
			reg [2:0] gnt1;
			reg [4:0] ss;
			reg [4:0] ss1;
			wire [2:0] wbm_cyc;
			wire [2:0] wbm_stb;
			wire [2:0] wbm_we;
			reg [2:0] wbm_ack;
			reg [2:0] wbm_err;
			reg [2:0] wbm_stall;
			wire [95:0] wbm_adr;
			wire [11:0] wbm_sel;
			wire [95:0] wbm_dat_i;
			reg [95:0] wbm_dat_o;
			genvar _gv_i_34;
			for (_gv_i_34 = 0; _gv_i_34 < numm; _gv_i_34 = _gv_i_34 + 1) begin : genblk1
				localparam i = _gv_i_34;
				assign wbm_cyc[i] = ibex_simple_system.wbm[i + _mbase_wbm].cyc;
				assign wbm_stb[i] = ibex_simple_system.wbm[i + _mbase_wbm].stb;
				assign wbm_we[i] = ibex_simple_system.wbm[i + _mbase_wbm].we;
				assign ibex_simple_system.wbm[i + _mbase_wbm].ack = wbm_ack[i];
				assign ibex_simple_system.wbm[i + _mbase_wbm].err = wbm_err[i];
				assign ibex_simple_system.wbm[i + _mbase_wbm].stall = wbm_stall[i];
				assign wbm_adr[i * 32+:32] = ibex_simple_system.wbm[i + _mbase_wbm].adr;
				assign wbm_sel[i * 4+:4] = ibex_simple_system.wbm[i + _mbase_wbm].sel;
				assign wbm_dat_i[i * 32+:32] = ibex_simple_system.wbm[i + _mbase_wbm].dat_m;
				assign ibex_simple_system.wbm[i + _mbase_wbm].dat_s = wbm_dat_o[i * 32+:32];
			end
			reg [4:0] wbs_cyc;
			reg [4:0] wbs_stb;
			reg [4:0] wbs_we;
			wire [4:0] wbs_ack;
			wire [4:0] wbs_err;
			wire [4:0] wbs_stall;
			reg [159:0] wbs_adr;
			reg [19:0] wbs_sel;
			wire [159:0] wbs_dat_i;
			reg [159:0] wbs_dat_o;
			genvar _gv_i_35;
			for (_gv_i_35 = 0; _gv_i_35 < nums; _gv_i_35 = _gv_i_35 + 1) begin : genblk2
				localparam i = _gv_i_35;
				assign ibex_simple_system.wbs[i + _mbase_wbs].cyc = wbs_cyc[i];
				assign ibex_simple_system.wbs[i + _mbase_wbs].stb = wbs_stb[i];
				assign ibex_simple_system.wbs[i + _mbase_wbs].we = wbs_we[i];
				assign wbs_ack[i] = ibex_simple_system.wbs[i + _mbase_wbs].ack;
				assign wbs_err[i] = ibex_simple_system.wbs[i + _mbase_wbs].err;
				assign wbs_stall[i] = ibex_simple_system.wbs[i + _mbase_wbs].stall;
				assign ibex_simple_system.wbs[i + _mbase_wbs].adr = wbs_adr[i * 32+:32];
				assign ibex_simple_system.wbs[i + _mbase_wbs].sel = wbs_sel[i * 4+:4];
				assign ibex_simple_system.wbs[i + _mbase_wbs].dat_m = wbs_dat_o[i * 32+:32];
				assign wbs_dat_i[i * 32+:32] = ibex_simple_system.wbs[i + _mbase_wbs].dat_s;
			end
			always @(*) begin : sv2v_autoblock_1
				reg signed [31:0] i;
				if (_sv2v_0)
					;
				for (i = 0; i < nums; i = i + 1)
					ss[i] = (adr >= base_addr[(4 - i) * 32+:32]) && (adr < (base_addr[(4 - i) * 32+:32] + size[(4 - i) * 32+:32]));
			end
			always @(posedge ibex_simple_system.wbs[0].clk or negedge ibex_simple_system.wbs[0].rst)
				if (!ibex_simple_system.wbs[0].rst)
					ss1 <= 1'sb0;
				else if (cyc && stb)
					ss1 <= ss;
			always @(*) begin : sv2v_autoblock_2
				reg [0:1] _sv2v_jump;
				_sv2v_jump = 2'b00;
				if (_sv2v_0)
					;
				gnt = 1'sb0;
				begin : sv2v_autoblock_3
					reg signed [31:0] i;
					begin : sv2v_autoblock_4
						reg signed [31:0] _sv2v_value_on_break;
						for (i = 0; i < numm; i = i + 1)
							if (_sv2v_jump < 2'b10) begin
								_sv2v_jump = 2'b00;
								if (wbm_cyc[i]) begin
									gnt[i] = 1'b1;
									_sv2v_jump = 2'b10;
								end
								_sv2v_value_on_break = i;
							end
						if (!(_sv2v_jump < 2'b10))
							i = _sv2v_value_on_break;
						if (_sv2v_jump != 2'b11)
							_sv2v_jump = 2'b00;
					end
				end
			end
			always @(posedge ibex_simple_system.wbm[0].clk or negedge ibex_simple_system.wbm[0].rst)
				if (!ibex_simple_system.wbm[0].rst)
					gnt1 <= 1'sb0;
				else if (cyc && stb)
					gnt1 <= gnt;
			always @(*) begin
				if (_sv2v_0)
					;
				cyc = 1'b0;
				adr = 1'sb0;
				stb = 1'b0;
				we = 1'b0;
				sel = 1'sb0;
				dat_wr = 1'sb0;
				begin : sv2v_autoblock_5
					reg signed [31:0] i;
					for (i = 0; i < numm; i = i + 1)
						begin
							cyc = cyc | wbm_cyc[i];
							if (gnt[i]) begin
								adr = wbm_adr[i * 32+:32];
								stb = wbm_stb[i];
								we = wbm_we[i];
								sel = wbm_sel[i * 4+:4];
								dat_wr = wbm_dat_i[i * 32+:32];
							end
						end
				end
			end
			always @(*) begin
				if (_sv2v_0)
					;
				ack = 1'b0;
				err = 1'b0;
				stall = 1'b0;
				dat_rd = 1'sb0;
				begin : sv2v_autoblock_6
					reg signed [31:0] i;
					for (i = 0; i < nums; i = i + 1)
						begin
							ack = ack | wbs_ack[i];
							err = err | wbs_err[i];
							stall = stall | wbs_stall[i];
							if (ss1[i])
								dat_rd = wbs_dat_i[i * 32+:32];
						end
				end
			end
			always @(*) begin
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_7
					reg signed [31:0] i;
					for (i = 0; i < numm; i = i + 1)
						begin
							wbm_stall[i] = 1'b1;
							if (gnt[i])
								wbm_stall[i] = stall;
						end
				end
			end
			always @(*) begin
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_8
					reg signed [31:0] i;
					for (i = 0; i < numm; i = i + 1)
						begin
							wbm_ack[i] = 1'b0;
							wbm_err[i] = 1'b0;
							wbm_dat_o[i * 32+:32] = 1'sb0;
							if (gnt1[i]) begin
								wbm_ack[i] = ack;
								wbm_err[i] = err;
								wbm_dat_o[i * 32+:32] = dat_rd;
							end
						end
				end
			end
			always @(*) begin : sv2v_autoblock_9
				reg signed [31:0] i;
				if (_sv2v_0)
					;
				for (i = 0; i < nums; i = i + 1)
					begin
						wbs_cyc[i] = cyc;
						wbs_adr[i * 32+:32] = 1'sb0;
						wbs_stb[i] = 1'b0;
						wbs_we[i] = we;
						wbs_sel[i * 4+:4] = 1'sb0;
						wbs_dat_o[i * 32+:32] = 1'sb0;
						if (ss[i]) begin
							wbs_adr[i * 32+:32] = adr;
							wbs_stb[i] = cyc & stb;
							wbs_sel[i * 4+:4] = sel;
							wbs_dat_o[i * 32+:32] = dat_wr;
						end
					end
			end
			initial _sv2v_0 = 0;
		end
	endgenerate
endmodule
