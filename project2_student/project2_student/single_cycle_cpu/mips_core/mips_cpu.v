module mips_cpu(
	input  rst,
	input  clk,

	output [31:0] PC,
	input  [31:0] Instruction,

	output [31:0] Address,
	output MemWrite,
	output [31:0] Write_data,

	input  [31:0] Read_data,
	output MemRead
);

	//TODO: Insert your design of single cycle MIPS CPU here
    
    ////////////////////////////////
    // 信号
    ///////////////////////////////
    
    integer i;
    always@(*)  i = PC/4;   //只是用来在跑sim时标示读的是mem的第几个位置，没有其他应用
    
    //重新定义一些reg类型的输出，然后用assign把它们和输出连接上。直接把PC重新声明为reg会报waring
    reg[31:0] reg_PC;
    assign PC = reg_PC;
    
    //control生成的控制信号：
    wire RegDst;
    wire Branch;
    wire MemToReg;
    wire[1:0] ALUop;
    wire ALUSrc;
    wire RegWrite;
    reg[8:0] control;
    //拼接控制信号
    assign { RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUop[1:0] } = control;     
    
    //reg reg_MemWrite;
    //reg reg_MemRead;
    //assign MemRead = reg_MemRead;
    //assign MemWrite = reg_MemWrite;
      
    //数据位数：
    parameter DataWide = 32;
    parameter AddrWide = 5;
   
   //reg_file 的输入输出信号
    wire[AddrWide-1:0] raddr1,raddr2,waddr;
    wire[DataWide-1:0] wdata,rdata1,rdata2;
    
    //ALU 的输入输出信号：
    wire[DataWide-1:0] alu_a,alu_b;
    reg[2:0] alu_operation;
    wire Overflow,CarryOut,Zero;
    wire[DataWide-1:0] Result;
    
    //计算PC中途产生的信号
    //加法器1结果，加法器2结果，符号扩展结果，左移两位结果
    wire[31:0] add1,add2,SignExtend,ShiftLeft;
    wire PCSrc;
    
    
    /////////////////////////////////////////
    //  参数
    ////////////////////////////////////////
    //参数：输入的指令操作：
    parameter ADDIU = 6'b001001;
    parameter LW    = 6'b100011;
    parameter SW    = 6'b101011;
    parameter BNE   = 6'b000101;
    parameter NOP   = 6'b000000;    
    
    //参数：ALU的操作：
    parameter And = 3'b000;
    parameter Or  = 3'b001;
    parameter Add = 3'b010;
    parameter Sub = 3'b110;
    parameter Slt = 3'b111;
    
    
          
    //////////////////////////////////////////////////////////////////////////////////////////
    //********************  control  *****************************
    //////////////////////////////////////////////////////////////////////////////////////////
    //产生控制信号的部件（control)
    // assign { RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUop[1:0] } = control;   
    always@(*)
     begin
        case( Instruction[31:26] )
            ADDIU:      control = 9'b010_100_011;
            //等待后续添加相应操作
            LW:         control = 9'b011_110_000;                
            SW:         control = 9'b111_001_000;
            BNE:        control = 9'b101_000_101;
            NOP:        control = 9'b000_000_000;
               
            default:    control = 9'b000_000_000;
        endcase
     end//always
     
     
     
     //////////////////////////////////////////////////////////////////////////////////////////
     //*****************  reg_file  *****************************
     //////////////////////////////////////////////////////////////////////////////////////////
     //连接reg_file的接口
     //连接输入
     assign raddr1 = Instruction[25:21];
     assign raddr2 = Instruction[20:16];
     assign waddr = (RegDst === 0)? Instruction[20:16] : Instruction[15:11];
     assign wdata = (MemToReg === 1)? Read_data : Result;
     //接口配对
     reg_file  rf(clk, rst, waddr, raddr1, raddr2, RegWrite, wdata, rdata1, rdata2);     
     
     
     
     //////////////////////////////////////////////////////////////////////////////////////////
     //******************** alu *******************************
     //////////////////////////////////////////////////////////////////////////////////////////
     //产生alu的操作信号
     always@(*)
      begin
        case(ALUop)           
            //后续补充对应的操作
            2'b00:  alu_operation = Add; //LW,SW,NOP(NOP是空操作，所以alu做什么计算都可以,result不写进mem也不写进reg）
            2'b01:  alu_operation = Sub; //BNE
            //2'b10:
            2'b11:  alu_operation = Add; //ADDIU
            default:alu_operation = And;
        endcase
      end//always
     
     //连接输入
     assign alu_a = rdata1;
     assign alu_b = (ALUSrc === 0)? rdata2 : SignExtend;
     //接口配对
     alu  alu_1(alu_a, alu_b, alu_operation, Overflow, CarryOut, Zero, Result);
     
     
     
      
    //////////////////////////////////////////////////////////////////////////////////////////
    //************************  PC ***************************
    //////////////////////////////////////////////////////////////////////////////////////////
    //产生中途信号
    
    assign add1 = PC + 4;
    //符号扩展
    assign SignExtend = { {16{Instruction[15]}} , Instruction[15:0]};
    //左移两位
    assign ShiftLeft = SignExtend << 2;
    assign add2 = add1 + ShiftLeft;
    assign PCSrc = ( Branch & (~Zero) );
    //同步更新PC的值(PC是wire，要更新的是reg_PC)
    always@(posedge clk)
     begin
      if(rst === 1) 
        reg_PC <= 0;
      else 
        reg_PC <= (PCSrc === 0)? add1 : add2;
     end//always
     //把PC连接到reg_PC
     assign PC = reg_PC;
    
    
    ///////////////////////////////////////////////////////////////////////////
    //*****************  连接剩余的输出信号  ********************
    ////////////////////////////////////////////////////////////////////////////
    assign Address = Result;
    assign Write_data = rdata2;
    
    
endmodule






























