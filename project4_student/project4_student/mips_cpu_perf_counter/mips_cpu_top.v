`timescale 10ns / 1ns

module mips_cpu_top (
    input           mips_cpu_clk,
    input           mips_cpu_reset,

    output          mips_cpu_pc_sig,
	output [7:0]	mips_cpu_perf_sig
);

	localparam		MEM_ADDR_WIDTH = 11;

	wire [MEM_ADDR_WIDTH - 3:0]		Waddr;			//Memory write port address
	wire [MEM_ADDR_WIDTH - 3:0]		Raddr;			//Read port 2 address
	
	wire [31:0]     PC;
	wire [31:0]		mips_mem_addr;	//MIPS CPU memory instruction address

	wire			MemWrite;		//CPU write enable
	wire			MemRead;		//CPU read enable

	wire [31:0]		Instruction;	
	wire [31:0]		Wdata;			//Memory write data
	wire [31:0]		Rdata;			//Memory read data
	
	(*mark_debug = "true"*) wire [31:0]		cycle_cnt;
	(*mark_debug = "true"*) wire [31:0]		inst_cnt;
	(*mark_debug = "true"*) wire [31:0]		br_cnt;
	(*mark_debug = "true"*) wire [31:0]		ld_cnt;
	(*mark_debug = "true"*) wire [31:0]		st_cnt;
	(*mark_debug = "true"*) wire [31:0]		user1_cnt;
	(*mark_debug = "true"*) wire [31:0]		user2_cnt;
	(*mark_debug = "true"*) wire [31:0]		user3_cnt;

	reg [1:0]		mips_cpu_rst_i = 2'b11;
	wire			mips_cpu_rst;

	/*avoiding performance counter to be optimized by P&R tools*/
	assign mips_cpu_perf_sig[0] = |cycle_cnt;
	assign mips_cpu_perf_sig[1] = |inst_cnt;
	assign mips_cpu_perf_sig[2] = |br_cnt;
	assign mips_cpu_perf_sig[3] = |ld_cnt;
	assign mips_cpu_perf_sig[4] = |st_cnt;
	assign mips_cpu_perf_sig[5] = |user1_cnt;
	assign mips_cpu_perf_sig[6] = |user2_cnt;
	assign mips_cpu_perf_sig[7] = |user3_cnt;

	/*sync. released reset signal*/
	always @ (posedge mips_cpu_clk)
	begin
		mips_cpu_rst_i <= {mips_cpu_rst_i[0], mips_cpu_reset};
	end
	assign mips_cpu_rst = mips_cpu_rst_i[1];
	
	ideal_mem 	#(
	  .ADDR_WIDTH	(MEM_ADDR_WIDTH)
    ) u_ideal_mem (
	  .clk			(mips_cpu_clk),
	  
	  .Waddr		(Waddr),
	  .Raddr1		(PC[MEM_ADDR_WIDTH - 1:2]),
	  .Raddr2		(Raddr),

	  .Wren			(MemWrite),
	  .Rden1		(1'b1),
	  .Rden2		(MemRead),

	  .Wdata		(Wdata),
	  .Rdata1		(Instruction),
	  .Rdata2		(Rdata)
	);

	mips_cpu		u_mips_cpu (	
	  .clk			(mips_cpu_clk),
	  .rst			(mips_cpu_rst),

	  .PC			(PC),
	  .Instruction	(Instruction),

	  .Address		(mips_mem_addr),
	  .MemWrite		(MemWrite),
	  .Write_data	(Wdata),
	  
	  .MemRead		(MemRead),
	  .Read_data	(Rdata),
	  
	  .cycle_cnt	(cycle_cnt),
	  .inst_cnt		(inst_cnt),
	  .br_cnt		(br_cnt),
	  .ld_cnt		(ld_cnt),
	  .st_cnt		(st_cnt),
	  .user1_cnt	(user1_cnt),
	  .user2_cnt	(user2_cnt),
	  .user3_cnt	(user3_cnt)
	);

	assign Waddr = {MEM_ADDR_WIDTH-2{MemWrite}} & mips_mem_addr[MEM_ADDR_WIDTH-1:2];
	assign Raddr = {MEM_ADDR_WIDTH-2{MemRead}} & mips_mem_addr[MEM_ADDR_WIDTH-1:2];

    assign mips_cpu_pc_sig = PC[2]; 

endmodule
