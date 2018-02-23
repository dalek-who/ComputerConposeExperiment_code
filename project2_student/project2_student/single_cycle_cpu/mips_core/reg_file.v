`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement 4 4-bit registers
    `define DATA_WIDTH 4
	`define ADDR_WIDTH 2
`else
    `define DATA_WIDTH 32
	`define ADDR_WIDTH 5
`endif

module reg_file(
	input clk,
	input rst,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);

	// TODO: insert your code
	reg[`DATA_WIDTH - 1:0] ram [`DATA_WIDTH - 1:0];
	integer rst_ptr;
	
	//write
	always@(posedge clk)
	 begin
	 ram[0] <= 0;//ram[0] is 0 and can`t be change
	 
	 if(rst===1)//clear all data
	  begin
	   for( rst_ptr = 1 ; rst_ptr < `DATA_WIDTH ; rst_ptr=rst_ptr+1 )
	       ram[rst_ptr]<=0;
	  end//if
	 
	 else if( wen===0)//write nothing
	           ;
	 else if( wen===1 && waddr===0)//write nothing
	           ;
	 else 
	       ram[waddr]<=wdata; //write data 
	 end//always
	 
	 //read
	 assign rdata1=ram[raddr1];
	 assign rdata2=ram[raddr2];

endmodule
