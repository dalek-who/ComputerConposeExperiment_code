/* =========================================
* AXI Lite Interface for ARM CPU cores to
* access MIPS instruction/data memory.
* Total Address space is 16KB.
* The low 8KB is allocated to distributed memory.
* The high 8KB is allocated to memory-mapped
* I/O registers
*
* Author: Yisong Chang (changyisong@ict.ac.cn)
* Date: 31/05/2016
* Version: v0.0.1
*===========================================
*/

`define C_S_AXI_DATA_WIDTH 32
`define C_S_AXI_ADDR_WIDTH 14

module axi_lite_if #(
  parameter ADDR_WIDTH = 13
)(
  input wire	S_AXI_ACLK,
  input wire	S_AXI_ARESETN,

  //AXI AW Channel
  input  wire [`C_S_AXI_ADDR_WIDTH - 1:0] S_AXI_AWADDR,
  input  wire                          S_AXI_AWVALID,
  output wire                          S_AXI_AWREADY,

  //AXI W Channle
  input  wire [`C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
  input  wire [`C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
  input  wire                          S_AXI_WVALID,
  output wire                          S_AXI_WREADY,

  //AXI B Channel
  output wire [1:0]                    S_AXI_BRESP,
  output wire                          S_AXI_BVALID,
  input  wire                          S_AXI_BREADY,

  //AXI AR Channel
  input  wire [`C_S_AXI_ADDR_WIDTH - 1:0] S_AXI_ARADDR,
  input  wire                          S_AXI_ARVALID,
  output wire                          S_AXI_ARREADY,

  //AXI R Channel
  output wire [`C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
  output wire [1:0]                    S_AXI_RRESP,
  output wire                          S_AXI_RVALID,
  input  wire                          S_AXI_RREADY,
 
  //Ports to ideal memory
  output wire [ADDR_WIDTH - 3:0]	   AXI_Address,
  output wire [31:0]                   AXI_Write_data,
  output wire                          AXI_MemWrite,
  output wire                          AXI_MemRead,
  input  wire [31:0]                   AXI_Read_data,

  input wire [31:0]					   cycle_cnt,
  input wire [31:0]					   inst_cnt,
  input wire [31:0]					   br_cnt,
  input wire [31:0]					   ld_cnt,
  input wire [31:0]					   st_cnt,
  input wire [31:0]					   user1_cnt,
  input wire [31:0]					   user2_cnt,
  input wire [31:0]					   user3_cnt,

  //MIPS reset signal
  output reg                           mips_rst
);

reg                           axi_rvalid;
reg [`C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
reg [1:0]					  axi_rresp;

reg                           axi_bvalid;
reg [1:0]                     axi_bresp;

reg                           axi_awready;

reg                           axi_wready;

reg                           axi_arready;

//Write address and Read address from decoder
wire [ADDR_WIDTH - 3:0]		  wr_addr;
wire [ADDR_WIDTH - 3:0] 	  rd_addr;

//MMIO decode signal for MIPS reset register (addr: 0x2000)
wire 						  mips_rst_sel;
wire						  mips_rst_wdata;

assign S_AXI_AWREADY = axi_awready;

assign S_AXI_WREADY  = axi_wready;

assign S_AXI_BRESP  = axi_bresp;
assign S_AXI_BVALID = axi_bvalid;

assign S_AXI_ARREADY = axi_arready;

assign S_AXI_RDATA  = axi_rdata;
assign S_AXI_RVALID = axi_rvalid;
assign S_AXI_RRESP  = axi_rresp;


////////////////////////////////////////////////////////////////////////////
// Implement axi_awready generation
//
//  axi_awready is asserted for one S_AXI_ACLK clock cycle when both
//  S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
//  de-asserted when reset is low.

  always @( posedge S_AXI_ACLK )
  begin
	  if(S_AXI_ARESETN == 1'b0)
		  axi_awready <= 1'b0;
	  else
	  begin
		  ////////////////////////////////////////////////////////////////////////////
		  // slave is ready to accept write address when
		  // there is a valid write address and write data
		  // on the write address and data bus. This design
		  // expects no outstanding transactions.
		  if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
			  axi_awready <= 1'b1;
		  else
			  axi_awready <= 1'b0;
	  end
  end

////////////////////////////////////////////////////////////////////////////
// Implement axi_wready generation
//
//  axi_wready is asserted for one S_AXI_ACLK clock cycle when both
//  S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
//  de-asserted when reset is low.

  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
        axi_wready <= 1'b0;
    else
      begin
	    ////////////////////////////////////////////////////////////////////////////
        // slave is ready to accept write data when
        // there is a valid write address and write data
        // on the write address and data bus. This design
        // expects no outstanding transactions.
        if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
            axi_wready <= 1'b1;
        else
            axi_wready <= 1'b0;
      end
  end

//decoder for AXI write operations
  assign wren = ~axi_awready & ~axi_wready & S_AXI_AWVALID & S_AXI_WVALID;
  assign AXI_MemWrite = ~S_AXI_AWADDR[13] & wren;
  assign AXI_Write_data =  {32{AXI_MemWrite}} & S_AXI_WDATA;
  assign wr_addr = {ADDR_WIDTH-2{AXI_MemWrite}} & S_AXI_AWADDR[ADDR_WIDTH-1:2];

  assign mips_rst_sel = S_AXI_AWADDR[13] & (~|S_AXI_AWADDR[ADDR_WIDTH-1:2]) & wren; 
  assign mips_rst_wdata = ~S_AXI_WDATA[0];

//MMIO MIPS reset register
//hold valid MIPS reset signal when system reset
//ARM CPU cores write 1 to invalidate MIPS reset signal
//This register is write-only for ARM cores 
  always @( posedge S_AXI_ACLK )
  begin
    if (S_AXI_ARESETN == 1'b0)
        mips_rst <= 1'b1;
    else if (mips_rst_sel)
        mips_rst <= mips_rst_wdata;
	else
        mips_rst <= mips_rst;
  end 

////////////////////////////////////////////////////////////////////////////
// Implement write response logic generation
//
//  The write response and response valid signals are asserted by the slave
//  when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
//  This marks the acceptance of address and indicates the status of
//  write transaction.

  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_bvalid  <= 0;
        axi_bresp   <= 2'b0;
      end
    else
      begin
        if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
          begin
            // indicates a valid write response is available
            axi_bvalid <= 1'b1;
            axi_bresp  <= 2'b0; // 'OKAY' response
          end                   // work error responses in future
        else
          begin
            if (S_AXI_BREADY && axi_bvalid)
              //check if bready is asserted while bvalid is high)
              //(there is a possibility that bready is always asserted high)
              begin
                axi_bvalid <= 1'b0;
              end
          end
      end
  end


////////////////////////////////////////////////////////////////////////////
// Implement axi_arready generation
//
//  axi_arready is asserted for one S_AXI_ACLK clock cycle when
//  S_AXI_ARVALID is asserted. axi_awready is
//  de-asserted when reset (active low) is asserted.
//  The read address is also latched when S_AXI_ARVALID is
//  asserted. axi_araddr is reset to zero on reset assertion.

  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
        axi_arready <= 1'b0;
    else
      begin
        // indicates that the slave has acceped the valid read address
        if (~axi_arready && S_AXI_ARVALID)
            axi_arready <= 1'b1;
        else
            axi_arready <= 1'b0;
      end
  end

////////////////////////////////////////////////////////////////////////////
// Implement memory mapped register select and read logic generation
//
//  axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
//  S_AXI_ARVALID and axi_arready are asserted. The slave registers
//  data are available on the axi_rdata bus at this instance. The
//  assertion of axi_rvalid marks the validity of read data on the
//  bus and axi_rresp indicates the status of read transaction.axi_rvalid
//  is deasserted on reset (active low). axi_rresp and axi_rdata are
//  cleared to zero on reset (active low).

  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_rvalid <= 1'd0;
        axi_rresp  <= 2'd0;
      end
    else
      begin
        // Valid read data is available at the read data bus
        if (~axi_arready && S_AXI_ARVALID && ~axi_rvalid)
          begin
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b00; // 'OKAY' response
          end
        
		// Read data is accepted by the master
        else if (axi_rvalid && S_AXI_RREADY)
            axi_rvalid <= 1'b0;
      end
  end
  
//TODO: Add arbitration logic to allow ARM processors to 
//read MIPS performance counter value													////////////////////////////////////////////////////////////
wire		AXI_PerfRd;			//selection signal for performance counter				// 添加性能计数器译码?辑
wire [3:0]	AXI_PerfAddr;		//Address offset of performance counter (0x1 - 0x8)		//
reg [31:0]	AXI_PerfData;		//Read out data of a certain performance counter		/////////////////////////////////////////////////////////////
  
  //store Read_data from distributed memory to axi_rdata register
  always @( posedge S_AXI_ACLK )											///////////////////////////////////////////////////////
  begin																		//
    if ( S_AXI_ARESETN == 1'b0 )											//
        axi_rdata <= {`C_S_AXI_DATA_WIDTH{1'b0}};							//
    else if(~axi_arready & S_AXI_ARVALID)									// 为AXI Lite接口返回读数据的仲裁逻辑
        axi_rdata <= ({32{~S_AXI_ARADDR[13]}} & AXI_Read_data) | 			//
						({32{S_AXI_ARADDR[13]}} & AXI_PerfData);			//
	else																	//
        axi_rdata <= axi_rdata;												//
  end																		////////////////////////////////////////////////////////

assign	AXI_MemRead = ~S_AXI_ARADDR[13] && ~axi_arready && S_AXI_ARVALID;		    //对ideal memory部分的译码过程
assign	rd_addr = {ADDR_WIDTH-2{AXI_MemRead}} & S_AXI_ARADDR[ADDR_WIDTH - 1:2];    ////////////////////////////////
  
assign  AXI_Address = wr_addr | rd_addr;



	/*第一版，失败
        assign AXI_PerfRd = ~S_AXI_ARADDR[13] && ~axi_arready && S_AXI_ARVALID;
        assign AXI_PerfAddr = {ADDR_WIDTH-2{AXI_MemRead}} & S_AXI_ARADDR[5:2];
    */
    //arm地址0x4000_0000~0x4000_1fff时为读mem，0x4000_2000为reset,0x4000_2001~0x4000_2008为count
    //           
    //0x1fff == 0b 0001_1111_1111_1111
    //0x2000 == 0b 0010_0000_0000_0000
    //所以S_AXI_ARADDR[13]是0还是1可以区别是读内存还是读counter
     assign AXI_PerfRd =   S_AXI_ARADDR[13] && ~axi_arready && S_AXI_ARVALID;
     assign AXI_PerfAddr = {4{AXI_PerfRd}} & S_AXI_ARADDR[5:2];
        
        always@( * )
        begin
        case(AXI_PerfAddr)
            4'b0001: AXI_PerfData = cycle_cnt;
            4'b0010: AXI_PerfData = inst_cnt;
            4'b0011: AXI_PerfData = br_cnt;
            4'b0100: AXI_PerfData = ld_cnt;
            4'b0101: AXI_PerfData = st_cnt;
            4'b0110: AXI_PerfData = user1_cnt;
            4'b0111: AXI_PerfData = user2_cnt;
            4'b1000: AXI_PerfData = user3_cnt;
            
            //用来检验输入的地址是不是错了
            4'b0000: AXI_PerfData = -1;
            4'b1001: AXI_PerfData = -9;
            4'b1010: AXI_PerfData = -10;
            4'b1011: AXI_PerfData = -11;
            4'b1100: AXI_PerfData = -12;
            4'b1101: AXI_PerfData = -13;
            4'b1110: AXI_PerfData = -14;
            4'b1111: AXI_PerfData = -15;
            default: AXI_PerfData = -16;    //出现-1表示总线或loader设计有误
        endcase
        
        //第一版：触发方式不对，失败
        /*
        always@( posedge S_AXI_ACLK  )
        begin
        case(AXI_PerfAddr)
            4'b0001: AXI_PerfData <= cycle_cnt;
            4'b0010: AXI_PerfData <= inst_cnt;
            4'b0011: AXI_PerfData <= br_cnt;
            4'b0100: AXI_PerfData <= ld_cnt;
            4'b0101: AXI_PerfData <= st_cnt;
            4'b0110: AXI_PerfData <= user1_cnt;
            4'b0111: AXI_PerfData <= user2_cnt;
            4'b1000: AXI_PerfData <= user3_cnt;
            
            //用来检验输入的地址是不是错了
            4'b0000: AXI_PerfData <= -1;
            4'b1001: AXI_PerfData <= -9;
            4'b1010: AXI_PerfData <= -10;
            4'b1011: AXI_PerfData <= -11;
            4'b1100: AXI_PerfData <= -12;
            4'b1101: AXI_PerfData <= -13;
            4'b1110: AXI_PerfData <= -14;
            4'b1111: AXI_PerfData <= -15;
            default: AXI_PerfData <= -16;    //出现-1表示总线或loader设计有误
        endcase
        */
        end
        
endmodule
