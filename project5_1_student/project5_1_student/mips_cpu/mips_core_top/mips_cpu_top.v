/* =========================================
* Top module for MIPS cores in the FPGA
* evaluation platform
*
* Author: Yisong Chang (changyisong@ict.ac.cn)
* Date: 19/03/2017
* Version: v0.0.1
*===========================================
*/

`timescale 10 ns / 1 ns

module mips_cpu_top (

`ifndef MIPS_CPU_FULL_SIMU
	//AXI AR Channel
    input  [13:0]	mips_cpu_axi_if_araddr,
    output			mips_cpu_axi_if_arready,
    input			mips_cpu_axi_if_arvalid,

	//AXI AW Channel
    input  [13:0]	mips_cpu_axi_if_awaddr,
    output			mips_cpu_axi_if_awready,
    input			mips_cpu_axi_if_awvalid,

	//AXI B Channel
    input			mips_cpu_axi_if_bready,
    output [1:0]	mips_cpu_axi_if_bresp,
    output			mips_cpu_axi_if_bvalid,

	//AXI R Channel
    output [31:0]	mips_cpu_axi_if_rdata,
    input			mips_cpu_axi_if_rready,
    output [1:0]	mips_cpu_axi_if_rresp,
    output			mips_cpu_axi_if_rvalid,

	//AXI W Channel
    input  [31:0]	mips_cpu_axi_if_wdata,
    output			mips_cpu_axi_if_wready,
    input  [3:0]	mips_cpu_axi_if_wstrb,
    input			mips_cpu_axi_if_wvalid,
`endif

`ifdef MIPS_CPU_FULL_SIMU
	output			mips_cpu_pc_sig,
	output [7:0]	mips_cpu_perf_sig,
`endif
	input			mips_cpu_clk,
    input			mips_cpu_reset
);

//at most 8KB ideal memory, so MEM_ADDR_WIDTH cannot exceed 13
localparam		MEM_ADDR_WIDTH = 11;

//AXI Lite IF ports to distributed memory
wire [MEM_ADDR_WIDTH - 3:0]		axi_lite_mem_addr;

wire			axi_lite_mem_wren;
wire [31:0]		axi_lite_mem_wdata;
wire			axi_lite_mem_rden;
wire [31:0]		axi_lite_mem_rdata;

//MIPS CPU ports to ideal memory
wire [31:0]		mips_mem_addr;
wire			MemWrite;
wire [31:0]		mips_mem_wdata;
wire			MemRead;
wire [31:0]		mips_mem_rdata;

(*mark_debug = "true"*) wire [31:0]		PC;
wire [31:0]		Instruction;

//read arbitration signal
wire			mips_mem_rd;
wire			axi_lite_mem_rd;

//Ideal memory ports
wire [MEM_ADDR_WIDTH - 3:0]	Waddr;
wire [MEM_ADDR_WIDTH - 3:0]	Raddr;

wire			Wren;
wire [31:0]		Wdata;
wire			Rden;
wire [31:0]		Rdata;

//Synchronized reset signal generated from AXI Lite IF
wire			mips_rst;

`ifdef MIPS_CPU_FULL_SIMU
reg [1:0]		mips_cpu_rst_i = 2'b11;
wire			mips_cpu_rst;
`endif

(*mark_debug = "true"*) wire [31:0]		cycle_cnt;
(*mark_debug = "true"*) wire [31:0]		inst_cnt;
(*mark_debug = "true"*) wire [31:0]		br_cnt;
(*mark_debug = "true"*) wire [31:0]		ld_cnt;
(*mark_debug = "true"*) wire [31:0]		st_cnt;
(*mark_debug = "true"*) wire [31:0]		user1_cnt;
(*mark_debug = "true"*) wire [31:0]		user2_cnt;
(*mark_debug = "true"*) wire [31:0]		user3_cnt;

`ifndef MIPS_CPU_FULL_SIMU
  //AXI Lite Interface Module
  //Receving memory read/write requests from ARM CPU cores
  axi_lite_if 	#(
	  .ADDR_WIDTH		(MEM_ADDR_WIDTH)
  ) u_axi_lite_slave (
	  .S_AXI_ACLK		(mips_cpu_clk),
	  .S_AXI_ARESETN	(~mips_cpu_reset),
	  
	  .S_AXI_ARADDR		(mips_cpu_axi_if_araddr),
	  .S_AXI_ARREADY	(mips_cpu_axi_if_arready),
	  .S_AXI_ARVALID	(mips_cpu_axi_if_arvalid),
	  
	  .S_AXI_AWADDR		(mips_cpu_axi_if_awaddr),
	  .S_AXI_AWREADY	(mips_cpu_axi_if_awready),
	  .S_AXI_AWVALID	(mips_cpu_axi_if_awvalid),
	  
	  .S_AXI_BREADY		(mips_cpu_axi_if_bready),
	  .S_AXI_BRESP		(mips_cpu_axi_if_bresp),
	  .S_AXI_BVALID		(mips_cpu_axi_if_bvalid),
	  
	  .S_AXI_RDATA		(mips_cpu_axi_if_rdata),
	  .S_AXI_RREADY		(mips_cpu_axi_if_rready),
	  .S_AXI_RRESP		(mips_cpu_axi_if_rresp),
	  .S_AXI_RVALID		(mips_cpu_axi_if_rvalid),
	  
	  .S_AXI_WDATA		(mips_cpu_axi_if_wdata),
	  .S_AXI_WREADY		(mips_cpu_axi_if_wready),
	  .S_AXI_WSTRB		(mips_cpu_axi_if_wstrb),
	  .S_AXI_WVALID		(mips_cpu_axi_if_wvalid),
	  
	  .AXI_Address		(axi_lite_mem_addr),
	  .AXI_MemRead		(axi_lite_mem_rden),
	  .AXI_MemWrite		(axi_lite_mem_wren),
	  .AXI_Read_data	(axi_lite_mem_rdata),
	  .AXI_Write_data	(axi_lite_mem_wdata),

	  .cycle_cnt		(cycle_cnt),
	  .inst_cnt			(inst_cnt),
	  .br_cnt			(br_cnt),
	  .ld_cnt			(ld_cnt),
	  .st_cnt			(st_cnt),
	  .user1_cnt		(user1_cnt),
	  .user2_cnt		(user2_cnt),
	  .user3_cnt		(user3_cnt),
	  
	  .mips_rst			(mips_rst)
  );
