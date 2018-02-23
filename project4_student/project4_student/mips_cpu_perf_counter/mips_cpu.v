`timescale 10ns / 1ns

module mips_cpu(
	input  rst,
	input  clk,

	output [31:0] PC,
	input  [31:0] Instruction,

	output [31:0] Address,
	output MemWrite,
	output [31:0] Write_data,

	input  [31:0] Read_data,
	output MemRead,

	output [31:0] cycle_cnt,		//counter of total cycles
	output [31:0] inst_cnt,			//counter of total instructions
	output [31:0] br_cnt,			//counter of branch/jump instructions
	output [31:0] ld_cnt,			//counter of load instructions
	output [31:0] st_cnt,			//counter of store instructions
	output [31:0] user1_cnt,		//user defined counter (reserved)
	output [31:0] user2_cnt,
	output [31:0] user3_cnt
);

	// TODO: insert your code
		
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //--------------------------------------------------------------------------
    //                                   �ź�           
    //--------------------------------------------------------------------------
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    //////////////////////////////
    //***** �����ź� ********
    //////////////////////////////
    
    //״̬��״̬�ź�
    (*mark_debug = "true" *) reg[4:0] state;        //*********״̬���ĵ�ǰ״̬**********
    (*mark_debug = "true" *) reg[4:0] new_state;    //*********״̬������һ��״̬**********
    /*
    ȫ��reg���͵Ŀ����źš�����ʽ״̬������wire�źż�ƴ��control�ź�������
    reg PCWriteBne; //bne��ת
    reg PCWriteBeq; //beq��ת
    reg PCWrite; //��������ת
    reg reg_MemWrite; assign MemRead = reg_MemRead;
    reg reg_MemRead;  assign MemWrite = reg_MemWrite;
    reg MemToReg; // 1:regд��mem������ 0��regд��alu������
    reg IRWrite;
    reg[1:0] PCSource; //00:PC=PC+4, 01:PC=PC+4+offset (beq,bne) 10:PC=jump��ַ��jump��
    reg[1:0] ALUop; 
    reg ALUSrcA; //0:ALU_a=PC, 1:ALU_a=a;
    reg[1:0] ALUSrcB; //00:ALU_b=B, 01:00:ALU_b=4 10:ALU_b=ָ���16λ������չ 11:ALU_b=ָ���16λ������չ������λ
    reg RegWrite;
    reg RegDst; //0��ָ��[20-16]�� 1��ָ��[15-11]
    //wire Branch;  
    */
    
    //control���ɵĿ����źţ�   
    wire         PCWriteBne; //bne��ת
    wire         PCWriteBeq; //beq��ת
    wire         PCWrite; //��������ת
    wire         MemToReg; // 1:regд��mem������ 0��regд��alu������
    wire         IRWrite;
    wire[1:0]    PCSource; //00:PC=PC+4, 01:PC=PC+4+offset (beq,bne) 10:PC=jump��ַ��jump��
    wire[3:0]    ALUop; 
    wire[1:0]    ALUSrcA; //0:ALU_a=PC, 1:ALU_a=a;
    wire[1:0]    ALUSrcB; //00:ALU_b=B, 01:00:ALU_b=4 10:ALU_b=ָ���16λ������չ 11:ALU_b=ָ���16λ������չ������λ
    wire         RegWrite;
    wire[1:0]    RegDst; //0��ָ��[20-16]�� 1��ָ��[15-11]  ;  2:31
   
    //ƴ�ӵõ����ܿ����ź�
    reg[19:0]     control;
    assign {PCWriteBeq,PCWriteBne,PCWrite,MemRead,MemWrite,IRWrite,RegWrite,MemToReg,PCSource[1:0],ALUop[3:0],ALUSrcA[1:0],ALUSrcB[1:0],RegDst} = control;
 



 
    //////////////////////////////////
    //****** ��;�ĵ����Ĵ��� *******
    //////////////////////////////////
    
    //ָ��Ĵ���
    reg[31:0] IR; //ָ��Ĵ���
    wire[5:0] Op; //������    
    wire[4:0] sa; //��λ�������λ��
    wire[5:0] func; //ĩ6λfunction�ֶ�
    
    //�ڴ����ݼĴ���memory data register
    reg[31:0] MDR;    
    
    //reg_file��������ļĴ���
    reg[31:0] A,B;
    
    //alu����Ĵ���
    reg[31:0] reg_ALUOUT;
    
    //����λ����
    parameter DataWide = 32;
    parameter AddrWide = 5;
   
   
   
   ////////////////////////////////////////
    //***** reg_file �ź� *******
    //////////////////////////////////////
    
    //reg_file ����������ź�
    wire[AddrWide-1:0] raddr1,raddr2;
    reg [AddrWide-1:0] waddr;
    wire[DataWide-1:0] wdata,rdata1,rdata2;
    
    
    
    ///////////////////////////////////////
    //***** ALU�ź�  ********
    //////////////////////////////////////    
    
    //ALU ����������źţ�
    reg[DataWide-1:0] alu_a,alu_b;
    reg[2:0] alu_operation;
    wire Overflow,CarryOut,Zero;
    wire[DataWide-1:0] Result;
    
    //����alu��;������IR��16λ������չ����λ�Ľ��
    wire[31:0] SignExtend_15_0;
    wire[31:0] ShiftLeft_15_0;
    wire[31:0] SignExtend_sa;    //������չ�����λ��
    
    
    
    
    //////////////////////////////
    //***** PC�ź� ********
    //////////////////////////////
    
    //����ʱ���ڴ��ַ��ֻ����������simʱ��ʾ������mem�ĵڼ���λ�ã�û������Ӧ��
    integer i;
    always@(*)  i = PC/4;   
    
    //���¶���һЩreg���͵������Ȼ����assign�����Ǻ���������ϡ�ֱ�Ӱ�PC��������Ϊreg�ᱨwaring
    reg[31:0] reg_PC;
    
    //����PC��;�������ź�
    //�ӷ���1������ӷ���2�����������չ�����������λ���
    wire[27:0] ShiftLeft_25_0; //���ڲ���jump��ת��ַ��һ���м��ź�
    wire[31:0] Jmp_addr; //jump��ת��ַ
    wire PC_enable; //PCдʹ���ź�
    
    
    
    
    //////////////////////////////
    //***** ����������Ĵ��� ********
    //////////////////////////////
    (*mark_debug = "true" *) reg [31:0] reg_cycle_cnt;        //counter of total cycles
    (*mark_debug = "true" *) reg [31:0] reg_inst_cnt;            //counter of total instructions
    (*mark_debug = "true" *) reg [31:0] reg_br_cnt;            //counter of branch/jump instructions
    (*mark_debug = "true" *) reg [31:0] reg_ld_cnt;            //counter of load instructions
    (*mark_debug = "true" *) reg [31:0] reg_st_cnt;            //counter of store instructions
    (*mark_debug = "true" *) reg [31:0] reg_user1_cnt;        //user defined counter (reserved)
    (*mark_debug = "true" *) reg [31:0] reg_user2_cnt;
    (*mark_debug = "true" *) reg [31:0] reg_user3_cnt;
    
    
    /////////////////////////////////////////
    //  ����
    ////////////////////////////////////////
    //�����������ָ�������
    parameter ADDIU = 6'b001_001;
    parameter LW    = 6'b100_011;
    parameter SW    = 6'b101_011;
    parameter BNE   = 6'b000_101;           

    parameter BEQ   = 6'b000_100;    
    parameter Rtype = 6'b000_000;
    parameter J         = 6'b000_010;
    parameter JAL    = 6'b000_011;
    parameter LUI    = 6'b001_111;
    parameter SLTI    = 6'b001_010;
    parameter SLTIU = 6'b001_011;
    
    //������ALU�Ĳ�����
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
    
    //������function�ֶΣ�ָ���6λ��
    parameter func_addu = 6'b100_001;
    parameter func_or    = 6'b100_101;
    parameter func_sll    = 6'b000_000;
    parameter func_slt    = 6'b101_010;
    parameter func_jr    = 6'b001_000;
    
    //������control״̬����״̬
    parameter Ins_Fetch = 0;
    parameter Ins_Decode = 1;
    //lw
    parameter LS1 = 2;//lw��sw�ĵ�һ��
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
    
    //����ADDIU(д�Ĵ�����״̬����addiu��д�Ĵ���״̬������״̬���õĺ�����ͬ)
    //SLTI
    parameter SLTI1 = 15;
    //SLTIU
    parameter SLTIU1 = 16;
    //LUI
    parameter LUI1 = 17;
    
    //����R����flag������ͬ
    parameter R_SLL1 = 18;
    parameter R_JR2 = 19;
    
    
    /////////////////////////////////////////////////////////////////////////////////////
    //-----------------------------------------------------------------
    //                                ��·����
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
    assign Op     = IR[31:26]; //������
    assign sa     = IR[10:6];    //��λ��
    assign func    = IR[5:0];    //R-type�Ĳ�������
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////
    //********************  MDR  *****************************
    //////////////////////////////////////////////////////////////////////////////////////////    
    always@(posedge clk)
        MDR <= Read_data;
    
    
    
    
    
     //////////////////////////////////////////////////////////////////////////////////////////
    //********************  control��������״̬��ʵ�֣�  *****************************
    //////////////////////////////////////////////////////////////////////////////////////////
     //����ʽ״̬��
     //1.��λ��״̬���£�
     always@(posedge clk)
        begin
            if(rst)    state <= Ins_Fetch;
            else    state <= new_state;
        end//always
     
     //2.״̬ת������
     always@(*)
        begin
            case(state)
            Ins_Fetch:    new_state = Ins_Decode;
            Ins_Decode:    begin
                         case(Op)
                         LW:    new_state = LS1;
                         SW:    new_state = LS1;
                         BNE:    new_state =    BNE1;
                         ADDIU:    new_state = ADDIU1;
    //                     NOP:    new_state = Ins_Fetch;
                         
                        ///////////////////////////////////////////////
                        //�������ָ��/////////////////////////////////
                        ///////////////////////////////////////////////
                         BEQ:    new_state = BEQ1;
                         J:        new_state = J1;
                         JAL:    new_state = JAL1;
                         SLTI:    new_state = SLTI1;
                         SLTIU: new_state = SLTIU1;
                         LUI:    new_state = LUI1;
                         Rtype:    if( func === func_sll )    new_state = R_SLL1;
                                else                    new_state = R1;
                         
                         default:new_state = Ins_Fetch;
                         endcase
                        end//Ins_Decode
            //lw,sw
            LS1:        begin
                         case(Op)
                         LW:     new_state = LW2;
                         SW:     new_state = SW2;
                         default:new_state = Ins_Fetch;
                         endcase
                        end//LS1
            
            //lw:
            LW2:        new_state = LW3;
            LW3:        new_state = Ins_Fetch;
            //sw:
            SW2:        new_state = Ins_Fetch;
            //BNE��
            BNE1:        new_state = Ins_Fetch;
            //ADDIU:
            ADDIU1:        new_state = ADDIU2;
            ADDIU2:        new_state = Ins_Fetch;
            ///////////////////////////////////////////////
            //�������ָ��/////////////////////////////////
            ///////////////////////////////////////////////
            //beq:
            BEQ1:        new_state = Ins_Fetch;
            //J:
            J1:            new_state = Ins_Fetch;
            //JAL:
            JAL1:        new_state = JAL2;
            JAL2:        new_state = Ins_Fetch;
            //����ADDIU��
            //SLTI:
            SLTI1:        new_state = ADDIU2;
            //SLTIU:
            SLTIU1:        new_state = ADDIU2;
            //LUI:
            LUI1:        new_state = ADDIU2;
            
            //R������R��sll��jr��:
            R1:    if(func === func_jr)    new_state = R_JR2;
                else                    new_state = R2;            
            R_SLL1:        new_state = R2;
            R2:         new_state = Ins_Fetch;
            R_JR2:        new_state = Ins_Fetch;
            
            default :     new_state = Ins_Fetch;
            endcase
        end//always
        
    //3.�����źŲ�������
    always@(*)
        begin
        //                    //ʹ���ź�                                                                 //ѡͨ�ź�        
        //assign             {PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
    //��׼�����ʽ    control = 20'b__x________x_________x________x_________x_________x________x__________x__________xx___________xxxx__________xx___________xx__________xx;
        case(state)
        Ins_Fetch:    control = 20'b__0________0_________1________1_________0_________1________0__________0__________00___________0000__________00___________01__________00;
        Ins_Decode: control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________00___________11__________00;
        //lw,sw
        LS1:        control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________01___________10__________00;
        //lw
        LW2:        control = 20'b__0________0_________0________1_________0_________0________0__________0__________00___________0000__________00___________00__________00;
        LW3:        control = 20'b__0________0_________0________0_________0_________0________1__________1__________00___________0000__________00___________00__________00;
        //assign             {PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
        //sw
        SW2:        control = 20'b__0________0_________0________0_________1_________0________0__________0__________00___________0000__________00___________00__________00;
        //bne
        BNE1:        control = 20'b__0________1_________0________0_________0_________0________0__________0__________01___________0001__________01___________00__________00;
        //addiu
        ADDIU1:        control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________01___________10__________00;
        ADDIU2:        control = 20'b__0________0_________0________0_________0_________0________1__________0__________00___________0000__________00___________00__________00;
        ///////////////////////////////////////////////
        //�������ָ��/////////////////////////////////
        ///////////////////////////////////////////////
        //assign             {PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
    //��׼�����ʽ    control = 20'b__x________x_________x________x_________x_________x________x__________x__________xx___________xxxx__________xx___________xx__________xx;        
        //bne
        BEQ1:        control = 20'b__1________0_________0________0_________0_________0________0__________0__________01___________0001__________01___________00__________00;
        //Jump:
        J1:            control = 20'b__0________0_________1________0_________0_________0________0__________0__________10___________0000__________00___________00__________00;
        //JAL:
        JAL1:        control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________00___________01__________00;
        JAL2:        control = 20'b__0________0_________1________0_________0_________0________1__________0__________10___________0000__________00___________00__________10;
        //assign             {PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
        //����ADDIU��
        //SLTI:
        SLTI1:        control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0011__________01___________10__________00;
        //SLTIU:
        SLTIU1:        control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0100__________01___________10__________00;
        //LUI:
        LUI1:        control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0101__________01___________10__________00;
        //assign             {PCWriteBeq, PCWriteBne, PCWrite, MemRead, MemWrite, IRWrite, RegWrite, MemToReg, PCSource[1:0], ALUop[3:0], ALUSrcA[1:0], ALUSrcB[1:0], RegDst} = control;
        //R-type������R��sll��jr��
        R1:            control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0010__________01___________00__________00;    
        R_SLL1:        control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0010__________10___________00__________00;    
        R2:            control = 20'b__0________0_________0________0_________0_________0________1__________0__________00___________0000__________00___________00__________01;        
        R_JR2:        control = 20'b__0________0_________1________0_________0_________0________0__________0__________01___________0000__________00___________00__________00;        
        
        default:    control = 20'b__0________0_________0________0_________0_________0________0__________0__________00___________0000__________00___________00__________00;
        endcase
        end//always
     /*
     //��Ϊһ��ʽ״̬����д����̫�����ˣ���ʱ�Ȳ��ã���������ʽ״̬���ع�
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
                    ALUSrcA     <= 0; //PC
                    ALUSrcB     <= 2'b01; //4
                    IRWrite     <= 1;
                    ALUop        <= 2'b00;
                    PCWrite        <= 1;
                    PCSource    <= 2'b00;
                    end//Ins_Fetch
                
                Ins_Decode:
                    begin
                        //state
                        case(Op)
                        LW:     state<=LS1;
                        SW:     state<=LS1;
                        BNE:    state<=BNE1;
                        ADDIU:    state<=ADDIU1;
                        NOP:    state<=Ins_Fetch;
                        //�����ָ��
                        /////////////////
                        default:state<=Ins_Fetch;
                        endcase
                        ALUSrcA    <= 0;
                        ALUSrcB <= 2'b11;
                        ALUop    <= 2'b00;
                    end//Ins_Decode
                
                default:state<=Ins_Fetch;
                
                endcase
        end//always
     */
     
     
     
     
     
     //////////////////////////////////////////////////////////////////////////////////////////
     //*****************  reg_file  *****************************
     //////////////////////////////////////////////////////////////////////////////////////////
     //����reg_file�Ľӿ�
     //��������
     assign raddr1 = IR[25:21];
     assign raddr2 = IR[20:16];
     
     //waddr
     always@(*)
        begin
        case(RegDst)
        2'b00:    waddr = IR[20:16];
        2'b01:    waddr = IR[15:11];
        2'b10:    waddr = 31;
        default:waddr = IR[20:16];
        endcase
        end//always
        
     assign wdata = (MemToReg === 1)? MDR : reg_ALUOUT;
     
     //�ӿ����
     reg_file  rf(clk, rst, waddr, raddr1, raddr2, RegWrite, wdata, rdata1, rdata2);     
     
     //reg_file��������ļĴ���
     always@(posedge clk)
        begin
        A <= rdata1;
        B <= rdata2;
        end//always
     
     
     
     
     
     
     //////////////////////////////////////////////////////////////////////////////////////////
     //******************** alu *******************************
     //////////////////////////////////////////////////////////////////////////////////////////
     //����alu�Ĳ����ź�
     always@(*)
      begin
        case(ALUop)           
            //���������Ӧ�Ĳ���
            4'b0000:  alu_operation = Add; //LW,SW,ADDIU,NOP(NOP�ǿղ���������alu��ʲô���㶼����,result��д��memҲ��д��reg��
            4'b0001:  alu_operation = Sub; //BNE
            
            ///////////////////////////////////////////////
            //�������ָ��/////////////////////////////////
            ///////////////////////////////////////////////
            4'b0010://R-type
                begin
                    case(func)
                    func_addu:    alu_operation = Add;
                    func_jr:    alu_operation = Add;
                    func_or:    alu_operation = Or;
                    func_sll:    alu_operation = Sll;
                    func_slt:    alu_operation = Slt;
                    default:    alu_operation = Add;
                    endcase
                end//R-type
            
            4'b0011:  alu_operation = Slt;
            4'b0100:  alu_operation = Sltu;
            4'b0101:  alu_operation = Lu;
            
            default:alu_operation = And;
        endcase
      end//always
     
     //������չ��������λ��
     assign SignExtend_15_0 = { {16{IR[15]}} , IR[15:0]};
     assign ShiftLeft_15_0  = SignExtend_15_0 << 2;
     assign SignExtend_sa    = { {27{sa[4]}}  , sa[4:0] };
     
     //��������
     //alu_a
     always@(*)
      begin
        case(ALUSrcA)
        2'b00:    alu_a = PC;
        2'b01:    alu_a = A;
        2'b10:    alu_a = SignExtend_sa; //��λ
        default:alu_a = A;
        endcase
      end//always
     
     //alu_b
     always@(*)
      begin
        case(ALUSrcB)
        2'b00:    alu_b = B;
        2'b01:    alu_b = 4;
        2'b10:    alu_b = SignExtend_15_0;
        2'b11:    alu_b = ShiftLeft_15_0;
        default:alu_b = B;
        endcase
      end//always
      
     //�ӿ����
     alu  alu_1(alu_a, alu_b, alu_operation, Overflow, CarryOut, Zero, Result);          
     
     //ALU����Ĵ���
     always@(posedge clk)
        reg_ALUOUT <= Result;
     
     
     
     
     
      
    //////////////////////////////////////////////////////////////////////////////////////////
    //************************  PC ***************************
    //////////////////////////////////////////////////////////////////////////////////////////
    //������;�ź�
    assign ShiftLeft_25_0 = IR[25:0] << 2;
    assign Jmp_addr = { PC[31:28] , ShiftLeft_25_0[27:0] };
    
    //PCдʹ���ź�
    assign PC_enable = PCWrite | (PCWriteBne & ~Zero) | (PCWriteBeq & Zero);
    
    //ͬ������PC��ֵ(PC��wire��Ҫ���µ���reg_PC)
    always@(posedge clk)
     begin
      if( rst ) 
        reg_PC <= 0;
      
      else if( !rst && PC_enable )
        begin
            case(PCSource)
            2'b00:    reg_PC <= Result;
            2'b01:    reg_PC <= reg_ALUOUT;
            2'b10:    reg_PC <= Jmp_addr;
            default:reg_PC <= Result;
            endcase
        end//����PC
      
      else
        reg_PC <= reg_PC;
     end//always
     //��PC���ӵ�reg_PC
     assign PC = reg_PC;
    
    //////////////////////////////////////////////////////////////////////////////////////////
    //************************  ��������� ***************************
    //////////////////////////////////////////////////////////////////////////////////////////
    
    //�������
    assign cycle_cnt         = reg_cycle_cnt;        //counter of total cycles
    assign inst_cnt     = reg_inst_cnt;            //counter of total instructions
    assign br_cnt            = reg_br_cnt;            //counter of branch/jump instructions
    assign ld_cnt            = reg_ld_cnt;            //counter of load instructions
    assign st_cnt            = reg_st_cnt;            //counter of store instructions
    //�����������/////////////////////////////////////////////////////////////////////////////
    assign user1_cnt    = cycle_cnt;        //user defined counter (reserved)
    assign user2_cnt    = cycle_cnt;
    assign user3_cnt    = cycle_cnt;
    
    // reg_cycle_cnt ͳ�Ƴ���ִ�е�����
    always@(posedge clk)
        begin
        if(rst)
            reg_cycle_cnt <= 0;
        else
            reg_cycle_cnt <= reg_cycle_cnt +1;
        end

        
    // reg_inst_cnt    ͳ�Ƴ���ִ�е�ָ������
    always@(posedge clk)
        begin
        if(rst)
            reg_inst_cnt <= 0 ;
        else if(state === Ins_Fetch)
            reg_inst_cnt <= reg_inst_cnt +1;
        else
            reg_inst_cnt <= reg_inst_cnt;
        end
    
    
    // reg_br_cnt ͳ�Ƴ����е�branch/jumpָ������ִ������ָ�û������ת����Ҳ+1��
    always@(posedge clk)
        begin
        if(rst)
            reg_br_cnt <= 0;
        else if(state !== Ins_Fetch && (PCWrite === 1 || PCWriteBeq === 1 || PCWriteBne ===1) )
            reg_br_cnt <= reg_br_cnt +1;
        else
            reg_br_cnt <= reg_br_cnt;
        end
    
    
    // reg_ld_cnt ͳ�ƶ��ڴ��ָ����
    always@(posedge clk)
        begin
        if(rst)
            reg_ld_cnt <= 0;
        else if(state !== Ins_Fetch && MemRead === 1)
            reg_ld_cnt <= reg_ld_cnt +1;
        else
            reg_ld_cnt <= reg_ld_cnt;
        end
        
        
    // reg_st_cnt ͳ��д�ڴ��ָ����    
    always@(posedge clk)
        begin
        if(rst)
            reg_st_cnt <= 0;
        else if(state !== Ins_Fetch && MemWrite === 1)
            reg_st_cnt <= reg_st_cnt +1;
        else
            reg_st_cnt <= reg_st_cnt;
        end
        
    // reg_user1_cnt
    // reg_user2_cnt
    // reg_user3_cnt
    
    
    ///////////////////////////////////////////////////////////////////////////
    //*****************  ����ʣ�������ź�  ********************
    ////////////////////////////////////////////////////////////////////////////
    assign Address = reg_ALUOUT;
    assign Write_data = B;
    

endmodule
