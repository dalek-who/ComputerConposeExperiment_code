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
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
	//--------------------------------------------------------------------------
    //                                   信号           
	//--------------------------------------------------------------------------
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    
	
    //////////////////////////////
	//***** 控制信号 ********
	//////////////////////////////
	
	//状态机状态信号
	reg[4:0] state;		//*********状态机的当前状态**********
	reg[4:0] new_state;	//*********状态机的下一个状态**********
	/*
	全是reg类型的控制信号。三段式状态机改用wire信号加拼接control信号来进行
    reg PCWriteBne; //bne跳转
	reg PCWriteBeq; //beq跳转
	reg PCWrite; //无条件跳转
	reg reg_MemWrite; assign MemRead = reg_MemRead;
    reg reg_MemRead;  assign MemWrite = reg_MemWrite;
	reg MemToReg; // 1:reg写入mem的数据 0：reg写入alu的数据
	reg IRWrite;
	reg[1:0] PCSource; //00:PC=PC+4, 01:PC=PC+4+offset (beq,bne) 10:PC=jump地址（jump）
	reg[1:0] ALUop; 
	reg ALUSrcA; //0:ALU_a=PC, 1:ALU_a=a;
	reg[1:0] ALUSrcB; //00:ALU_b=B, 01:00:ALU_b=4 10:ALU_b=指令后16位符号扩展 11:ALU_b=指令后16位符号扩展左移两位
	reg RegWrite;
	reg RegDst; //0：指令[20-16]， 1：指令[15-11]
	//wire Branch;  
	*/
    
    //control生成的控制信号：   
    wire 		PCWriteBne; //bne跳转
	wire 		PCWriteBeq; //beq跳转
	wire 		PCWrite; //无条件跳转
	wire 		MemToReg; // 1:reg写入mem的数据 0：reg写入alu的数据
	wire 		IRWrite;
	wire[1:0]	PCSource; //00:PC=PC+4, 01:PC=PC+4+offset (beq,bne) 10:PC=jump地址（jump）
	wire[3:0]	ALUop; 
	wire[1:0]	ALUSrcA; //0:ALU_a=PC, 1:ALU_a=a;
	wire[1:0]	ALUSrcB; //00:ALU_b=B, 01:00:ALU_b=4 10:ALU_b=指令后16位符号扩展 11:ALU_b=指令后16位符号扩展左移两位
	wire 		RegWrite;
	wire[1:0]	RegDst; //0：指令[20-16]， 1：指令[15-11]  ;  2:31
   
    //拼接得到的总控制信号
    reg[19:0] 	control;
	assign {PCWriteBeq,PCWriteBne,PCWrite,MemRead,MemWrite,IRWrite,RegWrite,MemToReg,PCSource[1:0],ALUop[3:0],ALUSrcA[1:0],ALUSrcB[1:0],RegDst} = control;
 



 
	//////////////////////////////////
	//****** 中途的单个寄存器 *******
	//////////////////////////////////
	
    //指令寄存器
	reg[31:0] IR; //指令寄存器
	wire[5:0] Op; //操作码	
	wire[4:0] sa; //移位运算的移位数
	wire[5:0] func; //末6位function字段
	
	//内存数据寄存器memory data register
	reg[31:0] MDR;	
	
	//reg_file读出结果的寄存器
	reg[31:0] A,B;
	
	//alu结果寄存器
	reg[31:0] reg_ALUOUT;
	
    //数据位数：
    parameter DataWide = 32;
    parameter AddrWide = 5;
   
   
   
   ////////////////////////////////////////
	//***** reg_file 信号 *******
	//////////////////////////////////////
    
	//reg_file 的输入输出信号
	wire[AddrWide-1:0] raddr1,raddr2;
	reg [AddrWide-1:0] waddr;
    wire[DataWide-1:0] wdata,rdata1,rdata2;
    
	
	
	///////////////////////////////////////
	//***** ALU信号  ********
	//////////////////////////////////////    
    
	//ALU 的输入输出信号：
    reg[DataWide-1:0] alu_a,alu_b;
    reg[2:0] alu_operation;
    wire Overflow,CarryOut,Zero;
    wire[DataWide-1:0] Result;
    
	//送入alu中途产生的IR后16位符号扩展和移位的结果
	wire[31:0] SignExtend_15_0;
	wire[31:0] ShiftLeft_15_0;
	wire[31:0] SignExtend_sa;	//符号扩展后的移位数
	
	
	
	
	//////////////////////////////
	//***** PC信号 ********
	//////////////////////////////
	
	//测试时的内存地址，只是用来在跑sim时标示读的是mem的第几个位置，没有其他应用
    integer i;
    always@(*)  i = PC/4;   
    
    //重新定义一些reg类型的输出，然后用assign把它们和输出连接上。直接把PC重新声明为reg会报waring
    reg[31:0] reg_PC;
    
    //计算PC中途产生的信号
    //加法器1结果，加法器2结果，符号扩展结果，左移两位结果
    wire[27:0] ShiftLeft_25_0; //用于产生jump跳转地址的一个中间信号
	wire[31:0] Jmp_addr; //jump跳转地址
    wire PC_enable; //PC写使能信号
    
    
    /////////////////////////////////////////
    //  参数
    ////////////////////////////////////////
    //参数：输入的指令操作：
    parameter ADDIU = 6'b001_001;
    parameter LW    = 6'b100_011;
    parameter SW    = 6'b101_011;
    parameter BNE   = 6'b000_101;       	

	parameter BEQ   = 6'b000_100;	
	parameter Rtype = 6'b000_000;
	parameter J	 	= 6'b000_010;
	parameter JAL	= 6'b000_011;
	parameter LUI	= 6'b001_111;
	parameter SLTI	= 6'b001_010;
	parameter SLTIU = 6'b001_011;
	
    //参数：ALU的操作：
    parameter And = 3'b000;
    parameter Or  = 3'b001;
    parameter Add = 3'b010;
	////////////////////////
	parameter Sltu= 3'b011;
	parameter Sll = 3'b100;
	parameter Lu  = 3'b101;
	////////////////////////
    parameter Sub = 3'b110;
    parameter Slt = 3'b111;
	
	//参数：function字段（指令后6位）
	parameter func_addu = 6'b100_001;
	parameter func_or	= 6'b100_101;
	parameter func_sll	= 6'b000_000;
	parameter func_slt	= 6'b101_010;
	parameter func_jr	= 6'b001_000;
    
    //参数：control状态机的状态
    parameter Ins_Fetch = 0;
	parameter Ins_Decode = 1;
	//lw
	parameter LS1 = 2;//lw、sw的第一步
	parameter LW2 = 3;
	parameter LW3 = 4;
	//sw
	parameter SW2 = 5;
	//R-type
	parameter R1 = 6;
	parameter R2 = 7;
	//BNE
	parameter BNE1 = 8;
	//BEQ
	parameter BEQ1 = 9;
	//ADDIU
	parameter ADDIU1 =10;
	parameter ADDIU2 =11;
	
	//Jump
	parameter J1 = 12;
	//JAL
	parameter JAL1 =13;
	parameter JAL2 =14;
	
	//类似ADDIU(写寄存器的状态就是addiu的写寄存器状态，计算状态调用的函数不同)
	//SLTI
	parameter SLTI1 = 15;
	//SLTIU
	parameter SLTIU1 = 16;
	//LUI
	parameter LUI1 = 17;
	
	//类似R，但flag有所不同
	parameter R_SLL1 = 18;
	parameter R_JR2 = 19;
	
	
	/////////////////////////////////////////////////////////////////////////////////////
	//-----------------------------------------------------------------
	//               				 电路部分
	//-----------------------------------------------------------------
	/////////////////////////////////////////////////////////////////////////////////////
	
	
	
	//////////////////////////////////////////////////////////////////////////////////////////
    //********************  IR  *****************************
    //////////////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk)
		begin
			if(rst)
			IR <= 0;
			else if( !rst && IRWrite )
			IR <= Instruction;
			else
				;
		end//always
	assign Op 	= IR[31:26]; //操作码
	assign sa 	= IR[10:6];	//移位数
	assign func	= IR[5:0];	//R-type的操作函数
	
	
	
	//////////////////////////////////////////////////////////////////////////////////////////
    //********************  MDR  *****************************
    //////////////////////////////////////////////////////////////////////////////////////////	
	always@(posedge clk)
		MDR <= Read_data;
	
	
	
	
	
     //////////////////////////////////////////////////////////////////////////////////////////
    //********************  control（用有限状态机实现）  *****************************
    //////////////////////////////////////////////////////////////////////////////////////////
	 //三段式状态机
	 //1.复位与状态更新：
	 always@(posedge clk)
		begin
			if(rst)	state <= Ins_Fetch;
			else	state <= new_state;
		end//always
	 
	 //2.状态转移序列
	 always@(*)
		begin
			case(state)
			Ins_Fetch:	new_state = Ins_Decode;
			Ins_Decode:	begin
						 case(Op)
						 LW:	new_state = LS1;
						 SW:	new_state = LS1;
						 BNE:	new_state =	BNE1;
						 ADDIU:	new_state = ADDIU1;
	//					 NOP:	new_state = Ins_Fetch;
						 
						///////////////////////////////////////////////
						//待添加新指令/////////////////////////////////
						///////////////////////////////////////////////
						 BEQ:	new_state = BEQ1;
						 J:		new_state = J1;
						 JAL:	new_state = JAL1;
						 SLTI:	new_state = SLTI1;
						 SLTIU: new_state = SLTIU1;
						 LUI:	new_state = LUI1;
						 Rtype:	if( func === func_sll )	new_state = R_SLL1;
								else					new_state = R1;
						 
						 default:new_state = Ins_Fetch;
						 endcase
						end//Ins_Decode
			//lw,sw
			LS1:		begin
						 case(Op)
						 LW:	 new_state = LW2;
						 SW:	 new_state = SW2;
						 default:new_state = Ins_Fetch;
						 endcase
						end//LS1
			
			//lw:
			LW2:		new_state = LW3;
			LW3:		new_state = Ins_Fetch;
			//sw:
			SW2:		new_state = Ins_Fetch;
			//BNE：
			BNE1:		new_state = Ins_Fetch;
			//ADDIU:
			ADDIU1:		new_state = ADDIU2;
			ADDIU2:		new_state = Ins_Fetch;
			///////////////////////////////////////////////
			//待添加新指令/////////////////////////////////
			///////////////////////////////////////////////
			//beq:
			BEQ1:		new_state = Ins_Fetch;
			//J:
			J1:			new_state = Ins_Fetch;
			//JAL:
			JAL1:		new_state = JAL2;
			JAL2:		new_state = Ins_Fetch;
			//类似ADDIU：
			//SLTI:
			SLTI1:		new_state = ADDIU2;
			//SLTIU:
			SLTIU1:		new_state = ADDIU2;
			//LUI:
			LUI1:		new_state = ADDIU2;
			
			//R、类似R（sll，jr）:
			R1:	if(func === func_jr)	new_state = R_JR2;
				else					new_state = R2;			
			R_SLL1:		new_state = R2;
			R2: 		new_state = Ins_Fetch;
			R_JR2:		new_state = Ins_Fetch;
			
			default : 	new_state = Ins_Fetch;
			endcase
		end//always
		
	//3.控制信号产生序列
	always@(*)
		begin
		//		            //使能信号														 		//选通信号		
		//assign 			{PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
	//标准对齐格式	control = 20'b__x________x_________x________x_________x_________x________x__________x__________xx___________xxxx__________xx___________xx__________xx;
		case(state)
		Ins_Fetch:	control = 20'b__0________0_________1________1_________0_________1________0__________0__________00___________0000__________00___________01__________00;
		Ins_Decode: control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________00___________11__________00;
		//lw,sw
		LS1:		control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________01___________10__________00;
		//lw
		LW2:		control = 20'b__0________0_________0________1_________0_________0________0__________0__________00___________0000__________00___________00__________00;
		LW3:		control = 20'b__0________0_________0________0_________0_________0________1__________1__________00___________0000__________00___________00__________00;
		//assign 			{PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
		//sw
		SW2:		control = 20'b__0________0_________0________0_________1_________0________0__________0__________00___________0000__________00___________00__________00;
		//bne
		BNE1:		control = 20'b__0________1_________0________0_________0_________0________0__________0__________01___________0001__________01___________00__________00;
		//addiu
		ADDIU1:		control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________01___________10__________00;
		ADDIU2:		control = 20'b__0________0_________0________0_________0_________0________1__________0__________00___________0000__________00___________00__________00;
		///////////////////////////////////////////////
		//待添加新指令/////////////////////////////////
		///////////////////////////////////////////////
		//assign 			{PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
	//标准对齐格式	control = 20'b__x________x_________x________x_________x_________x________x__________x__________xx___________xxxx__________xx___________xx__________xx;		
		//bne
		BEQ1:		control = 20'b__1________0_________0________0_________0_________0________0__________0__________01___________0001__________01___________00__________00;
		//Jump:
		J1:			control = 20'b__0________0_________1________0_________0_________0________0__________0__________10___________0000__________00___________00__________00;
		//JAL:
		JAL1:		control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________00___________01__________00;
		JAL2:		control = 20'b__0________0_________1________0_________0_________0________1__________0__________10___________0000__________00___________00__________10;
		//assign 			{PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
		//类似ADDIU：
		//SLTI:
		SLTI1:		control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0011__________01___________10__________00;
		//SLTIU:
		SLTIU1:		control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0100__________01___________10__________00;
		//LUI:
		LUI1:		control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0101__________01___________10__________00;
		//assign 			{PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
		//R-type、类似R（sll，jr）
		R1:			control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0010__________01___________00__________00;	
		R_SLL1:		control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0010__________10___________00__________00;	
		R2:			control = 20'b__0________0_________0________0_________0_________0________1__________0__________00___________0000__________00___________00__________01;		
		R_JR2:		control = 20'b__0________0_________1________0_________0_________0________0__________0__________01___________0000__________00___________00__________00;		
		
		default:	control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________00___________00__________00;
		endcase
		end//always
	 /*
	 //此为一段式状态机，写起来太混乱了，暂时先不用，改用三段式状态机重构
	 always@(posedge clk)
		begin
			if(rst)
				state <= Ins_Fetch;
			else
				case(state)
				Ins_Fetch:
					begin
					state <= Ins_Decode;
					reg_MemRead <= 1;
					ALUSrcA 	<= 0; //PC
					ALUSrcB 	<= 2'b01; //4
					IRWrite 	<= 1;
					ALUop		<= 2'b00;
					PCWrite		<= 1;
					PCSource	<= 2'b00;
					end//Ins_Fetch
				
				Ins_Decode:
					begin
						//state
						case(Op)
						LW: 	state<=LS1;
						SW: 	state<=LS1;
						BNE:	state<=BNE1;
						ADDIU:	state<=ADDIU1;
						NOP:	state<=Ins_Fetch;
						//待添加指令
						/////////////////
						default:state<=Ins_Fetch;
						endcase
						ALUSrcA	<= 0;
						ALUSrcB <= 2'b11;
						ALUop	<= 2'b00;
					end//Ins_Decode
				
				default:state<=Ins_Fetch;
				
				endcase
		end//always
	 */
     
	 
	 
	 
	 
	 //////////////////////////////////////////////////////////////////////////////////////////
     //*****************  reg_file  *****************************
     //////////////////////////////////////////////////////////////////////////////////////////
     //连接reg_file的接口
     //连接输入
     assign raddr1 = IR[25:21];
     assign raddr2 = IR[20:16];
	 
	 //waddr
	 always@(*)
		begin
		case(RegDst)
		2'b00:	waddr = IR[20:16];
		2'b01:	waddr = IR[15:11];
		2'b10:	waddr = 31;
		default:waddr = IR[20:16];
		endcase
		end//always
		
     assign wdata = (MemToReg === 1)? MDR : reg_ALUOUT;
     
	 //接口配对
     reg_file  rf(clk, rst, waddr, raddr1, raddr2, RegWrite, wdata, rdata1, rdata2);     
     
	 //reg_file读出结果的寄存器
	 always@(posedge clk)
		begin
		A <= rdata1;
		B <= rdata2;
		end//always
     
	 
	 
	 
	 
     
     //////////////////////////////////////////////////////////////////////////////////////////
     //******************** alu *******************************
     //////////////////////////////////////////////////////////////////////////////////////////
     //产生alu的操作信号
     always@(*)
      begin
        case(ALUop)           
            //后续补充对应的操作
            4'b0000:  alu_operation = Add; //LW,SW,ADDIU,NOP(NOP是空操作，所以alu做什么计算都可以,result不写进mem也不写进reg）
            4'b0001:  alu_operation = Sub; //BNE
            
			///////////////////////////////////////////////
			//待添加新指令/////////////////////////////////
			///////////////////////////////////////////////
			4'b0010://R-type
				begin
					case(func)
					func_addu:	alu_operation = Add;
					func_jr:	alu_operation = Add;
					func_or:	alu_operation = Or;
					func_sll:	alu_operation = Sll;
					func_slt:	alu_operation = Slt;
					default:	alu_operation = Add;
					endcase
				end//R-type
			
			4'b0011:  alu_operation = Slt;
			4'b0100:  alu_operation = Sltu;
			4'b0101:  alu_operation = Lu;
			
            default:alu_operation = And;
        endcase
      end//always
     
	 //符号扩展与左移两位：
	 assign SignExtend_15_0 = { {16{IR[15]}} , IR[15:0]};
	 assign ShiftLeft_15_0  = SignExtend_15_0 << 2;
	 assign SignExtend_sa	= { {27{sa[4]}}  , sa[4:0] };
	 
     //连接输入
	 //alu_a
	 always@(*)
	  begin
		case(ALUSrcA)
		2'b00:	alu_a = PC;
		2'b01:	alu_a = A;
		2'b10:	alu_a = SignExtend_sa; //移位
		default:alu_a = A;
		endcase
	  end//always
     
	 //alu_b
	 always@(*)
	  begin
		case(ALUSrcB)
		2'b00:	alu_b = B;
		2'b01:	alu_b = 4;
		2'b10:	alu_b = SignExtend_15_0;
		2'b11:	alu_b = ShiftLeft_15_0;
		default:alu_b = B;
		endcase
	  end//always
	  
     //接口配对
     alu  alu_1(alu_a, alu_b, alu_operation, Overflow, CarryOut, Zero, Result);    	  
     
	 //ALU结果寄存器
	 always@(posedge clk)
		reg_ALUOUT <= Result;
     
	 
	 
	 
	 
      
    //////////////////////////////////////////////////////////////////////////////////////////
    //************************  PC ***************************
    //////////////////////////////////////////////////////////////////////////////////////////
    //产生中途信号
    assign ShiftLeft_25_0 = IR[25:0] << 2;
	assign Jmp_addr = { PC[31:28] , ShiftLeft_25_0[27:0] };
	
	//PC写使能信号
	assign PC_enable = PCWrite | (PCWriteBne & ~Zero) | (PCWriteBeq & Zero);
	
    //同步更新PC的值(PC是wire，要更新的是reg_PC)
    always@(posedge clk)
     begin
      if( rst ) 
        reg_PC <= 0;
      
	  else if( !rst && PC_enable )
        begin
			case(PCSource)
			2'b00:	reg_PC <= Result;
			2'b01:	reg_PC <= reg_ALUOUT;
			2'b10:	reg_PC <= Jmp_addr;
			default:reg_PC <= Result;
			endcase
		end//更新PC
	  
	  else
		reg_PC <= reg_PC;
     end//always
     //把PC连接到reg_PC
     assign PC = reg_PC;
    
    
	
	
    ///////////////////////////////////////////////////////////////////////////
    //*****************  连接剩余的输出信号  ********************
    ////////////////////////////////////////////////////////////////////////////
    assign Address = reg_ALUOUT;
    assign Write_data = B;
    
    
endmodule






























