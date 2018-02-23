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
    // �ź�
    ///////////////////////////////
    
    integer i;
    always@(*)  i = PC/4;   //ֻ����������simʱ��ʾ������mem�ĵڼ���λ�ã�û������Ӧ��
    
    //���¶���һЩreg���͵������Ȼ����assign�����Ǻ���������ϡ�ֱ�Ӱ�PC��������Ϊreg�ᱨwaring
    reg[31:0] reg_PC;
    assign PC = reg_PC;
    
    //control���ɵĿ����źţ�
    wire RegDst;
    wire Branch;
    wire MemToReg;
    wire[1:0] ALUop;
    wire ALUSrc;
    wire RegWrite;
    reg[8:0] control;
    //ƴ�ӿ����ź�
    assign { RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUop[1:0] } = control;     
    
    //reg reg_MemWrite;
    //reg reg_MemRead;
    //assign MemRead = reg_MemRead;
    //assign MemWrite = reg_MemWrite;
      
    //����λ����
    parameter DataWide = 32;
    parameter AddrWide = 5;
   
   //reg_file ����������ź�
    wire[AddrWide-1:0] raddr1,raddr2,waddr;
    wire[DataWide-1:0] wdata,rdata1,rdata2;
    
    //ALU ����������źţ�
    wire[DataWide-1:0] alu_a,alu_b;
    reg[2:0] alu_operation;
    wire Overflow,CarryOut,Zero;
    wire[DataWide-1:0] Result;
    
    //����PC��;�������ź�
    //�ӷ���1������ӷ���2�����������չ�����������λ���
    wire[31:0] add1,add2,SignExtend,ShiftLeft;
    wire PCSrc;
    
    
    /////////////////////////////////////////
    //  ����
    ////////////////////////////////////////
    //�����������ָ�������
    parameter ADDIU = 6'b001001;
    parameter LW    = 6'b100011;
    parameter SW    = 6'b101011;
    parameter BNE   = 6'b000101;
    parameter NOP   = 6'b000000;    
    
    //������ALU�Ĳ�����
    parameter And = 3'b000;
    parameter Or  = 3'b001;
    parameter Add = 3'b010;
    parameter Sub = 3'b110;
    parameter Slt = 3'b111;
    
    
          
    //////////////////////////////////////////////////////////////////////////////////////////
    //********************  control  *****************************
    //////////////////////////////////////////////////////////////////////////////////////////
    //���������źŵĲ�����control)
    // assign { RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUop[1:0] } = control;   
    always@(*)
     begin
        case( Instruction[31:26] )
            ADDIU:      control = 9'b010_100_011;
            //�ȴ����������Ӧ����
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
     //����reg_file�Ľӿ�
     //��������
     assign raddr1 = Instruction[25:21];
     assign raddr2 = Instruction[20:16];
     assign waddr = (RegDst === 0)? Instruction[20:16] : Instruction[15:11];
     assign wdata = (MemToReg === 1)? Read_data : Result;
     //�ӿ����
     reg_file  rf(clk, rst, waddr, raddr1, raddr2, RegWrite, wdata, rdata1, rdata2);     
     
     
     
     //////////////////////////////////////////////////////////////////////////////////////////
     //******************** alu *******************************
     //////////////////////////////////////////////////////////////////////////////////////////
     //����alu�Ĳ����ź�
     always@(*)
      begin
        case(ALUop)           
            //���������Ӧ�Ĳ���
            2'b00:  alu_operation = Add; //LW,SW,NOP(NOP�ǿղ���������alu��ʲô���㶼����,result��д��memҲ��д��reg��
            2'b01:  alu_operation = Sub; //BNE
            //2'b10:
            2'b11:  alu_operation = Add; //ADDIU
            default:alu_operation = And;
        endcase
      end//always
     
     //��������
     assign alu_a = rdata1;
     assign alu_b = (ALUSrc === 0)? rdata2 : SignExtend;
     //�ӿ����
     alu  alu_1(alu_a, alu_b, alu_operation, Overflow, CarryOut, Zero, Result);
     
     
     
      
    //////////////////////////////////////////////////////////////////////////////////////////
    //************************  PC ***************************
    //////////////////////////////////////////////////////////////////////////////////////////
    //������;�ź�
    
    assign add1 = PC + 4;
    //������չ
    assign SignExtend = { {16{Instruction[15]}} , Instruction[15:0]};
    //������λ
    assign ShiftLeft = SignExtend << 2;
    assign add2 = add1 + ShiftLeft;
    assign PCSrc = ( Branch & (~Zero) );
    //ͬ������PC��ֵ(PC��wire��Ҫ���µ���reg_PC)
    always@(posedge clk)
     begin
      if(rst === 1) 
        reg_PC <= 0;
      else 
        reg_PC <= (PCSrc === 0)? add1 : add2;
     end//always
     //��PC���ӵ�reg_PC
     assign PC = reg_PC;
    
    
    ///////////////////////////////////////////////////////////////////////////
    //*****************  ����ʣ�������ź�  ********************
    ////////////////////////////////////////////////////////////////////////////
    assign Address = Result;
    assign Write_data = rdata2;
    
    
endmodule






