`else
  assign axi_lite_mem_addr = 'd0;
  assign axi_lite_mem_rden = 'd0;
  assign axi_lite_mem_wren = 'd0;
  assign axi_lite_mem_wdata = 'd0;
  assign mips_rst = mips_cpu_reset;

  assign mips_cpu_perf_sig[0] = |cycle_cnt[31:0];
  assign mips_cpu_perf_sig[1] = |inst_cnt[31:0];
  assign mips_cpu_perf_sig[2] = |br_cnt[31:0];
  assign mips_cpu_perf_sig[3] = |ld_cnt[31:0];
  assign mips_cpu_perf_sig[4] = |st_cnt[31:0];
  assign mips_cpu_perf_sig[5] = |user1_cnt[31:0];
  assign mips_cpu_perf_sig[6] = |user2_cnt[31:0];
  assign mips_cpu_perf_sig[7] = |user3_cnt[31:0];

`endif

`ifdef MIPS_CPU_FULL_SIMU
	always @ (posedge mips_cpu_clk)
	begin
		mips_cpu_rst_i <= {mips_cpu_rst_i[0], mips_cpu_reset};
	end
	assign mips_cpu_rst = mips_cpu_rst_i[1];
`endif

//MIPS CPU cores
  mips_cpu	u_mips_cpu (	
	  .clk			(mips_cpu_clk),
`ifdef MIPS_CPU_FULL_SIMU
	  .rst			(mips_cpu_rst),
`else
	  .rst			(mips_rst),
`endif

	  .PC			(PC),
	  .Instruction	(Instruction),

	  .Address		(mips_mem_addr),
	  .MemWrite		(MemWrite),
	  .Write_data	(mips_mem_wdata),
	  .MemRead		(MemRead),
	  .Read_data	(mips_mem_rdata),

	  .cycle_cnt	(cycle_cnt),
	  .inst_cnt		(inst_cnt),
	  .br_cnt		(br_cnt),
	  .ld_cnt		(ld_cnt),
	  .st_cnt		(st_cnt),
	  .user1_cnt	(user1_cnt),
	  .user2_cnt	(user2_cnt),
	  .user3_cnt	(user3_cnt)
  );

`ifdef MIPS_CPU_FULL_SIMU
  assign mips_cpu_pc_sig = PC[2];
`endif

/*
 * ============================================================== 
 * Memory read arbitration between AXI Lite IF and MIPS CPU
 * ==============================================================
 */

  //AXI Lite IF can read distributed memory only when MIPS CPU has no memory operations
  //if contention occurs, return 0xFFFFFFFF to Read_data port of AXI Lite IF
  assign mips_mem_rd = MemRead & (~mips_rst);
  assign axi_lite_mem_rd = axi_lite_mem_rden & (mips_rst | (~MemRead));
  
  assign Rden = mips_mem_rd | axi_lite_mem_rd;

  assign axi_lite_mem_rdata = ({32{axi_lite_mem_rd}} & Rdata) | ({32{~axi_lite_mem_rd}});

  assign mips_mem_rdata = {32{mips_mem_rd}} & Rdata;

  assign Raddr = ({MEM_ADDR_WIDTH-2{mips_mem_rd}} & mips_mem_addr[MEM_ADDR_WIDTH - 1:2]) | 
				({MEM_ADDR_WIDTH-2{axi_lite_mem_rd}} & axi_lite_mem_addr);

/*
 * ==============================================================
 * Memory write arbitration between AXI Lite IF and MIPS CPU
 * ==============================================================
 */
  //AXI Lite IF only generates memory write requests before MIPS CPU is running
  assign Wren = MemWrite | axi_lite_mem_wren;

  assign Wdata = ({32{MemWrite}} & mips_mem_wdata) | 
				({32{axi_lite_mem_wren}} & axi_lite_mem_wdata);

  assign Waddr = ({MEM_ADDR_WIDTH-2{MemWrite}} & mips_mem_addr[MEM_ADDR_WIDTH - 1:2]) | 
				({MEM_ADDR_WIDTH-2{axi_lite_mem_wren}} & axi_lite_mem_addr);

  //Distributed memory module used as main memory of MIPS CPU
  ideal_mem		# (
	  .ADDR_WIDTH	(MEM_ADDR_WIDTH)
  ) u_ideal_mem (
	  .clk			(mips_cpu_clk),
	  
	  .Waddr		(Waddr),
	  .Raddr1		(PC[MEM_ADDR_WIDTH - 1:2]),
	  .Raddr2		(Raddr),

	  .Wren			(Wren),
	  .Rden1		(1'b1),
	  .Rden2		(Rden),

	  .Wdata		(Wdata),
	  .Rdata1		(Instruction),
	  .Rdata2		(Rdata)
  );

endmodule

