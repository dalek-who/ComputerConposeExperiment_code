/* =========================================
* Ideal Memory Module for MIPS CPU Core
* Synchronize write (clock enable)
* Asynchronize read (do not use clock signal)
*
* Author: Yisong Chang (changyisong@ict.ac.cn)
* Date: 31/05/2016
* Version: v0.0.1
*===========================================
*/

`timescale 1 ps / 1 ps

module ideal_mem #(
	parameter ADDR_WIDTH = 10,
	parameter MEM_WIDTH = 2 ** (ADDR_WIDTH - 2)
	) (
	input			clk,			//source clock of the MIPS CPU Evaluation Module

	input [ADDR_WIDTH - 1:0]	Waddr,			//Memory write port address
	input [ADDR_WIDTH - 1:0]	Raddr1,			//Read port 1 address
	input [ADDR_WIDTH - 1:0]	Raddr2,			//Read port 2 address

	input			Wren,			//write enable
	input			Rden1,			//port 1 read enable
	input			Rden2,			//port 2 read enable

	input [31:0]	Wdata,			//Memory write data
	output [31:0]	Rdata1,			//Memory read data 1
	output [31:0]	Rdata2			//Memory read data 2
);

reg [31:0]	mem [MEM_WIDTH - 1:0];

`define ADDIU(rt, rs,   imm)    {6'b001001, rs,   rt, imm};
//`define LW   (rt, base, offset) {6'b100011, base, rt, offset};
//`define SW   (rt, base, offset) {6'b101011, base, rt, offset};
//`define BNE  (rt, rs,   offset) {6'b000101, base, rt, offset};
//`define NOP                {32'b0};

`ifdef MIPS_CPU_SIM

    parameter LW    = 6'b100011;
    parameter SW    = 6'b101011;
    parameter BNE   = 6'b000101;
    parameter NOP   = 32'b0;    
	//Add memory initialization here
	initial begin
		mem[0] = `ADDIU(5'd1, 5'd0, 16'd100);
		//TODO: Please update the memory initialization with your owm instructions and data
		//each initialization data is 32-bit
		//e.g.,
		//mem[0] = `ADDID(5'd2, 5'd0, 16'd10);
		//mem[1] = xxxx;
		//mem[2] = xxxx;
		
		//test: ADDIU
		mem[1] = `ADDIU(5'd1, 5'd0, 16'd101);
		mem[2] = `ADDIU(5'd2, 5'd0, 16'd100);
		mem[3] = `ADDIU(5'd2, 5'd1, 16'd7);
		mem[4] = `ADDIU(5'd0, 5'd1, 16'd7);
		mem[5] = `ADDIU(5'd2, 5'd2, 16'd9);
		
		//////////////////////////////////////////////////////////////////////////////
		//Ϊlw��swԤ����ר��������ȡ�����õ��ڴ�����
				
		//200-209:lw������
		mem[200] = 12;
		mem[201] = 24;
		mem[202] = 36;
		mem[203] = 48;
		mem[204] = 60;
        mem[205] = 72;
        
        //210-219:sw������
        
        //230--:bne������������
        
        ////////////////////////////////////////////////////////////////////////////
        //test��sw
        //��reg��׼������
        //д���ڴ�����ݣ�
        mem[11] = `ADDIU(5'd1, 5'd0, 16'd1);
        mem[12] = `ADDIU(5'd2, 5'd0, 16'd2);
        mem[13] = `ADDIU(5'd3, 5'd0, 16'd3);
        mem[14] = `ADDIU(5'd4, 5'd0, 16'd4);
        mem[15] = `ADDIU(5'd5, 5'd0, 16'd5);
                
        //�ڴ��ַ��
        //��reg������������ݻᱻ����4��Ϊ�ڴ��ַ
        //Ҫ����д����ڴ�������210--214
        mem[16] = `ADDIU(5'd6, 5'd0, 16'd840);
        mem[17] = `ADDIU(5'd7, 5'd0, 16'd844);
        mem[18] = `ADDIU(5'd8, 5'd0, 16'd848);
        mem[19] = `ADDIU(5'd9, 5'd0, 16'd852);
        mem[20] = `ADDIU(5'd10, 5'd0, 16'd856);
        
        //sw����ָ��
        mem[21] =  {SW, 5'd6,5'd1, 16'd0};//mem 210
        //������ͬһ��mem��sw��ͬ���ݣ��������ܷ������ı�
        mem[22] =  {SW, 5'd7,5'd1, 16'd0};//mem 211
        mem[23] =  {SW, 5'd7,5'd2, 16'd0};//mem 211
        //����ƫ����Ϊ����0���������
        mem[24] =  {SW, 5'd9,5'd3, 16'b1111_1111_1111_1100};//ƫ����-1 mem 212
        mem[25] =  {SW, 5'd9,5'd4, 16'd0}; //mem 213
        mem[26] =  {SW, 5'd9,5'd5, 16'd4}; //mem 214
        
        ////////////////////////////////////////////////////////////////////////////////
        //test:lw
        //��reg��׼����������
        //���ݣ�
        //reg 1~5���������ܲ���lw������lw����֮ǰ�Ƚ���Щ������0
        mem[41] = `ADDIU(5'd1, 5'd0, 16'd0);
        mem[42] = `ADDIU(5'd2, 5'd0, 16'd0);
        mem[43] = `ADDIU(5'd3, 5'd0, 16'd0);
        mem[44] = `ADDIU(5'd4, 5'd0, 16'd0);
        mem[45] = `ADDIU(5'd5, 5'd0, 16'd0);
        //�ڴ��ַ
        mem[46] = `ADDIU(5'd6, 5'd0, 16'd800);
        mem[47] = `ADDIU(5'd7, 5'd0, 16'd804);
        mem[48] = `ADDIU(5'd8, 5'd0, 16'd808);
        mem[49] = `ADDIU(5'd9, 5'd0, 16'd812);
        mem[50] = `ADDIU(5'd10, 5'd0, 16'd816);
        /*
        //����Ҫ��rt���ǼĴ�����
        //�ڼĴ���11~16�д�����Ҫ���ԵļĴ�����ַ��0-5��
        mem[51] = `ADDIU(5'd11, 5'd0, 16'd0);
        mem[52] = `ADDIU(5'd12, 5'd0, 16'd1);
        mem[53] = `ADDIU(5'd13, 5'd0, 16'd2);
        mem[54] = `ADDIU(5'd14, 5'd0, 16'd3);
        mem[55] = `ADDIU(5'd15, 5'd0, 16'd4);                
        mem[56] = `ADDIU(5'd16, 5'd0, 16'd5);      
        */
        
        //sw����ָ��
        //lw 0�żĴ���
        mem[70] = {LW, 5'd6,5'd0, 16'd0};
        //lwָ��
        mem[71] = {LW, 5'd6,5'd1, 16'd0};
        //lwͬһ�Ĵ���
        mem[72] = {LW, 5'd6,5'd2, 16'd0};
        mem[73] = {LW, 5'd7,5'd2, 16'd4};
        //ƫ����Ϊ�����㡢��
        mem[74] = {LW, 5'd9,5'd3, 16'b1111_1111_1111_1100};
        mem[75] = {LW, 5'd9,5'd4, 16'd0};
        mem[76] = {LW, 5'd9,5'd5, 16'd4};
		
		//test:BNE
		//reg׼������
		mem[91] = `ADDIU(5'd1, 5'd0, 16'd1 );
		mem[92] = `ADDIU(5'd2, 5'd0, 16'd1 );
		mem[93] = `ADDIU(5'd3, 5'd0, 16'd3 );
		mem[94] = `ADDIU(5'd4, 5'd0, 16'd3 );
		mem[95] = `ADDIU(5'd5, 5'd0, 16'd5 );
		mem[96] = `ADDIU(5'd10, 5'd0, 16'd920);
		//BNE����ָ��
		//�Ƚ�ͬһ�Ĵ���
		mem[100] = {BNE, 5'd1, 5'd1, 16'd2};
		//�Ƚϲ�ͬ�Ĵ���
		mem[101] = {BNE, 5'd2, 5'd1, 16'd2}; //ֵ��ͬ������ת
		mem[102] = {BNE, 5'd3, 5'd1, 16'd2}; //ֵ��ͬ�������ת����ת��105
		mem[103] = `ADDIU(5'd28, 5'd0, 16'd123); //�����ת�ɹ���������ָ���ִ��
		mem[104] = {SW, 5'd10, 5'd5, 16'd4}; 	//�����ת�ɹ���������ָ���ִ��
		
		//��ǰ��ת�Ĳ��ԣ�
		mem[105] = `ADDIU(5'd2, 5'd2, 16'd1 ); //ִ��mem[108]����ת������
		mem[106] = NOP; 	//˳����Կղ���
		mem[107] = {SW, 5'd10, 5'd1, 16'd8};
		mem[108] = {BNE, 5'd2, 5'd5, 16'b1111_1111_1111_1100}; //������������reg[1]�е��������������ӵ�5�󣬾Ͳ�Ӧ������ǰ��ת����Ӧ�����ִ��
		//��ѭ����
		mem[109] = `ADDIU(5'd15, 5'd15, 16'b0011_1111_1111_1111 );
		mem[110] = {BNE, 5'd0, 5'd1, 16'b1111_1111_1111_1110};
		
/*		
		//��reg��д������
		mem[6]  = `ADDIU(5'd6,  5'd0, 16'd600);
		mem[7]  = `ADDIU(5'd7,  5'd0, 16'd700);
		mem[8]  = `ADDIU(5'd8,  5'd0, 16'd800);
		mem[9]  = `ADDIU(5'd9,  5'd0, 16'd600);
		mem[10] = `ADDIU(5'd10, 5'd0, 16'd700);
		mem[11] = `ADDIU(5'd11, 5'd0, 16'd820);
		
		//test: NOP
		mem[12] = NOP;
		mem[13] = `ADDIU(5'd13, 5'd0, 16'd16);
		mem[14] = `ADDIU(5'd14, 5'd0, 16'd17);
		mem[15] = `ADDIU(5'd15, 5'd0, 16'd18);
		
	   mem[16] = `ADDIU(5'd16, 5'd0, 16'd160);
	   mem[17] = `ADDIU(5'd17, 5'd0, 16'd170);
	   mem[18] = `ADDIU(5'd18, 5'd0, 16'd180);
	   mem[19]  = NOP;
		//test: BNE
		

		
		//test: LW
		
	    mem[20] = {LW, 5'd25,5'd16, 16'd0};
	    mem[21] = {LW, 5'd25,5'd17, 16'd2};
	    mem[22] = {LW, 5'd27,5'd18, 16'd1111_1111_1111_1110};
		
		mem[25]= 32'd250;
		mem[26]= 32'd260;
		mem[27]= 32'd270;
		
		//test: SW
		mem[30] = {SW, 5'd6,5'd6, 16'd0};
		mem[31] = {SW, 5'd6,5'd7, 16'd12};
		mem[32] = {SW, 5'd7,5'd7, 16'd8};
		mem[33] = {SW, 5'd7,5'd7, 16'b1111_1111_1111_1000};
		*/
	end
`endif

always @ (posedge clk)
begin
	if (Wren)
		mem[Waddr] <= Wdata;
end

assign Rdata1 = {32{Rden1}} & mem[Raddr1];
assign Rdata2 = {32{Rden2}} & mem[Raddr2];

endmodule
