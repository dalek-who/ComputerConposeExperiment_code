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
	parameter ADDR_WIDTH = 10,	// 1KB
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

`define ADDIU(rt, rs, imm) {6'b001001, rs, rt, imm}
`define LW(rt, base, off) {6'b100011, base, rt, off}
`define SW(rt, base, off) {6'b101011, base, rt, off}
`define BNE(rs, rt, off) {6'b000101, rs, rt, off}

`ifdef MIPS_CPU_SIM
	
	parameter NOP   = 32'b0;  
	integer TestNumber = 1;
	parameter WaitTime = 2_000_000_00;
	//wire[31:0] global_reslut;
	//assign global_result = mem[3];
	
	//Add memory initialization here
	initial begin
	/*
	//各项功能单元测试 success
         
            
                     //test: ADDIU
                    mem[0] = `ADDIU(5'd1, 5'd0, 16'd100);                              
                    mem[1] = `ADDIU(5'd1, 5'd0, 16'd101);
                    mem[2] = `ADDIU(5'd2, 5'd0, 16'd100);
                    mem[3] = `ADDIU(5'd2, 5'd1, 16'd7);
                    mem[4] = `ADDIU(5'd0, 5'd1, 16'd7);
                    mem[5] = `ADDIU(5'd2, 5'd2, 16'd9);
                    
                    //////////////////////////////////////////////////////////////////////////////
                    //为lw，sw预留的专门用来存取数据用的内存区域
                            
                    //200-209:lw数据区
                    mem[200] = 12;
                    mem[201] = 24;
                    mem[202] = 36;
                    mem[203] = 48;
                    mem[204] = 60;
                    mem[205] = 72;
                    
                    //210-219:sw数据区
                    
                    //230--:bne测试用数据区
                    
                    ////////////////////////////////////////////////////////////////////////////
                    //test：sw
                    //在reg中准备数据
                    //写入内存的数据：
                    mem[11] = `ADDIU(5'd1, 5'd0, 16'd1);
                    mem[12] = `ADDIU(5'd2, 5'd0, 16'd2);
                    mem[13] = `ADDIU(5'd3, 5'd0, 16'd3);
                    mem[14] = `ADDIU(5'd4, 5'd0, 16'd4);
                    mem[15] = `ADDIU(5'd5, 5'd0, 16'd5);
                            
                    //内存地址：
                    //从reg里读出来的数据会被除以4做为内存地址
                    //要测试写入的内存区域是210--214
                    mem[16] = `ADDIU(5'd6, 5'd0, 16'd840);
                    mem[17] = `ADDIU(5'd7, 5'd0, 16'd844);
                    mem[18] = `ADDIU(5'd8, 5'd0, 16'd848);
                    mem[19] = `ADDIU(5'd9, 5'd0, 16'd852);
                    mem[20] = `ADDIU(5'd10, 5'd0, 16'd856);
                    
                    //sw测试指令
                    mem[21] =  `SW(5'd1,5'd6, 16'd0);//mem 210
                    //测试在同一个mem里sw不同数据，看数据能否正常改变
                    mem[22] =  `SW(5'd1,5'd7, 16'd0);//mem 211
                    mem[23] =  `SW(5'd2,5'd7, 16'd0);//mem 211
                    //测试偏移量为负、0、正的情况
                    mem[24] =  `SW(5'd3,5'd9, 16'b1111_1111_1111_1100);//偏移量-1 mem 212
                    mem[25] =  `SW(5'd4,5'd9, 16'd0); //mem 213
                    mem[26] =  `SW(5'd5,5'd9, 16'd4); //mem 214
                    
                    
                    ////////////////////////////////////////////////////////////////////////////////
                    //test:lw
                    //在reg中准备测试数据
                    //数据：
                    //reg 1~5用来测试能不能lw进来。lw测试之前先将这些区域清0
                    mem[41] = `ADDIU(5'd1, 5'd0, 16'd0);
                    mem[42] = `ADDIU(5'd2, 5'd0, 16'd0);
                    mem[43] = `ADDIU(5'd3, 5'd0, 16'd0);
                    mem[44] = `ADDIU(5'd4, 5'd0, 16'd0);
                    mem[45] = `ADDIU(5'd5, 5'd0, 16'd0);
                    //内存地址
                    mem[46] = `ADDIU(5'd6, 5'd0, 16'd800);
                    mem[47] = `ADDIU(5'd7, 5'd0, 16'd804);
                    mem[48] = `ADDIU(5'd8, 5'd0, 16'd808);
                    mem[49] = `ADDIU(5'd9, 5'd0, 16'd812);
                    mem[50] = `ADDIU(5'd10, 5'd0, 16'd816);
                    
                    //lw测试指令
                    //lw 0号寄存器
                    mem[70] = `LW( 5'd0,5'd6, 16'd0);
                    //lw指令
                    mem[71] = `LW( 5'd1,5'd6, 16'd0);
                    //lw同一寄存器
                    mem[72] = `LW( 5'd2,5'd6, 16'd0);
                    mem[73] = `LW( 5'd2,5'd7, 16'd4);
                    //偏移量为负、零、正
                    mem[74] = `LW( 5'd3,5'd9, 16'b1111_1111_1111_1100);
                    mem[75] = `LW( 5'd4,5'd9, 16'd0);
                    mem[76] = `LW( 5'd5,5'd9, 16'd4);
                    
                    
                    //test:BNE
                    //reg准备数据
                    mem[91] = `ADDIU(5'd1, 5'd0, 16'd1 );
                    mem[92] = `ADDIU(5'd2, 5'd0, 16'd1 );
                    mem[93] = `ADDIU(5'd3, 5'd0, 16'd3 );
                    mem[94] = `ADDIU(5'd4, 5'd0, 16'd3 );
                    mem[95] = `ADDIU(5'd5, 5'd0, 16'd5 );
                    mem[96] = `ADDIU(5'd10, 5'd0, 16'd920);
                    //BNE测试指令
                    //比较同一寄存器
                    mem[100] = `BNE( 5'd1, 5'd1, 16'd2);
                    //比较不同寄存器
                    mem[101] = `BNE( 5'd2, 5'd1, 16'd2); //值相同，不跳转
                    mem[102] = `BNE( 5'd3, 5'd1, 16'd2); //值不同，向后跳转：跳转到105
                    mem[103] = `ADDIU(5'd28, 5'd0, 16'd123); //如果跳转成功，则这条指令不会执行
                    mem[104] = `SW(  5'd5,5'd10, 16'd4);     //如果跳转成功，则这条指令不会执行
                    
                    //向前跳转的测试：
                    mem[105] = `ADDIU(5'd2, 5'd2, 16'd1 ); //执行mem[108]后跳转回这里
                    mem[106] = NOP;     //顺便测试空操作
                    mem[107] = `SW(  5'd1,5'd10, 16'd8);
                    mem[108] = `BNE( 5'd2, 5'd5, 16'b1111_1111_1111_1100); //回跳三步。给reg[1]中的数据自增，增加到5后，就不应该再向前跳转，而应该向后执行
                    //死循环：
                    mem[109] = `ADDIU(5'd15, 5'd15, 16'b0011_1111_1111_1111 );
                    mem[110] = `BNE( 5'd0, 5'd1, 16'b1111_1111_1111_1110);    
                           
        */
		/*
	//memcpy success
		
		// fill memory region [100, 200) with [0, 100)
		mem[0] = `ADDIU(5'd1, 5'd0, 16'd100);
		mem[1] = `ADDIU(5'd2, 5'd0, 16'd0);
		mem[2] = `SW(5'd2, 5'd2, 16'd100);
		mem[3] = `ADDIU(5'd2, 5'd2, 16'd4);
		mem[4] = `BNE(5'd1, 5'd2, 16'hfffd);

		// copy memory region [100, 200) to memory region [200, 300)
		mem[5] = `ADDIU(5'd2, 5'd0, 16'd0);
		mem[6] = `LW(5'd3, 5'd2, 16'd100);
		mem[7] = `SW(5'd3, 5'd2, 16'd200);
		mem[8] = `ADDIU(5'd2, 5'd2, 16'd4);
		mem[9] = `BNE(5'd1, 5'd2, 16'hfffc);

		mem[10] = `BNE(5'd1, 5'd0, 16'hffff);
	*/	
	
	//add.vh : success
	
	mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c00000e;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h00851021;    // addr = 0x2c
    mem[12] = 32'h03e00008;    // addr = 0x30
    mem[13] = 32'h00000000;    // addr = 0x34
    mem[14] = 32'h3c0d0000;    // addr = 0x38
    mem[15] = 32'h3c0c0000;    // addr = 0x3c
    mem[16] = 32'h258c01e8;    // addr = 0x40
    mem[17] = 32'h3c0b0000;    // addr = 0x44
    mem[18] = 32'h3c070000;    // addr = 0x48
    mem[19] = 32'h8da9000c;    // addr = 0x4c
    mem[20] = 32'h256b00e8;    // addr = 0x50
    mem[21] = 32'h24e70208;    // addr = 0x54
    mem[22] = 32'h01805025;    // addr = 0x58
    mem[23] = 32'h00004025;    // addr = 0x5c
    mem[24] = 32'h8d460000;    // addr = 0x60
    mem[25] = 32'h01602025;    // addr = 0x64
    mem[26] = 32'h01801025;    // addr = 0x68
    mem[27] = 32'h8c430000;    // addr = 0x6c
    mem[28] = 32'h8c850000;    // addr = 0x70
    mem[29] = 32'h00c31821;    // addr = 0x74
    mem[30] = 32'h10650005;    // addr = 0x78
    mem[31] = 32'h00000000;    // addr = 0x7c
    mem[32] = 32'h08000009;    // addr = 0x80
    mem[33] = 32'h00000000;    // addr = 0x84
    mem[34] = 32'h24080001;    // addr = 0x88
    mem[35] = 32'h24090001;    // addr = 0x8c
    mem[36] = 32'h24420004;    // addr = 0x90
    mem[37] = 32'h24840004;    // addr = 0x94
    mem[38] = 32'h1447fff4;    // addr = 0x98
    mem[39] = 32'h00000000;    // addr = 0x9c
    mem[40] = 32'h254a0004;    // addr = 0xa0
    mem[41] = 32'h256b0020;    // addr = 0xa4
    mem[42] = 32'h144affed;    // addr = 0xa8
    mem[43] = 32'h00000000;    // addr = 0xac
    mem[44] = 32'h15000004;    // addr = 0xb0
    mem[45] = 32'h00000000;    // addr = 0xb4
    mem[46] = 32'h00001025;    // addr = 0xb8
    mem[47] = 32'h03e00008;    // addr = 0xbc
    mem[48] = 32'h00000000;    // addr = 0xc0
    mem[49] = 32'hada9000c;    // addr = 0xc4
    mem[50] = 32'h1000fffb;    // addr = 0xc8
    mem[51] = 32'h00000000;    // addr = 0xcc
    mem[52] = 32'h01200000;    // addr = 0xd0
    mem[53] = 32'h01000101;    // addr = 0xd4
    mem[54] = 32'h00000000;    // addr = 0xd8
    mem[55] = 32'h00000000;    // addr = 0xdc
    mem[56] = 32'h00000001;    // addr = 0xe0
    mem[57] = 32'h00000000;    // addr = 0xe4
    mem[58] = 32'h00000000;    // addr = 0xe8
    mem[59] = 32'h00000001;    // addr = 0xec
    mem[60] = 32'h00000002;    // addr = 0xf0
    mem[61] = 32'h7fffffff;    // addr = 0xf4
    mem[62] = 32'h80000000;    // addr = 0xf8
    mem[63] = 32'h80000001;    // addr = 0xfc
    mem[64] = 32'hfffffffe;    // addr = 0x100
    mem[65] = 32'hffffffff;    // addr = 0x104
    mem[66] = 32'h00000001;    // addr = 0x108
    mem[67] = 32'h00000002;    // addr = 0x10c
    mem[68] = 32'h00000003;    // addr = 0x110
    mem[69] = 32'h80000000;    // addr = 0x114
    mem[70] = 32'h80000001;    // addr = 0x118
    mem[71] = 32'h80000002;    // addr = 0x11c
    mem[72] = 32'hffffffff;    // addr = 0x120
    mem[73] = 32'h00000000;    // addr = 0x124
    mem[74] = 32'h00000002;    // addr = 0x128
    mem[75] = 32'h00000003;    // addr = 0x12c
    mem[76] = 32'h00000004;    // addr = 0x130
    mem[77] = 32'h80000001;    // addr = 0x134
    mem[78] = 32'h80000002;    // addr = 0x138
    mem[79] = 32'h80000003;    // addr = 0x13c
    mem[80] = 32'h00000000;    // addr = 0x140
    mem[81] = 32'h00000001;    // addr = 0x144
    mem[82] = 32'h7fffffff;    // addr = 0x148
    mem[83] = 32'h80000000;    // addr = 0x14c
    mem[84] = 32'h80000001;    // addr = 0x150
    mem[85] = 32'hfffffffe;    // addr = 0x154
    mem[86] = 32'hffffffff;    // addr = 0x158
    mem[87] = 32'h00000000;    // addr = 0x15c
    mem[88] = 32'h7ffffffd;    // addr = 0x160
    mem[89] = 32'h7ffffffe;    // addr = 0x164
    mem[90] = 32'h80000000;    // addr = 0x168
    mem[91] = 32'h80000001;    // addr = 0x16c
    mem[92] = 32'h80000002;    // addr = 0x170
    mem[93] = 32'hffffffff;    // addr = 0x174
    mem[94] = 32'h00000000;    // addr = 0x178
    mem[95] = 32'h00000001;    // addr = 0x17c
    mem[96] = 32'h7ffffffe;    // addr = 0x180
    mem[97] = 32'h7fffffff;    // addr = 0x184
    mem[98] = 32'h80000001;    // addr = 0x188
    mem[99] = 32'h80000002;    // addr = 0x18c
    mem[100] = 32'h80000003;    // addr = 0x190
    mem[101] = 32'h00000000;    // addr = 0x194
    mem[102] = 32'h00000001;    // addr = 0x198
    mem[103] = 32'h00000002;    // addr = 0x19c
    mem[104] = 32'h7fffffff;    // addr = 0x1a0
    mem[105] = 32'h80000000;    // addr = 0x1a4
    mem[106] = 32'hfffffffe;    // addr = 0x1a8
    mem[107] = 32'hffffffff;    // addr = 0x1ac
    mem[108] = 32'h00000000;    // addr = 0x1b0
    mem[109] = 32'h7ffffffd;    // addr = 0x1b4
    mem[110] = 32'h7ffffffe;    // addr = 0x1b8
    mem[111] = 32'h7fffffff;    // addr = 0x1bc
    mem[112] = 32'hfffffffc;    // addr = 0x1c0
    mem[113] = 32'hfffffffd;    // addr = 0x1c4
    mem[114] = 32'hffffffff;    // addr = 0x1c8
    mem[115] = 32'h00000000;    // addr = 0x1cc
    mem[116] = 32'h00000001;    // addr = 0x1d0
    mem[117] = 32'h7ffffffe;    // addr = 0x1d4
    mem[118] = 32'h7fffffff;    // addr = 0x1d8
    mem[119] = 32'h80000000;    // addr = 0x1dc
    mem[120] = 32'hfffffffd;    // addr = 0x1e0
    mem[121] = 32'hfffffffe;    // addr = 0x1e4
    mem[122] = 32'h00000000;    // addr = 0x1e8
    mem[123] = 32'h00000001;    // addr = 0x1ec
    mem[124] = 32'h00000002;    // addr = 0x1f0
    mem[125] = 32'h7fffffff;    // addr = 0x1f4
    mem[126] = 32'h80000000;    // addr = 0x1f8
    mem[127] = 32'h80000001;    // addr = 0x1fc
    mem[128] = 32'hfffffffe;    // addr = 0x200
    mem[129] = 32'hffffffff;    // addr = 0x204
	
	
	//2.bubble_sort.vh success
	
	wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
	mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c000025;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h3c080000;    // addr = 0x2c
    mem[12] = 32'h24070013;    // addr = 0x30
    mem[13] = 32'h25080228;    // addr = 0x34
    mem[14] = 32'h2409ffff;    // addr = 0x38
    mem[15] = 32'h00001825;    // addr = 0x3c
    mem[16] = 32'h0067202a;    // addr = 0x40
    mem[17] = 32'h01001025;    // addr = 0x44
    mem[18] = 32'h1080000d;    // addr = 0x48
    mem[19] = 32'h00000000;    // addr = 0x4c
    mem[20] = 32'h8c440000;    // addr = 0x50
    mem[21] = 32'h8c450004;    // addr = 0x54
    mem[22] = 32'h24630001;    // addr = 0x58
    mem[23] = 32'h00a4302a;    // addr = 0x5c
    mem[24] = 32'h10c00003;    // addr = 0x60
    mem[25] = 32'h00000000;    // addr = 0x64
    mem[26] = 32'hac450000;    // addr = 0x68
    mem[27] = 32'hac440004;    // addr = 0x6c
    mem[28] = 32'h0067202a;    // addr = 0x70
    mem[29] = 32'h24420004;    // addr = 0x74
    mem[30] = 32'h1480fff5;    // addr = 0x78
    mem[31] = 32'h00000000;    // addr = 0x7c
    mem[32] = 32'h24e7ffff;    // addr = 0x80
    mem[33] = 32'h14e9ffed;    // addr = 0x84
    mem[34] = 32'h00000000;    // addr = 0x88
    mem[35] = 32'h03e00008;    // addr = 0x8c
    mem[36] = 32'h00000000;    // addr = 0x90
    mem[37] = 32'h3c090000;    // addr = 0x94
    mem[38] = 32'h24070013;    // addr = 0x98
    mem[39] = 32'h25290228;    // addr = 0x9c
    mem[40] = 32'h240affff;    // addr = 0xa0
    mem[41] = 32'h00001825;    // addr = 0xa4
    mem[42] = 32'h0067202a;    // addr = 0xa8
    mem[43] = 32'h01204025;    // addr = 0xac
    mem[44] = 32'h01201025;    // addr = 0xb0
    mem[45] = 32'h1080000d;    // addr = 0xb4
    mem[46] = 32'h00000000;    // addr = 0xb8
    mem[47] = 32'h8c440000;    // addr = 0xbc
    mem[48] = 32'h8c450004;    // addr = 0xc0
    mem[49] = 32'h24630001;    // addr = 0xc4
    mem[50] = 32'h00a4302a;    // addr = 0xc8
    mem[51] = 32'h10c00003;    // addr = 0xcc
    mem[52] = 32'h00000000;    // addr = 0xd0
    mem[53] = 32'hac450000;    // addr = 0xd4
    mem[54] = 32'hac440004;    // addr = 0xd8
    mem[55] = 32'h0067202a;    // addr = 0xdc
    mem[56] = 32'h24420004;    // addr = 0xe0
    mem[57] = 32'h1480fff5;    // addr = 0xe4
    mem[58] = 32'h00000000;    // addr = 0xe8
    mem[59] = 32'h24e7ffff;    // addr = 0xec
    mem[60] = 32'h14eaffec;    // addr = 0xf0
    mem[61] = 32'h00000000;    // addr = 0xf4
    mem[62] = 32'h3c0b0000;    // addr = 0xf8
    mem[63] = 32'h8d67000c;    // addr = 0xfc
    mem[64] = 32'h01201825;    // addr = 0x100
    mem[65] = 32'h00003025;    // addr = 0x104
    mem[66] = 32'h00001025;    // addr = 0x108
    mem[67] = 32'h24050014;    // addr = 0x10c
    mem[68] = 32'h8c640000;    // addr = 0x110
    mem[69] = 32'h10820005;    // addr = 0x114
    mem[70] = 32'h00000000;    // addr = 0x118
    mem[71] = 32'h08000009;    // addr = 0x11c
    mem[72] = 32'h00000000;    // addr = 0x120
    mem[73] = 32'h24060001;    // addr = 0x124
    mem[74] = 32'h24070001;    // addr = 0x128
    mem[75] = 32'h24420001;    // addr = 0x12c
    mem[76] = 32'h24630004;    // addr = 0x130
    mem[77] = 32'h1445fff6;    // addr = 0x134
    mem[78] = 32'h00000000;    // addr = 0x138
    mem[79] = 32'h14c0002b;    // addr = 0x13c
    mem[80] = 32'h00000000;    // addr = 0x140
    mem[81] = 32'h24070013;    // addr = 0x144
    mem[82] = 32'h240affff;    // addr = 0x148
    mem[83] = 32'h00001825;    // addr = 0x14c
    mem[84] = 32'h0067202a;    // addr = 0x150
    mem[85] = 32'h01201025;    // addr = 0x154
    mem[86] = 32'h1080000d;    // addr = 0x158
    mem[87] = 32'h00000000;    // addr = 0x15c
    mem[88] = 32'h8c440000;    // addr = 0x160
    mem[89] = 32'h8c450004;    // addr = 0x164
    mem[90] = 32'h24630001;    // addr = 0x168
    mem[91] = 32'h00a4302a;    // addr = 0x16c
    mem[92] = 32'h10c00003;    // addr = 0x170
    mem[93] = 32'h00000000;    // addr = 0x174
    mem[94] = 32'hac450000;    // addr = 0x178
    mem[95] = 32'hac440004;    // addr = 0x17c
    mem[96] = 32'h0067202a;    // addr = 0x180
    mem[97] = 32'h24420004;    // addr = 0x184
    mem[98] = 32'h1480fff5;    // addr = 0x188
    mem[99] = 32'h00000000;    // addr = 0x18c
    mem[100] = 32'h24e7ffff;    // addr = 0x190
    mem[101] = 32'h14eaffed;    // addr = 0x194
    mem[102] = 32'h00000000;    // addr = 0x198
    mem[103] = 32'h8d66000c;    // addr = 0x19c
    mem[104] = 32'h00002825;    // addr = 0x1a0
    mem[105] = 32'h00001025;    // addr = 0x1a4
    mem[106] = 32'h24040014;    // addr = 0x1a8
    mem[107] = 32'h8d030000;    // addr = 0x1ac
    mem[108] = 32'h10620005;    // addr = 0x1b0
    mem[109] = 32'h00000000;    // addr = 0x1b4
    mem[110] = 32'h08000009;    // addr = 0x1b8
    mem[111] = 32'h00000000;    // addr = 0x1bc
    mem[112] = 32'h24050001;    // addr = 0x1c0
    mem[113] = 32'h24060001;    // addr = 0x1c4
    mem[114] = 32'h24420001;    // addr = 0x1c8
    mem[115] = 32'h25080004;    // addr = 0x1cc
    mem[116] = 32'h1444fff6;    // addr = 0x1d0
    mem[117] = 32'h00000000;    // addr = 0x1d4
    mem[118] = 32'h14a00009;    // addr = 0x1d8
    mem[119] = 32'h00000000;    // addr = 0x1dc
    mem[120] = 32'h00001025;    // addr = 0x1e0
    mem[121] = 32'h03e00008;    // addr = 0x1e4
    mem[122] = 32'h00000000;    // addr = 0x1e8
    mem[123] = 32'had67000c;    // addr = 0x1ec
    mem[124] = 32'h240affff;    // addr = 0x1f0
    mem[125] = 32'h24070013;    // addr = 0x1f4
    mem[126] = 32'h1000ffd4;    // addr = 0x1f8
    mem[127] = 32'h00000000;    // addr = 0x1fc
    mem[128] = 32'had66000c;    // addr = 0x200
    mem[129] = 32'h1000fff6;    // addr = 0x204
    mem[130] = 32'h00000000;    // addr = 0x208
    mem[131] = 32'h00000000;    // addr = 0x20c
    mem[132] = 32'h01200000;    // addr = 0x210
    mem[133] = 32'h01000101;    // addr = 0x214
    mem[134] = 32'h00000000;    // addr = 0x218
    mem[135] = 32'h00000000;    // addr = 0x21c
    mem[136] = 32'h00000001;    // addr = 0x220
    mem[137] = 32'h00000000;    // addr = 0x224
    mem[138] = 32'h00000002;    // addr = 0x228
    mem[139] = 32'h0000000c;    // addr = 0x22c
    mem[140] = 32'h0000000e;    // addr = 0x230
    mem[141] = 32'h00000006;    // addr = 0x234
    mem[142] = 32'h0000000d;    // addr = 0x238
    mem[143] = 32'h0000000f;    // addr = 0x23c
    mem[144] = 32'h00000010;    // addr = 0x240
    mem[145] = 32'h0000000a;    // addr = 0x244
    mem[146] = 32'h00000000;    // addr = 0x248
    mem[147] = 32'h00000012;    // addr = 0x24c
    mem[148] = 32'h0000000b;    // addr = 0x250
    mem[149] = 32'h00000013;    // addr = 0x254
    mem[150] = 32'h00000009;    // addr = 0x258
    mem[151] = 32'h00000001;    // addr = 0x25c
    mem[152] = 32'h00000007;    // addr = 0x260
    mem[153] = 32'h00000005;    // addr = 0x264
    mem[154] = 32'h00000004;    // addr = 0x268
    mem[155] = 32'h00000003;    // addr = 0x26c
    mem[156] = 32'h00000008;    // addr = 0x270
    mem[157] = 32'h00000011;    // addr = 0x274
    end
    
	
    //3.fib.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c00000b;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h3c0a0000;    // addr = 0x2c
    mem[12] = 32'h3c020000;    // addr = 0x30
    mem[13] = 32'h3c040000;    // addr = 0x34
    mem[14] = 32'h3c070000;    // addr = 0x38
    mem[15] = 32'h8d49000c;    // addr = 0x3c
    mem[16] = 32'h24420168;    // addr = 0x40
    mem[17] = 32'h248400d0;    // addr = 0x44
    mem[18] = 32'h24e70200;    // addr = 0x48
    mem[19] = 32'h00004025;    // addr = 0x4c
    mem[20] = 32'h8c430004;    // addr = 0x50
    mem[21] = 32'h8c460000;    // addr = 0x54
    mem[22] = 32'h8c850000;    // addr = 0x58
    mem[23] = 32'h00661821;    // addr = 0x5c
    mem[24] = 32'hac430008;    // addr = 0x60
    mem[25] = 32'h10650005;    // addr = 0x64
    mem[26] = 32'h00000000;    // addr = 0x68
    mem[27] = 32'h08000009;    // addr = 0x6c
    mem[28] = 32'h00000000;    // addr = 0x70
    mem[29] = 32'h24080001;    // addr = 0x74
    mem[30] = 32'h24090001;    // addr = 0x78
    mem[31] = 32'h24420004;    // addr = 0x7c
    mem[32] = 32'h24840004;    // addr = 0x80
    mem[33] = 32'h1447fff2;    // addr = 0x84
    mem[34] = 32'h00000000;    // addr = 0x88
    mem[35] = 32'h15000004;    // addr = 0x8c
    mem[36] = 32'h00000000;    // addr = 0x90
    mem[37] = 32'h00001025;    // addr = 0x94
    mem[38] = 32'h03e00008;    // addr = 0x98
    mem[39] = 32'h00000000;    // addr = 0x9c
    mem[40] = 32'had49000c;    // addr = 0xa0
    mem[41] = 32'h1000fffb;    // addr = 0xa4
    mem[42] = 32'h00000000;    // addr = 0xa8
    mem[43] = 32'h00000000;    // addr = 0xac
    mem[44] = 32'h01200000;    // addr = 0xb0
    mem[45] = 32'h01000101;    // addr = 0xb4
    mem[46] = 32'h00000000;    // addr = 0xb8
    mem[47] = 32'h00000000;    // addr = 0xbc
    mem[48] = 32'h00000001;    // addr = 0xc0
    mem[49] = 32'h00000000;    // addr = 0xc4
    mem[50] = 32'h00000001;    // addr = 0xc8
    mem[51] = 32'h00000001;    // addr = 0xcc
    mem[52] = 32'h00000002;    // addr = 0xd0
    mem[53] = 32'h00000003;    // addr = 0xd4
    mem[54] = 32'h00000005;    // addr = 0xd8
    mem[55] = 32'h00000008;    // addr = 0xdc
    mem[56] = 32'h0000000d;    // addr = 0xe0
    mem[57] = 32'h00000015;    // addr = 0xe4
    mem[58] = 32'h00000022;    // addr = 0xe8
    mem[59] = 32'h00000037;    // addr = 0xec
    mem[60] = 32'h00000059;    // addr = 0xf0
    mem[61] = 32'h00000090;    // addr = 0xf4
    mem[62] = 32'h000000e9;    // addr = 0xf8
    mem[63] = 32'h00000179;    // addr = 0xfc
    mem[64] = 32'h00000262;    // addr = 0x100
    mem[65] = 32'h000003db;    // addr = 0x104
    mem[66] = 32'h0000063d;    // addr = 0x108
    mem[67] = 32'h00000a18;    // addr = 0x10c
    mem[68] = 32'h00001055;    // addr = 0x110
    mem[69] = 32'h00001a6d;    // addr = 0x114
    mem[70] = 32'h00002ac2;    // addr = 0x118
    mem[71] = 32'h0000452f;    // addr = 0x11c
    mem[72] = 32'h00006ff1;    // addr = 0x120
    mem[73] = 32'h0000b520;    // addr = 0x124
    mem[74] = 32'h00012511;    // addr = 0x128
    mem[75] = 32'h0001da31;    // addr = 0x12c
    mem[76] = 32'h0002ff42;    // addr = 0x130
    mem[77] = 32'h0004d973;    // addr = 0x134
    mem[78] = 32'h0007d8b5;    // addr = 0x138
    mem[79] = 32'h000cb228;    // addr = 0x13c
    mem[80] = 32'h00148add;    // addr = 0x140
    mem[81] = 32'h00213d05;    // addr = 0x144
    mem[82] = 32'h0035c7e2;    // addr = 0x148
    mem[83] = 32'h005704e7;    // addr = 0x14c
    mem[84] = 32'h008cccc9;    // addr = 0x150
    mem[85] = 32'h00e3d1b0;    // addr = 0x154
    mem[86] = 32'h01709e79;    // addr = 0x158
    mem[87] = 32'h02547029;    // addr = 0x15c
    mem[88] = 32'h03c50ea2;    // addr = 0x160
    mem[89] = 32'h06197ecb;    // addr = 0x164
    mem[90] = 32'h00000001;    // addr = 0x168
    mem[91] = 32'h00000001;    // addr = 0x16c
    mem[92] = 32'h00000000;    // addr = 0x170
    mem[93] = 32'h00000000;    // addr = 0x174
    mem[94] = 32'h00000000;    // addr = 0x178
    mem[95] = 32'h00000000;    // addr = 0x17c
    mem[96] = 32'h00000000;    // addr = 0x180
    mem[97] = 32'h00000000;    // addr = 0x184
    mem[98] = 32'h00000000;    // addr = 0x188
    mem[99] = 32'h00000000;    // addr = 0x18c
    mem[100] = 32'h00000000;    // addr = 0x190
    mem[101] = 32'h00000000;    // addr = 0x194
    mem[102] = 32'h00000000;    // addr = 0x198
    mem[103] = 32'h00000000;    // addr = 0x19c
    mem[104] = 32'h00000000;    // addr = 0x1a0
    mem[105] = 32'h00000000;    // addr = 0x1a4
    mem[106] = 32'h00000000;    // addr = 0x1a8
    mem[107] = 32'h00000000;    // addr = 0x1ac
    mem[108] = 32'h00000000;    // addr = 0x1b0
    mem[109] = 32'h00000000;    // addr = 0x1b4
    mem[110] = 32'h00000000;    // addr = 0x1b8
    mem[111] = 32'h00000000;    // addr = 0x1bc
    mem[112] = 32'h00000000;    // addr = 0x1c0
    mem[113] = 32'h00000000;    // addr = 0x1c4
    mem[114] = 32'h00000000;    // addr = 0x1c8
    mem[115] = 32'h00000000;    // addr = 0x1cc
    mem[116] = 32'h00000000;    // addr = 0x1d0
    mem[117] = 32'h00000000;    // addr = 0x1d4
    mem[118] = 32'h00000000;    // addr = 0x1d8
    mem[119] = 32'h00000000;    // addr = 0x1dc
    mem[120] = 32'h00000000;    // addr = 0x1e0
    mem[121] = 32'h00000000;    // addr = 0x1e4
    mem[122] = 32'h00000000;    // addr = 0x1e8
    mem[123] = 32'h00000000;    // addr = 0x1ec
    mem[124] = 32'h00000000;    // addr = 0x1f0
    mem[125] = 32'h00000000;    // addr = 0x1f4
    mem[126] = 32'h00000000;    // addr = 0x1f8
    mem[127] = 32'h00000000;    // addr = 0x1fc
    mem[128] = 32'h00000000;    // addr = 0x200
    mem[129] = 32'h00000000;    // addr = 0x204
    end
    
    //4.if-else.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c000036;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h27bdfff0;    // addr = 0x2c
    mem[12] = 32'hafbe000c;    // addr = 0x30
    mem[13] = 32'h03a0f025;    // addr = 0x34
    mem[14] = 32'hafc40010;    // addr = 0x38
    mem[15] = 32'h8fc20010;    // addr = 0x3c
    mem[16] = 32'h284201f5;    // addr = 0x40
    mem[17] = 32'h14400005;    // addr = 0x44
    mem[18] = 32'h00000000;    // addr = 0x48
    mem[19] = 32'h24020096;    // addr = 0x4c
    mem[20] = 32'hafc20000;    // addr = 0x50
    mem[21] = 32'h1000001a;    // addr = 0x54
    mem[22] = 32'h00000000;    // addr = 0x58
    mem[23] = 32'h8fc20010;    // addr = 0x5c
    mem[24] = 32'h2842012d;    // addr = 0x60
    mem[25] = 32'h14400005;    // addr = 0x64
    mem[26] = 32'h00000000;    // addr = 0x68
    mem[27] = 32'h24020064;    // addr = 0x6c
    mem[28] = 32'hafc20000;    // addr = 0x70
    mem[29] = 32'h10000012;    // addr = 0x74
    mem[30] = 32'h00000000;    // addr = 0x78
    mem[31] = 32'h8fc20010;    // addr = 0x7c
    mem[32] = 32'h28420065;    // addr = 0x80
    mem[33] = 32'h14400005;    // addr = 0x84
    mem[34] = 32'h00000000;    // addr = 0x88
    mem[35] = 32'h2402004b;    // addr = 0x8c
    mem[36] = 32'hafc20000;    // addr = 0x90
    mem[37] = 32'h1000000a;    // addr = 0x94
    mem[38] = 32'h00000000;    // addr = 0x98
    mem[39] = 32'h8fc20010;    // addr = 0x9c
    mem[40] = 32'h28420033;    // addr = 0xa0
    mem[41] = 32'h14400005;    // addr = 0xa4
    mem[42] = 32'h00000000;    // addr = 0xa8
    mem[43] = 32'h24020032;    // addr = 0xac
    mem[44] = 32'hafc20000;    // addr = 0xb0
    mem[45] = 32'h10000002;    // addr = 0xb4
    mem[46] = 32'h00000000;    // addr = 0xb8
    mem[47] = 32'hafc00000;    // addr = 0xbc
    mem[48] = 32'h8fc20000;    // addr = 0xc0
    mem[49] = 32'h03c0e825;    // addr = 0xc4
    mem[50] = 32'h8fbe000c;    // addr = 0xc8
    mem[51] = 32'h27bd0010;    // addr = 0xcc
    mem[52] = 32'h03e00008;    // addr = 0xd0
    mem[53] = 32'h00000000;    // addr = 0xd4
    mem[54] = 32'h27bdffe0;    // addr = 0xd8
    mem[55] = 32'hafbf001c;    // addr = 0xdc
    mem[56] = 32'hafbe0018;    // addr = 0xe0
    mem[57] = 32'h03a0f025;    // addr = 0xe4
    mem[58] = 32'hafc00014;    // addr = 0xe8
    mem[59] = 32'hafc00010;    // addr = 0xec
    mem[60] = 32'h1000001d;    // addr = 0xf0
    mem[61] = 32'h00000000;    // addr = 0xf4
    mem[62] = 32'h3c020000;    // addr = 0xf8
    mem[63] = 32'h8fc30010;    // addr = 0xfc
    mem[64] = 32'h00031880;    // addr = 0x100
    mem[65] = 32'h244201d0;    // addr = 0x104
    mem[66] = 32'h00621021;    // addr = 0x108
    mem[67] = 32'h8c420000;    // addr = 0x10c
    mem[68] = 32'h00402025;    // addr = 0x110
    mem[69] = 32'h0c00000b;    // addr = 0x114
    mem[70] = 32'h00000000;    // addr = 0x118
    mem[71] = 32'h00402825;    // addr = 0x11c
    mem[72] = 32'h8fc20014;    // addr = 0x120
    mem[73] = 32'h24430001;    // addr = 0x124
    mem[74] = 32'hafc30014;    // addr = 0x128
    mem[75] = 32'h3c040000;    // addr = 0x12c
    mem[76] = 32'h00021880;    // addr = 0x130
    mem[77] = 32'h24820208;    // addr = 0x134
    mem[78] = 32'h00621021;    // addr = 0x138
    mem[79] = 32'h8c420000;    // addr = 0x13c
    mem[80] = 32'h10a20006;    // addr = 0x140
    mem[81] = 32'h00000000;    // addr = 0x144
    mem[82] = 32'h3c020000;    // addr = 0x148
    mem[83] = 32'h24030001;    // addr = 0x14c
    mem[84] = 32'hac43000c;    // addr = 0x150
    mem[85] = 32'h08000009;    // addr = 0x154
    mem[86] = 32'h00000000;    // addr = 0x158
    mem[87] = 32'h8fc20010;    // addr = 0x15c
    mem[88] = 32'h24420001;    // addr = 0x160
    mem[89] = 32'hafc20010;    // addr = 0x164
    mem[90] = 32'h8fc20010;    // addr = 0x168
    mem[91] = 32'h2c42000e;    // addr = 0x16c
    mem[92] = 32'h1440ffe1;    // addr = 0x170
    mem[93] = 32'h00000000;    // addr = 0x174
    mem[94] = 32'h8fc30010;    // addr = 0x178
    mem[95] = 32'h2402000e;    // addr = 0x17c
    mem[96] = 32'h10620006;    // addr = 0x180
    mem[97] = 32'h00000000;    // addr = 0x184
    mem[98] = 32'h3c020000;    // addr = 0x188
    mem[99] = 32'h24030001;    // addr = 0x18c
    mem[100] = 32'hac43000c;    // addr = 0x190
    mem[101] = 32'h08000009;    // addr = 0x194
    mem[102] = 32'h00000000;    // addr = 0x198
    mem[103] = 32'h00001025;    // addr = 0x19c
    mem[104] = 32'h03c0e825;    // addr = 0x1a0
    mem[105] = 32'h8fbf001c;    // addr = 0x1a4
    mem[106] = 32'h8fbe0018;    // addr = 0x1a8
    mem[107] = 32'h27bd0020;    // addr = 0x1ac
    mem[108] = 32'h03e00008;    // addr = 0x1b0
    mem[109] = 32'h00000000;    // addr = 0x1b4
    mem[110] = 32'h01200000;    // addr = 0x1b8
    mem[111] = 32'h01000101;    // addr = 0x1bc
    mem[112] = 32'h00000000;    // addr = 0x1c0
    mem[113] = 32'h00000000;    // addr = 0x1c4
    mem[114] = 32'h00000001;    // addr = 0x1c8
    mem[115] = 32'h00000000;    // addr = 0x1cc
    mem[116] = 32'hffffffff;    // addr = 0x1d0
    mem[117] = 32'h00000000;    // addr = 0x1d4
    mem[118] = 32'h00000031;    // addr = 0x1d8
    mem[119] = 32'h00000032;    // addr = 0x1dc
    mem[120] = 32'h00000033;    // addr = 0x1e0
    mem[121] = 32'h00000063;    // addr = 0x1e4
    mem[122] = 32'h00000064;    // addr = 0x1e8
    mem[123] = 32'h00000065;    // addr = 0x1ec
    mem[124] = 32'h0000012b;    // addr = 0x1f0
    mem[125] = 32'h0000012c;    // addr = 0x1f4
    mem[126] = 32'h0000012d;    // addr = 0x1f8
    mem[127] = 32'h000001f3;    // addr = 0x1fc
    mem[128] = 32'h000001f4;    // addr = 0x200
    mem[129] = 32'h000001f5;    // addr = 0x204
    mem[130] = 32'h00000000;    // addr = 0x208
    mem[131] = 32'h00000000;    // addr = 0x20c
    mem[132] = 32'h00000000;    // addr = 0x210
    mem[133] = 32'h00000000;    // addr = 0x214
    mem[134] = 32'h00000032;    // addr = 0x218
    mem[135] = 32'h00000032;    // addr = 0x21c
    mem[136] = 32'h00000032;    // addr = 0x220
    mem[137] = 32'h0000004b;    // addr = 0x224
    mem[138] = 32'h0000004b;    // addr = 0x228
    mem[139] = 32'h0000004b;    // addr = 0x22c
    mem[140] = 32'h00000064;    // addr = 0x230
    mem[141] = 32'h00000064;    // addr = 0x234
    mem[142] = 32'h00000064;    // addr = 0x238
    mem[143] = 32'h00000096;    // addr = 0x23c
    end
	
	//5.max.vh success
	wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
	mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c000021;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h27bdfff0;    // addr = 0x2c
    mem[12] = 32'hafbe000c;    // addr = 0x30
    mem[13] = 32'h03a0f025;    // addr = 0x34
    mem[14] = 32'hafc40010;    // addr = 0x38
    mem[15] = 32'hafc50014;    // addr = 0x3c
    mem[16] = 32'h8fc30010;    // addr = 0x40
    mem[17] = 32'h8fc20014;    // addr = 0x44
    mem[18] = 32'h0043102a;    // addr = 0x48
    mem[19] = 32'h10400005;    // addr = 0x4c
    mem[20] = 32'h00000000;    // addr = 0x50
    mem[21] = 32'h8fc20010;    // addr = 0x54
    mem[22] = 32'hafc20000;    // addr = 0x58
    mem[23] = 32'h10000003;    // addr = 0x5c
    mem[24] = 32'h00000000;    // addr = 0x60
    mem[25] = 32'h8fc20014;    // addr = 0x64
    mem[26] = 32'hafc20000;    // addr = 0x68
    mem[27] = 32'h8fc20000;    // addr = 0x6c
    mem[28] = 32'h03c0e825;    // addr = 0x70
    mem[29] = 32'h8fbe000c;    // addr = 0x74
    mem[30] = 32'h27bd0010;    // addr = 0x78
    mem[31] = 32'h03e00008;    // addr = 0x7c
    mem[32] = 32'h00000000;    // addr = 0x80
    mem[33] = 32'h27bdffd8;    // addr = 0x84
    mem[34] = 32'hafbf0024;    // addr = 0x88
    mem[35] = 32'hafbe0020;    // addr = 0x8c
    mem[36] = 32'h03a0f025;    // addr = 0x90
    mem[37] = 32'hafc00018;    // addr = 0x94
    mem[38] = 32'hafc00010;    // addr = 0x98
    mem[39] = 32'h10000036;    // addr = 0x9c
    mem[40] = 32'h00000000;    // addr = 0xa0
    mem[41] = 32'hafc00014;    // addr = 0xa4
    mem[42] = 32'h10000023;    // addr = 0xa8
    mem[43] = 32'h00000000;    // addr = 0xac
    mem[44] = 32'h3c020000;    // addr = 0xb0
    mem[45] = 32'h8fc30010;    // addr = 0xb4
    mem[46] = 32'h00031880;    // addr = 0xb8
    mem[47] = 32'h244201e0;    // addr = 0xbc
    mem[48] = 32'h00621021;    // addr = 0xc0
    mem[49] = 32'h8c440000;    // addr = 0xc4
    mem[50] = 32'h3c020000;    // addr = 0xc8
    mem[51] = 32'h8fc30014;    // addr = 0xcc
    mem[52] = 32'h00031880;    // addr = 0xd0
    mem[53] = 32'h244201e0;    // addr = 0xd4
    mem[54] = 32'h00621021;    // addr = 0xd8
    mem[55] = 32'h8c420000;    // addr = 0xdc
    mem[56] = 32'h00402825;    // addr = 0xe0
    mem[57] = 32'h0c00000b;    // addr = 0xe4
    mem[58] = 32'h00000000;    // addr = 0xe8
    mem[59] = 32'h00402825;    // addr = 0xec
    mem[60] = 32'h8fc20018;    // addr = 0xf0
    mem[61] = 32'h24430001;    // addr = 0xf4
    mem[62] = 32'hafc30018;    // addr = 0xf8
    mem[63] = 32'h3c040000;    // addr = 0xfc
    mem[64] = 32'h00021880;    // addr = 0x100
    mem[65] = 32'h24820200;    // addr = 0x104
    mem[66] = 32'h00621021;    // addr = 0x108
    mem[67] = 32'h8c420000;    // addr = 0x10c
    mem[68] = 32'h10a20006;    // addr = 0x110
    mem[69] = 32'h00000000;    // addr = 0x114
    mem[70] = 32'h3c020000;    // addr = 0x118
    mem[71] = 32'h24030001;    // addr = 0x11c
    mem[72] = 32'hac43000c;    // addr = 0x120
    mem[73] = 32'h08000009;    // addr = 0x124
    mem[74] = 32'h00000000;    // addr = 0x128
    mem[75] = 32'h8fc20014;    // addr = 0x12c
    mem[76] = 32'h24420001;    // addr = 0x130
    mem[77] = 32'hafc20014;    // addr = 0x134
    mem[78] = 32'h8fc20014;    // addr = 0x138
    mem[79] = 32'h2c420008;    // addr = 0x13c
    mem[80] = 32'h1440ffdb;    // addr = 0x140
    mem[81] = 32'h00000000;    // addr = 0x144
    mem[82] = 32'h8fc30014;    // addr = 0x148
    mem[83] = 32'h24020008;    // addr = 0x14c
    mem[84] = 32'h10620006;    // addr = 0x150
    mem[85] = 32'h00000000;    // addr = 0x154
    mem[86] = 32'h3c020000;    // addr = 0x158
    mem[87] = 32'h24030001;    // addr = 0x15c
    mem[88] = 32'hac43000c;    // addr = 0x160
    mem[89] = 32'h08000009;    // addr = 0x164
    mem[90] = 32'h00000000;    // addr = 0x168
    mem[91] = 32'h8fc20010;    // addr = 0x16c
    mem[92] = 32'h24420001;    // addr = 0x170
    mem[93] = 32'hafc20010;    // addr = 0x174
    mem[94] = 32'h8fc20010;    // addr = 0x178
    mem[95] = 32'h2c420008;    // addr = 0x17c
    mem[96] = 32'h1440ffc8;    // addr = 0x180
    mem[97] = 32'h00000000;    // addr = 0x184
    mem[98] = 32'h8fc30010;    // addr = 0x188
    mem[99] = 32'h24020008;    // addr = 0x18c
    mem[100] = 32'h10620006;    // addr = 0x190
    mem[101] = 32'h00000000;    // addr = 0x194
    mem[102] = 32'h3c020000;    // addr = 0x198
    mem[103] = 32'h24030001;    // addr = 0x19c
    mem[104] = 32'hac43000c;    // addr = 0x1a0
    mem[105] = 32'h08000009;    // addr = 0x1a4
    mem[106] = 32'h00000000;    // addr = 0x1a8
    mem[107] = 32'h00001025;    // addr = 0x1ac
    mem[108] = 32'h03c0e825;    // addr = 0x1b0
    mem[109] = 32'h8fbf0024;    // addr = 0x1b4
    mem[110] = 32'h8fbe0020;    // addr = 0x1b8
    mem[111] = 32'h27bd0028;    // addr = 0x1bc
    mem[112] = 32'h03e00008;    // addr = 0x1c0
    mem[113] = 32'h00000000;    // addr = 0x1c4
    mem[114] = 32'h01200000;    // addr = 0x1c8
    mem[115] = 32'h01000101;    // addr = 0x1cc
    mem[116] = 32'h00000000;    // addr = 0x1d0
    mem[117] = 32'h00000000;    // addr = 0x1d4
    mem[118] = 32'h00000001;    // addr = 0x1d8
    mem[119] = 32'h00000000;    // addr = 0x1dc
    mem[120] = 32'h00000000;    // addr = 0x1e0
    mem[121] = 32'h00000001;    // addr = 0x1e4
    mem[122] = 32'h00000002;    // addr = 0x1e8
    mem[123] = 32'h7fffffff;    // addr = 0x1ec
    mem[124] = 32'h80000000;    // addr = 0x1f0
    mem[125] = 32'h80000001;    // addr = 0x1f4
    mem[126] = 32'hfffffffe;    // addr = 0x1f8
    mem[127] = 32'hffffffff;    // addr = 0x1fc
    mem[128] = 32'h00000000;    // addr = 0x200
    mem[129] = 32'h00000001;    // addr = 0x204
    mem[130] = 32'h00000002;    // addr = 0x208
    mem[131] = 32'h7fffffff;    // addr = 0x20c
    mem[132] = 32'h00000000;    // addr = 0x210
    mem[133] = 32'h00000000;    // addr = 0x214
    mem[134] = 32'h00000000;    // addr = 0x218
    mem[135] = 32'h00000000;    // addr = 0x21c
    mem[136] = 32'h00000001;    // addr = 0x220
    mem[137] = 32'h00000001;    // addr = 0x224
    mem[138] = 32'h00000002;    // addr = 0x228
    mem[139] = 32'h7fffffff;    // addr = 0x22c
    mem[140] = 32'h00000001;    // addr = 0x230
    mem[141] = 32'h00000001;    // addr = 0x234
    mem[142] = 32'h00000001;    // addr = 0x238
    mem[143] = 32'h00000001;    // addr = 0x23c
    mem[144] = 32'h00000002;    // addr = 0x240
    mem[145] = 32'h00000002;    // addr = 0x244
    mem[146] = 32'h00000002;    // addr = 0x248
    mem[147] = 32'h7fffffff;    // addr = 0x24c
    mem[148] = 32'h00000002;    // addr = 0x250
    mem[149] = 32'h00000002;    // addr = 0x254
    mem[150] = 32'h00000002;    // addr = 0x258
    mem[151] = 32'h00000002;    // addr = 0x25c
    mem[152] = 32'h7fffffff;    // addr = 0x260
    mem[153] = 32'h7fffffff;    // addr = 0x264
    mem[154] = 32'h7fffffff;    // addr = 0x268
    mem[155] = 32'h7fffffff;    // addr = 0x26c
    mem[156] = 32'h7fffffff;    // addr = 0x270
    mem[157] = 32'h7fffffff;    // addr = 0x274
    mem[158] = 32'h7fffffff;    // addr = 0x278
    mem[159] = 32'h7fffffff;    // addr = 0x27c
    mem[160] = 32'h00000000;    // addr = 0x280
    mem[161] = 32'h00000001;    // addr = 0x284
    mem[162] = 32'h00000002;    // addr = 0x288
    mem[163] = 32'h7fffffff;    // addr = 0x28c
    mem[164] = 32'h80000000;    // addr = 0x290
    mem[165] = 32'h80000001;    // addr = 0x294
    mem[166] = 32'hfffffffe;    // addr = 0x298
    mem[167] = 32'hffffffff;    // addr = 0x29c
    mem[168] = 32'h00000000;    // addr = 0x2a0
    mem[169] = 32'h00000001;    // addr = 0x2a4
    mem[170] = 32'h00000002;    // addr = 0x2a8
    mem[171] = 32'h7fffffff;    // addr = 0x2ac
    mem[172] = 32'h80000001;    // addr = 0x2b0
    mem[173] = 32'h80000001;    // addr = 0x2b4
    mem[174] = 32'hfffffffe;    // addr = 0x2b8
    mem[175] = 32'hffffffff;    // addr = 0x2bc
    mem[176] = 32'h00000000;    // addr = 0x2c0
    mem[177] = 32'h00000001;    // addr = 0x2c4
    mem[178] = 32'h00000002;    // addr = 0x2c8
    mem[179] = 32'h7fffffff;    // addr = 0x2cc
    mem[180] = 32'hfffffffe;    // addr = 0x2d0
    mem[181] = 32'hfffffffe;    // addr = 0x2d4
    mem[182] = 32'hfffffffe;    // addr = 0x2d8
    mem[183] = 32'hffffffff;    // addr = 0x2dc
    mem[184] = 32'h00000000;    // addr = 0x2e0
    mem[185] = 32'h00000001;    // addr = 0x2e4
    mem[186] = 32'h00000002;    // addr = 0x2e8
    mem[187] = 32'h7fffffff;    // addr = 0x2ec
    mem[188] = 32'hffffffff;    // addr = 0x2f0
    mem[189] = 32'hffffffff;    // addr = 0x2f4
    mem[190] = 32'hffffffff;    // addr = 0x2f8
    mem[191] = 32'hffffffff;    // addr = 0x2fc
    end
    
    //6.min3.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c000029;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h27bdfff0;    // addr = 0x2c
    mem[12] = 32'hafbe000c;    // addr = 0x30
    mem[13] = 32'h03a0f025;    // addr = 0x34
    mem[14] = 32'hafc40010;    // addr = 0x38
    mem[15] = 32'hafc50014;    // addr = 0x3c
    mem[16] = 32'hafc60018;    // addr = 0x40
    mem[17] = 32'h8fc30010;    // addr = 0x44
    mem[18] = 32'h8fc20014;    // addr = 0x48
    mem[19] = 32'h0062102a;    // addr = 0x4c
    mem[20] = 32'h10400005;    // addr = 0x50
    mem[21] = 32'h00000000;    // addr = 0x54
    mem[22] = 32'h8fc20010;    // addr = 0x58
    mem[23] = 32'hafc20000;    // addr = 0x5c
    mem[24] = 32'h10000003;    // addr = 0x60
    mem[25] = 32'h00000000;    // addr = 0x64
    mem[26] = 32'h8fc20014;    // addr = 0x68
    mem[27] = 32'hafc20000;    // addr = 0x6c
    mem[28] = 32'h8fc30018;    // addr = 0x70
    mem[29] = 32'h8fc20000;    // addr = 0x74
    mem[30] = 32'h0062102a;    // addr = 0x78
    mem[31] = 32'h10400003;    // addr = 0x7c
    mem[32] = 32'h00000000;    // addr = 0x80
    mem[33] = 32'h8fc20018;    // addr = 0x84
    mem[34] = 32'hafc20000;    // addr = 0x88
    mem[35] = 32'h8fc20000;    // addr = 0x8c
    mem[36] = 32'h03c0e825;    // addr = 0x90
    mem[37] = 32'h8fbe000c;    // addr = 0x94
    mem[38] = 32'h27bd0010;    // addr = 0x98
    mem[39] = 32'h03e00008;    // addr = 0x9c
    mem[40] = 32'h00000000;    // addr = 0xa0
    mem[41] = 32'h27bdffd8;    // addr = 0xa4
    mem[42] = 32'hafbf0024;    // addr = 0xa8
    mem[43] = 32'hafbe0020;    // addr = 0xac
    mem[44] = 32'h03a0f025;    // addr = 0xb0
    mem[45] = 32'hafc0001c;    // addr = 0xb4
    mem[46] = 32'hafc00010;    // addr = 0xb8
    mem[47] = 32'h1000004f;    // addr = 0xbc
    mem[48] = 32'h00000000;    // addr = 0xc0
    mem[49] = 32'hafc00014;    // addr = 0xc4
    mem[50] = 32'h1000003c;    // addr = 0xc8
    mem[51] = 32'h00000000;    // addr = 0xcc
    mem[52] = 32'hafc00018;    // addr = 0xd0
    mem[53] = 32'h10000029;    // addr = 0xd4
    mem[54] = 32'h00000000;    // addr = 0xd8
    mem[55] = 32'h3c020000;    // addr = 0xdc
    mem[56] = 32'h8fc30010;    // addr = 0xe0
    mem[57] = 32'h00031880;    // addr = 0xe4
    mem[58] = 32'h24420268;    // addr = 0xe8
    mem[59] = 32'h00621021;    // addr = 0xec
    mem[60] = 32'h8c440000;    // addr = 0xf0
    mem[61] = 32'h3c020000;    // addr = 0xf4
    mem[62] = 32'h8fc30014;    // addr = 0xf8
    mem[63] = 32'h00031880;    // addr = 0xfc
    mem[64] = 32'h24420268;    // addr = 0x100
    mem[65] = 32'h00621021;    // addr = 0x104
    mem[66] = 32'h8c450000;    // addr = 0x108
    mem[67] = 32'h3c020000;    // addr = 0x10c
    mem[68] = 32'h8fc30018;    // addr = 0x110
    mem[69] = 32'h00031880;    // addr = 0x114
    mem[70] = 32'h24420268;    // addr = 0x118
    mem[71] = 32'h00621021;    // addr = 0x11c
    mem[72] = 32'h8c420000;    // addr = 0x120
    mem[73] = 32'h00403025;    // addr = 0x124
    mem[74] = 32'h0c00000b;    // addr = 0x128
    mem[75] = 32'h00000000;    // addr = 0x12c
    mem[76] = 32'h00402825;    // addr = 0x130
    mem[77] = 32'h8fc2001c;    // addr = 0x134
    mem[78] = 32'h24430001;    // addr = 0x138
    mem[79] = 32'hafc3001c;    // addr = 0x13c
    mem[80] = 32'h3c040000;    // addr = 0x140
    mem[81] = 32'h00021880;    // addr = 0x144
    mem[82] = 32'h24820278;    // addr = 0x148
    mem[83] = 32'h00621021;    // addr = 0x14c
    mem[84] = 32'h8c420000;    // addr = 0x150
    mem[85] = 32'h10a20006;    // addr = 0x154
    mem[86] = 32'h00000000;    // addr = 0x158
    mem[87] = 32'h3c020000;    // addr = 0x15c
    mem[88] = 32'h24030001;    // addr = 0x160
    mem[89] = 32'hac43000c;    // addr = 0x164
    mem[90] = 32'h08000009;    // addr = 0x168
    mem[91] = 32'h00000000;    // addr = 0x16c
    mem[92] = 32'h8fc20018;    // addr = 0x170
    mem[93] = 32'h24420001;    // addr = 0x174
    mem[94] = 32'hafc20018;    // addr = 0x178
    mem[95] = 32'h8fc20018;    // addr = 0x17c
    mem[96] = 32'h2c420004;    // addr = 0x180
    mem[97] = 32'h1440ffd5;    // addr = 0x184
    mem[98] = 32'h00000000;    // addr = 0x188
    mem[99] = 32'h8fc30018;    // addr = 0x18c
    mem[100] = 32'h24020004;    // addr = 0x190
    mem[101] = 32'h10620006;    // addr = 0x194
    mem[102] = 32'h00000000;    // addr = 0x198
    mem[103] = 32'h3c020000;    // addr = 0x19c
    mem[104] = 32'h24030001;    // addr = 0x1a0
    mem[105] = 32'hac43000c;    // addr = 0x1a4
    mem[106] = 32'h08000009;    // addr = 0x1a8
    mem[107] = 32'h00000000;    // addr = 0x1ac
    mem[108] = 32'h8fc20014;    // addr = 0x1b0
    mem[109] = 32'h24420001;    // addr = 0x1b4
    mem[110] = 32'hafc20014;    // addr = 0x1b8
    mem[111] = 32'h8fc20014;    // addr = 0x1bc
    mem[112] = 32'h2c420004;    // addr = 0x1c0
    mem[113] = 32'h1440ffc2;    // addr = 0x1c4
    mem[114] = 32'h00000000;    // addr = 0x1c8
    mem[115] = 32'h8fc30014;    // addr = 0x1cc
    mem[116] = 32'h24020004;    // addr = 0x1d0
    mem[117] = 32'h10620006;    // addr = 0x1d4
    mem[118] = 32'h00000000;    // addr = 0x1d8
    mem[119] = 32'h3c020000;    // addr = 0x1dc
    mem[120] = 32'h24030001;    // addr = 0x1e0
    mem[121] = 32'hac43000c;    // addr = 0x1e4
    mem[122] = 32'h08000009;    // addr = 0x1e8
    mem[123] = 32'h00000000;    // addr = 0x1ec
    mem[124] = 32'h8fc20010;    // addr = 0x1f0
    mem[125] = 32'h24420001;    // addr = 0x1f4
    mem[126] = 32'hafc20010;    // addr = 0x1f8
    mem[127] = 32'h8fc20010;    // addr = 0x1fc
    mem[128] = 32'h2c420004;    // addr = 0x200
    mem[129] = 32'h1440ffaf;    // addr = 0x204
    mem[130] = 32'h00000000;    // addr = 0x208
    mem[131] = 32'h8fc30010;    // addr = 0x20c
    mem[132] = 32'h24020004;    // addr = 0x210
    mem[133] = 32'h10620006;    // addr = 0x214
    mem[134] = 32'h00000000;    // addr = 0x218
    mem[135] = 32'h3c020000;    // addr = 0x21c
    mem[136] = 32'h24030001;    // addr = 0x220
    mem[137] = 32'hac43000c;    // addr = 0x224
    mem[138] = 32'h08000009;    // addr = 0x228
    mem[139] = 32'h00000000;    // addr = 0x22c
    mem[140] = 32'h00001025;    // addr = 0x230
    mem[141] = 32'h03c0e825;    // addr = 0x234
    mem[142] = 32'h8fbf0024;    // addr = 0x238
    mem[143] = 32'h8fbe0020;    // addr = 0x23c
    mem[144] = 32'h27bd0028;    // addr = 0x240
    mem[145] = 32'h03e00008;    // addr = 0x244
    mem[146] = 32'h00000000;    // addr = 0x248
    mem[147] = 32'h00000000;    // addr = 0x24c
    mem[148] = 32'h01200000;    // addr = 0x250
    mem[149] = 32'h01000101;    // addr = 0x254
    mem[150] = 32'h00000000;    // addr = 0x258
    mem[151] = 32'h00000000;    // addr = 0x25c
    mem[152] = 32'h00000001;    // addr = 0x260
    mem[153] = 32'h00000000;    // addr = 0x264
    mem[154] = 32'h00000000;    // addr = 0x268
    mem[155] = 32'h7fffffff;    // addr = 0x26c
    mem[156] = 32'h80000000;    // addr = 0x270
    mem[157] = 32'hffffffff;    // addr = 0x274
    mem[158] = 32'h00000000;    // addr = 0x278
    mem[159] = 32'h00000000;    // addr = 0x27c
    mem[160] = 32'h80000000;    // addr = 0x280
    mem[161] = 32'hffffffff;    // addr = 0x284
    mem[162] = 32'h00000000;    // addr = 0x288
    mem[163] = 32'h00000000;    // addr = 0x28c
    mem[164] = 32'h80000000;    // addr = 0x290
    mem[165] = 32'hffffffff;    // addr = 0x294
    mem[166] = 32'h80000000;    // addr = 0x298
    mem[167] = 32'h80000000;    // addr = 0x29c
    mem[168] = 32'h80000000;    // addr = 0x2a0
    mem[169] = 32'h80000000;    // addr = 0x2a4
    mem[170] = 32'hffffffff;    // addr = 0x2a8
    mem[171] = 32'hffffffff;    // addr = 0x2ac
    mem[172] = 32'h80000000;    // addr = 0x2b0
    mem[173] = 32'hffffffff;    // addr = 0x2b4
    mem[174] = 32'h00000000;    // addr = 0x2b8
    mem[175] = 32'h00000000;    // addr = 0x2bc
    mem[176] = 32'h80000000;    // addr = 0x2c0
    mem[177] = 32'hffffffff;    // addr = 0x2c4
    mem[178] = 32'h00000000;    // addr = 0x2c8
    mem[179] = 32'h7fffffff;    // addr = 0x2cc
    mem[180] = 32'h80000000;    // addr = 0x2d0
    mem[181] = 32'hffffffff;    // addr = 0x2d4
    mem[182] = 32'h80000000;    // addr = 0x2d8
    mem[183] = 32'h80000000;    // addr = 0x2dc
    mem[184] = 32'h80000000;    // addr = 0x2e0
    mem[185] = 32'h80000000;    // addr = 0x2e4
    mem[186] = 32'hffffffff;    // addr = 0x2e8
    mem[187] = 32'hffffffff;    // addr = 0x2ec
    mem[188] = 32'h80000000;    // addr = 0x2f0
    mem[189] = 32'hffffffff;    // addr = 0x2f4
    mem[190] = 32'h80000000;    // addr = 0x2f8
    mem[191] = 32'h80000000;    // addr = 0x2fc
    mem[192] = 32'h80000000;    // addr = 0x300
    mem[193] = 32'h80000000;    // addr = 0x304
    mem[194] = 32'h80000000;    // addr = 0x308
    mem[195] = 32'h80000000;    // addr = 0x30c
    mem[196] = 32'h80000000;    // addr = 0x310
    mem[197] = 32'h80000000;    // addr = 0x314
    mem[198] = 32'h80000000;    // addr = 0x318
    mem[199] = 32'h80000000;    // addr = 0x31c
    mem[200] = 32'h80000000;    // addr = 0x320
    mem[201] = 32'h80000000;    // addr = 0x324
    mem[202] = 32'h80000000;    // addr = 0x328
    mem[203] = 32'h80000000;    // addr = 0x32c
    mem[204] = 32'h80000000;    // addr = 0x330
    mem[205] = 32'h80000000;    // addr = 0x334
    mem[206] = 32'hffffffff;    // addr = 0x338
    mem[207] = 32'hffffffff;    // addr = 0x33c
    mem[208] = 32'h80000000;    // addr = 0x340
    mem[209] = 32'hffffffff;    // addr = 0x344
    mem[210] = 32'hffffffff;    // addr = 0x348
    mem[211] = 32'hffffffff;    // addr = 0x34c
    mem[212] = 32'h80000000;    // addr = 0x350
    mem[213] = 32'hffffffff;    // addr = 0x354
    mem[214] = 32'h80000000;    // addr = 0x358
    mem[215] = 32'h80000000;    // addr = 0x35c
    mem[216] = 32'h80000000;    // addr = 0x360
    mem[217] = 32'h80000000;    // addr = 0x364
    mem[218] = 32'hffffffff;    // addr = 0x368
    mem[219] = 32'hffffffff;    // addr = 0x36c
    mem[220] = 32'h80000000;    // addr = 0x370
    mem[221] = 32'hffffffff;    // addr = 0x374
    end
    
    //7.mov-c.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c00000b;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h3c040000;    // addr = 0x2c
    mem[12] = 32'h24820088;    // addr = 0x30
    mem[13] = 32'hac800088;    // addr = 0x34
    mem[14] = 32'h24040001;    // addr = 0x38
    mem[15] = 32'hac440004;    // addr = 0x3c
    mem[16] = 32'h24040002;    // addr = 0x40
    mem[17] = 32'hac440008;    // addr = 0x44
    mem[18] = 32'h24040004;    // addr = 0x48
    mem[19] = 32'h24030003;    // addr = 0x4c
    mem[20] = 32'hac440010;    // addr = 0x50
    mem[21] = 32'h3c040000;    // addr = 0x54
    mem[22] = 32'hac43000c;    // addr = 0x58
    mem[23] = 32'hac430014;    // addr = 0x5c
    mem[24] = 32'hac8300b0;    // addr = 0x60
    mem[25] = 32'h00001025;    // addr = 0x64
    mem[26] = 32'h03e00008;    // addr = 0x68
    mem[27] = 32'h00000000;    // addr = 0x6c
    mem[28] = 32'h01200000;    // addr = 0x70
    mem[29] = 32'h01000101;    // addr = 0x74
    mem[30] = 32'h00000000;    // addr = 0x78
    mem[31] = 32'h00000000;    // addr = 0x7c
    mem[32] = 32'h00000001;    // addr = 0x80
    mem[33] = 32'h00000000;    // addr = 0x84
    mem[34] = 32'h00000000;    // addr = 0x88
    mem[35] = 32'h00000000;    // addr = 0x8c
    mem[36] = 32'h00000000;    // addr = 0x90
    mem[37] = 32'h00000000;    // addr = 0x94
    mem[38] = 32'h00000000;    // addr = 0x98
    mem[39] = 32'h00000000;    // addr = 0x9c
    mem[40] = 32'h00000000;    // addr = 0xa0
    mem[41] = 32'h00000000;    // addr = 0xa4
    mem[42] = 32'h00000000;    // addr = 0xa8
    mem[43] = 32'h00000000;    // addr = 0xac
    mem[44] = 32'h00000000;    // addr = 0xb0
    end
    
    //8.pascal.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c00000b;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h3c020000;    // addr = 0x2c
    mem[12] = 32'h24030001;    // addr = 0x30
    mem[13] = 32'h244601a4;    // addr = 0x34
    mem[14] = 32'h3c050000;    // addr = 0x38
    mem[15] = 32'h3c080000;    // addr = 0x3c
    mem[16] = 32'h3c070000;    // addr = 0x40
    mem[17] = 32'hacc30004;    // addr = 0x44
    mem[18] = 32'hac4301a4;    // addr = 0x48
    mem[19] = 32'h24a501ac;    // addr = 0x4c
    mem[20] = 32'h25080220;    // addr = 0x50
    mem[21] = 32'h24040001;    // addr = 0x54
    mem[22] = 32'h24e701a8;    // addr = 0x58
    mem[23] = 32'h24090001;    // addr = 0x5c
    mem[24] = 32'h00e01025;    // addr = 0x60
    mem[25] = 32'h24030001;    // addr = 0x64
    mem[26] = 32'h10000002;    // addr = 0x68
    mem[27] = 32'h00000000;    // addr = 0x6c
    mem[28] = 32'h8c440000;    // addr = 0x70
    mem[29] = 32'h00831821;    // addr = 0x74
    mem[30] = 32'hac430000;    // addr = 0x78
    mem[31] = 32'h24420004;    // addr = 0x7c
    mem[32] = 32'h00801825;    // addr = 0x80
    mem[33] = 32'h1445fffa;    // addr = 0x84
    mem[34] = 32'h00000000;    // addr = 0x88
    mem[35] = 32'haca90000;    // addr = 0x8c
    mem[36] = 32'h24a50004;    // addr = 0x90
    mem[37] = 32'h10a80004;    // addr = 0x94
    mem[38] = 32'h00000000;    // addr = 0x98
    mem[39] = 32'h8cc40004;    // addr = 0x9c
    mem[40] = 32'h1000ffef;    // addr = 0xa0
    mem[41] = 32'h00000000;    // addr = 0xa4
    mem[42] = 32'h3c090000;    // addr = 0xa8
    mem[43] = 32'h3c030000;    // addr = 0xac
    mem[44] = 32'h8d27000c;    // addr = 0xb0
    mem[45] = 32'h00c01025;    // addr = 0xb4
    mem[46] = 32'h24630128;    // addr = 0xb8
    mem[47] = 32'h00004025;    // addr = 0xbc
    mem[48] = 32'h8c460000;    // addr = 0xc0
    mem[49] = 32'h8c640000;    // addr = 0xc4
    mem[50] = 32'h10c40005;    // addr = 0xc8
    mem[51] = 32'h00000000;    // addr = 0xcc
    mem[52] = 32'h08000009;    // addr = 0xd0
    mem[53] = 32'h00000000;    // addr = 0xd4
    mem[54] = 32'h24080001;    // addr = 0xd8
    mem[55] = 32'h24070001;    // addr = 0xdc
    mem[56] = 32'h24420004;    // addr = 0xe0
    mem[57] = 32'h24630004;    // addr = 0xe4
    mem[58] = 32'h1445fff5;    // addr = 0xe8
    mem[59] = 32'h00000000;    // addr = 0xec
    mem[60] = 32'h15000004;    // addr = 0xf0
    mem[61] = 32'h00000000;    // addr = 0xf4
    mem[62] = 32'h00001025;    // addr = 0xf8
    mem[63] = 32'h03e00008;    // addr = 0xfc
    mem[64] = 32'h00000000;    // addr = 0x100
    mem[65] = 32'had27000c;    // addr = 0x104
    mem[66] = 32'h1000fffb;    // addr = 0x108
    mem[67] = 32'h00000000;    // addr = 0x10c
    mem[68] = 32'h01200000;    // addr = 0x110
    mem[69] = 32'h01000101;    // addr = 0x114
    mem[70] = 32'h00000000;    // addr = 0x118
    mem[71] = 32'h00000000;    // addr = 0x11c
    mem[72] = 32'h00000001;    // addr = 0x120
    mem[73] = 32'h00000000;    // addr = 0x124
    mem[74] = 32'h00000001;    // addr = 0x128
    mem[75] = 32'h0000001e;    // addr = 0x12c
    mem[76] = 32'h000001b3;    // addr = 0x130
    mem[77] = 32'h00000fdc;    // addr = 0x134
    mem[78] = 32'h00006b0d;    // addr = 0x138
    mem[79] = 32'h00022caa;    // addr = 0x13c
    mem[80] = 32'h00090f6f;    // addr = 0x140
    mem[81] = 32'h001f1058;    // addr = 0x144
    mem[82] = 32'h00594efd;    // addr = 0x148
    mem[83] = 32'h00da4f4e;    // addr = 0x14c
    mem[84] = 32'h01ca7357;    // addr = 0x150
    mem[85] = 32'h03418be4;    // addr = 0x154
    mem[86] = 32'h0527c829;    // addr = 0x158
    mem[87] = 32'h072363ea;    // addr = 0x15c
    mem[88] = 32'h08aaf953;    // addr = 0x160
    mem[89] = 32'h093ee7d0;    // addr = 0x164
    mem[90] = 32'h08aaf953;    // addr = 0x168
    mem[91] = 32'h072363ea;    // addr = 0x16c
    mem[92] = 32'h0527c829;    // addr = 0x170
    mem[93] = 32'h03418be4;    // addr = 0x174
    mem[94] = 32'h01ca7357;    // addr = 0x178
    mem[95] = 32'h00da4f4e;    // addr = 0x17c
    mem[96] = 32'h00594efd;    // addr = 0x180
    mem[97] = 32'h001f1058;    // addr = 0x184
    mem[98] = 32'h00090f6f;    // addr = 0x188
    mem[99] = 32'h00022caa;    // addr = 0x18c
    mem[100] = 32'h00006b0d;    // addr = 0x190
    mem[101] = 32'h00000fdc;    // addr = 0x194
    mem[102] = 32'h000001b3;    // addr = 0x198
    mem[103] = 32'h0000001e;    // addr = 0x19c
    mem[104] = 32'h00000001;    // addr = 0x1a0
    mem[105] = 32'h00000000;    // addr = 0x1a4
    mem[106] = 32'h00000000;    // addr = 0x1a8
    mem[107] = 32'h00000000;    // addr = 0x1ac
    mem[108] = 32'h00000000;    // addr = 0x1b0
    mem[109] = 32'h00000000;    // addr = 0x1b4
    mem[110] = 32'h00000000;    // addr = 0x1b8
    mem[111] = 32'h00000000;    // addr = 0x1bc
    mem[112] = 32'h00000000;    // addr = 0x1c0
    mem[113] = 32'h00000000;    // addr = 0x1c4
    mem[114] = 32'h00000000;    // addr = 0x1c8
    mem[115] = 32'h00000000;    // addr = 0x1cc
    mem[116] = 32'h00000000;    // addr = 0x1d0
    mem[117] = 32'h00000000;    // addr = 0x1d4
    mem[118] = 32'h00000000;    // addr = 0x1d8
    mem[119] = 32'h00000000;    // addr = 0x1dc
    mem[120] = 32'h00000000;    // addr = 0x1e0
    mem[121] = 32'h00000000;    // addr = 0x1e4
    mem[122] = 32'h00000000;    // addr = 0x1e8
    mem[123] = 32'h00000000;    // addr = 0x1ec
    mem[124] = 32'h00000000;    // addr = 0x1f0
    mem[125] = 32'h00000000;    // addr = 0x1f4
    mem[126] = 32'h00000000;    // addr = 0x1f8
    mem[127] = 32'h00000000;    // addr = 0x1fc
    mem[128] = 32'h00000000;    // addr = 0x200
    mem[129] = 32'h00000000;    // addr = 0x204
    mem[130] = 32'h00000000;    // addr = 0x208
    mem[131] = 32'h00000000;    // addr = 0x20c
    mem[132] = 32'h00000000;    // addr = 0x210
    mem[133] = 32'h00000000;    // addr = 0x214
    mem[134] = 32'h00000000;    // addr = 0x218
    mem[135] = 32'h00000000;    // addr = 0x21c
    end
    
    //9.quick-sort.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c00006b;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h00053880;    // addr = 0x2c
    mem[12] = 32'h00873821;    // addr = 0x30
    mem[13] = 32'h00a6102a;    // addr = 0x34
    mem[14] = 32'h8ce90000;    // addr = 0x38
    mem[15] = 32'h10400038;    // addr = 0x3c
    mem[16] = 32'h00000000;    // addr = 0x40
    mem[17] = 32'h00064080;    // addr = 0x44
    mem[18] = 32'h00881021;    // addr = 0x48
    mem[19] = 32'h8c430000;    // addr = 0x4c
    mem[20] = 32'h00a01025;    // addr = 0x50
    mem[21] = 32'h0123282a;    // addr = 0x54
    mem[22] = 32'h00883821;    // addr = 0x58
    mem[23] = 32'h10000003;    // addr = 0x5c
    mem[24] = 32'h00000000;    // addr = 0x60
    mem[25] = 32'h8ce30000;    // addr = 0x64
    mem[26] = 32'h0123282a;    // addr = 0x68
    mem[27] = 32'h10a00010;    // addr = 0x6c
    mem[28] = 32'h00000000;    // addr = 0x70
    mem[29] = 32'h24c6ffff;    // addr = 0x74
    mem[30] = 32'h0046182a;    // addr = 0x78
    mem[31] = 32'h24e7fffc;    // addr = 0x7c
    mem[32] = 32'h1460fff8;    // addr = 0x80
    mem[33] = 32'h00000000;    // addr = 0x84
    mem[34] = 32'h00063080;    // addr = 0x88
    mem[35] = 32'h00865021;    // addr = 0x8c
    mem[36] = 32'h00023880;    // addr = 0x90
    mem[37] = 32'h8d430000;    // addr = 0x94
    mem[38] = 32'h00873821;    // addr = 0x98
    mem[39] = 32'hace30000;    // addr = 0x9c
    mem[40] = 32'had430000;    // addr = 0xa0
    mem[41] = 32'hace90000;    // addr = 0xa4
    mem[42] = 32'h03e00008;    // addr = 0xa8
    mem[43] = 32'h00000000;    // addr = 0xac
    mem[44] = 32'h00023880;    // addr = 0xb0
    mem[45] = 32'h00064080;    // addr = 0xb4
    mem[46] = 32'h00873821;    // addr = 0xb8
    mem[47] = 32'h0046282a;    // addr = 0xbc
    mem[48] = 32'h00885021;    // addr = 0xc0
    mem[49] = 32'hace30000;    // addr = 0xc4
    mem[50] = 32'h14a00007;    // addr = 0xc8
    mem[51] = 32'h00000000;    // addr = 0xcc
    mem[52] = 32'h1000fff3;    // addr = 0xd0
    mem[53] = 32'h00000000;    // addr = 0xd4
    mem[54] = 32'h8ce30000;    // addr = 0xd8
    mem[55] = 32'h0123282a;    // addr = 0xdc
    mem[56] = 32'h14a0000c;    // addr = 0xe0
    mem[57] = 32'h00000000;    // addr = 0xe4
    mem[58] = 32'h24420001;    // addr = 0xe8
    mem[59] = 32'h24e70004;    // addr = 0xec
    mem[60] = 32'h1446fff9;    // addr = 0xf0
    mem[61] = 32'h00000000;    // addr = 0xf4
    mem[62] = 32'h00023880;    // addr = 0xf8
    mem[63] = 32'h00873821;    // addr = 0xfc
    mem[64] = 32'h8ce30000;    // addr = 0x100
    mem[65] = 32'had430000;    // addr = 0x104
    mem[66] = 32'hace90000;    // addr = 0x108
    mem[67] = 32'h03e00008;    // addr = 0x10c
    mem[68] = 32'h00000000;    // addr = 0x110
    mem[69] = 32'had430000;    // addr = 0x114
    mem[70] = 32'h1000ffcf;    // addr = 0x118
    mem[71] = 32'h00000000;    // addr = 0x11c
    mem[72] = 32'h00a01025;    // addr = 0x120
    mem[73] = 32'h1000ffdf;    // addr = 0x124
    mem[74] = 32'h00000000;    // addr = 0x128
    mem[75] = 32'h00a6102a;    // addr = 0x12c
    mem[76] = 32'h1040001c;    // addr = 0x130
    mem[77] = 32'h00000000;    // addr = 0x134
    mem[78] = 32'h27bdffe0;    // addr = 0x138
    mem[79] = 32'hafb20018;    // addr = 0x13c
    mem[80] = 32'hafb10014;    // addr = 0x140
    mem[81] = 32'hafb00010;    // addr = 0x144
    mem[82] = 32'hafbf001c;    // addr = 0x148
    mem[83] = 32'h00a08025;    // addr = 0x14c
    mem[84] = 32'h00c08825;    // addr = 0x150
    mem[85] = 32'h00809025;    // addr = 0x154
    mem[86] = 32'h02002825;    // addr = 0x158
    mem[87] = 32'h02203025;    // addr = 0x15c
    mem[88] = 32'h02402025;    // addr = 0x160
    mem[89] = 32'h0c00000b;    // addr = 0x164
    mem[90] = 32'h00000000;    // addr = 0x168
    mem[91] = 32'h2446ffff;    // addr = 0x16c
    mem[92] = 32'h02002825;    // addr = 0x170
    mem[93] = 32'h02402025;    // addr = 0x174
    mem[94] = 32'h24500001;    // addr = 0x178
    mem[95] = 32'h0c00004b;    // addr = 0x17c
    mem[96] = 32'h00000000;    // addr = 0x180
    mem[97] = 32'h0211102a;    // addr = 0x184
    mem[98] = 32'h1440fff3;    // addr = 0x188
    mem[99] = 32'h00000000;    // addr = 0x18c
    mem[100] = 32'h8fbf001c;    // addr = 0x190
    mem[101] = 32'h8fb20018;    // addr = 0x194
    mem[102] = 32'h8fb10014;    // addr = 0x198
    mem[103] = 32'h8fb00010;    // addr = 0x19c
    mem[104] = 32'h27bd0020;    // addr = 0x1a0
    mem[105] = 32'h03e00008;    // addr = 0x1a4
    mem[106] = 32'h00000000;    // addr = 0x1a8
    mem[107] = 32'h3c0c0000;    // addr = 0x1ac
    mem[108] = 32'h27bdffe8;    // addr = 0x1b0
    mem[109] = 32'h24060013;    // addr = 0x1b4
    mem[110] = 32'h00002825;    // addr = 0x1b8
    mem[111] = 32'h258402b8;    // addr = 0x1bc
    mem[112] = 32'hafbf0014;    // addr = 0x1c0
    mem[113] = 32'h0c00004b;    // addr = 0x1c4
    mem[114] = 32'h00000000;    // addr = 0x1c8
    mem[115] = 32'h3c0d0000;    // addr = 0x1cc
    mem[116] = 32'h258b02b8;    // addr = 0x1d0
    mem[117] = 32'h8da7000c;    // addr = 0x1d4
    mem[118] = 32'h01601825;    // addr = 0x1d8
    mem[119] = 32'h00003025;    // addr = 0x1dc
    mem[120] = 32'h00001025;    // addr = 0x1e0
    mem[121] = 32'h24050014;    // addr = 0x1e4
    mem[122] = 32'h8c640000;    // addr = 0x1e8
    mem[123] = 32'h10820005;    // addr = 0x1ec
    mem[124] = 32'h00000000;    // addr = 0x1f0
    mem[125] = 32'h08000009;    // addr = 0x1f4
    mem[126] = 32'h00000000;    // addr = 0x1f8
    mem[127] = 32'h24060001;    // addr = 0x1fc
    mem[128] = 32'h24070001;    // addr = 0x200
    mem[129] = 32'h24420001;    // addr = 0x204
    mem[130] = 32'h24630004;    // addr = 0x208
    mem[131] = 32'h1445fff6;    // addr = 0x20c
    mem[132] = 32'h00000000;    // addr = 0x210
    mem[133] = 32'h14c0001c;    // addr = 0x214
    mem[134] = 32'h00000000;    // addr = 0x218
    mem[135] = 32'h24060013;    // addr = 0x21c
    mem[136] = 32'h00002825;    // addr = 0x220
    mem[137] = 32'h258402b8;    // addr = 0x224
    mem[138] = 32'h0c00004b;    // addr = 0x228
    mem[139] = 32'h00000000;    // addr = 0x22c
    mem[140] = 32'h8da6000c;    // addr = 0x230
    mem[141] = 32'h00002825;    // addr = 0x234
    mem[142] = 32'h00001025;    // addr = 0x238
    mem[143] = 32'h24040014;    // addr = 0x23c
    mem[144] = 32'h8d630000;    // addr = 0x240
    mem[145] = 32'h10620005;    // addr = 0x244
    mem[146] = 32'h00000000;    // addr = 0x248
    mem[147] = 32'h08000009;    // addr = 0x24c
    mem[148] = 32'h00000000;    // addr = 0x250
    mem[149] = 32'h24050001;    // addr = 0x254
    mem[150] = 32'h24060001;    // addr = 0x258
    mem[151] = 32'h24420001;    // addr = 0x25c
    mem[152] = 32'h256b0004;    // addr = 0x260
    mem[153] = 32'h1444fff6;    // addr = 0x264
    mem[154] = 32'h00000000;    // addr = 0x268
    mem[155] = 32'h14a00009;    // addr = 0x26c
    mem[156] = 32'h00000000;    // addr = 0x270
    mem[157] = 32'h8fbf0014;    // addr = 0x274
    mem[158] = 32'h00001025;    // addr = 0x278
    mem[159] = 32'h27bd0018;    // addr = 0x27c
    mem[160] = 32'h03e00008;    // addr = 0x280
    mem[161] = 32'h00000000;    // addr = 0x284
    mem[162] = 32'hada7000c;    // addr = 0x288
    mem[163] = 32'h1000ffe3;    // addr = 0x28c
    mem[164] = 32'h00000000;    // addr = 0x290
    mem[165] = 32'hada6000c;    // addr = 0x294
    mem[166] = 32'h1000fff6;    // addr = 0x298
    mem[167] = 32'h00000000;    // addr = 0x29c
    mem[168] = 32'h01200000;    // addr = 0x2a0
    mem[169] = 32'h01000101;    // addr = 0x2a4
    mem[170] = 32'h00000000;    // addr = 0x2a8
    mem[171] = 32'h00000000;    // addr = 0x2ac
    mem[172] = 32'h00000001;    // addr = 0x2b0
    mem[173] = 32'h00000000;    // addr = 0x2b4
    mem[174] = 32'h00000002;    // addr = 0x2b8
    mem[175] = 32'h0000000c;    // addr = 0x2bc
    mem[176] = 32'h0000000e;    // addr = 0x2c0
    mem[177] = 32'h00000006;    // addr = 0x2c4
    mem[178] = 32'h0000000d;    // addr = 0x2c8
    mem[179] = 32'h0000000f;    // addr = 0x2cc
    mem[180] = 32'h00000010;    // addr = 0x2d0
    mem[181] = 32'h0000000a;    // addr = 0x2d4
    mem[182] = 32'h00000000;    // addr = 0x2d8
    mem[183] = 32'h00000012;    // addr = 0x2dc
    mem[184] = 32'h0000000b;    // addr = 0x2e0
    mem[185] = 32'h00000013;    // addr = 0x2e4
    mem[186] = 32'h00000009;    // addr = 0x2e8
    mem[187] = 32'h00000001;    // addr = 0x2ec
    mem[188] = 32'h00000007;    // addr = 0x2f0
    mem[189] = 32'h00000005;    // addr = 0x2f4
    mem[190] = 32'h00000004;    // addr = 0x2f8
    mem[191] = 32'h00000003;    // addr = 0x2fc
    mem[192] = 32'h00000008;    // addr = 0x300
    mem[193] = 32'h00000011;    // addr = 0x304
    end
    
    //10.select-sort.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c000057;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h27bdffe8;    // addr = 0x2c
    mem[12] = 32'hafbe0014;    // addr = 0x30
    mem[13] = 32'h03a0f025;    // addr = 0x34
    mem[14] = 32'hafc00000;    // addr = 0x38
    mem[15] = 32'h1000003d;    // addr = 0x3c
    mem[16] = 32'h00000000;    // addr = 0x40
    mem[17] = 32'h8fc20000;    // addr = 0x44
    mem[18] = 32'hafc20008;    // addr = 0x48
    mem[19] = 32'h8fc20000;    // addr = 0x4c
    mem[20] = 32'h24420001;    // addr = 0x50
    mem[21] = 32'hafc20004;    // addr = 0x54
    mem[22] = 32'h10000015;    // addr = 0x58
    mem[23] = 32'h00000000;    // addr = 0x5c
    mem[24] = 32'h3c020000;    // addr = 0x60
    mem[25] = 32'h8fc30004;    // addr = 0x64
    mem[26] = 32'h00031880;    // addr = 0x68
    mem[27] = 32'h244202b8;    // addr = 0x6c
    mem[28] = 32'h00621021;    // addr = 0x70
    mem[29] = 32'h8c430000;    // addr = 0x74
    mem[30] = 32'h3c020000;    // addr = 0x78
    mem[31] = 32'h8fc40008;    // addr = 0x7c
    mem[32] = 32'h00042080;    // addr = 0x80
    mem[33] = 32'h244202b8;    // addr = 0x84
    mem[34] = 32'h00821021;    // addr = 0x88
    mem[35] = 32'h8c420000;    // addr = 0x8c
    mem[36] = 32'h0062102a;    // addr = 0x90
    mem[37] = 32'h10400003;    // addr = 0x94
    mem[38] = 32'h00000000;    // addr = 0x98
    mem[39] = 32'h8fc20004;    // addr = 0x9c
    mem[40] = 32'hafc20008;    // addr = 0xa0
    mem[41] = 32'h8fc20004;    // addr = 0xa4
    mem[42] = 32'h24420001;    // addr = 0xa8
    mem[43] = 32'hafc20004;    // addr = 0xac
    mem[44] = 32'h8fc20004;    // addr = 0xb0
    mem[45] = 32'h28420014;    // addr = 0xb4
    mem[46] = 32'h1440ffe9;    // addr = 0xb8
    mem[47] = 32'h00000000;    // addr = 0xbc
    mem[48] = 32'h3c020000;    // addr = 0xc0
    mem[49] = 32'h8fc30000;    // addr = 0xc4
    mem[50] = 32'h00031880;    // addr = 0xc8
    mem[51] = 32'h244202b8;    // addr = 0xcc
    mem[52] = 32'h00621021;    // addr = 0xd0
    mem[53] = 32'h8c420000;    // addr = 0xd4
    mem[54] = 32'hafc2000c;    // addr = 0xd8
    mem[55] = 32'h3c020000;    // addr = 0xdc
    mem[56] = 32'h8fc30008;    // addr = 0xe0
    mem[57] = 32'h00031880;    // addr = 0xe4
    mem[58] = 32'h244202b8;    // addr = 0xe8
    mem[59] = 32'h00621021;    // addr = 0xec
    mem[60] = 32'h8c430000;    // addr = 0xf0
    mem[61] = 32'h3c020000;    // addr = 0xf4
    mem[62] = 32'h8fc40000;    // addr = 0xf8
    mem[63] = 32'h00042080;    // addr = 0xfc
    mem[64] = 32'h244202b8;    // addr = 0x100
    mem[65] = 32'h00821021;    // addr = 0x104
    mem[66] = 32'hac430000;    // addr = 0x108
    mem[67] = 32'h3c020000;    // addr = 0x10c
    mem[68] = 32'h8fc30008;    // addr = 0x110
    mem[69] = 32'h00031880;    // addr = 0x114
    mem[70] = 32'h244202b8;    // addr = 0x118
    mem[71] = 32'h00621021;    // addr = 0x11c
    mem[72] = 32'h8fc3000c;    // addr = 0x120
    mem[73] = 32'hac430000;    // addr = 0x124
    mem[74] = 32'h8fc20000;    // addr = 0x128
    mem[75] = 32'h24420001;    // addr = 0x12c
    mem[76] = 32'hafc20000;    // addr = 0x130
    mem[77] = 32'h8fc20000;    // addr = 0x134
    mem[78] = 32'h28420013;    // addr = 0x138
    mem[79] = 32'h1440ffc1;    // addr = 0x13c
    mem[80] = 32'h00000000;    // addr = 0x140
    mem[81] = 32'h00000000;    // addr = 0x144
    mem[82] = 32'h03c0e825;    // addr = 0x148
    mem[83] = 32'h8fbe0014;    // addr = 0x14c
    mem[84] = 32'h27bd0018;    // addr = 0x150
    mem[85] = 32'h03e00008;    // addr = 0x154
    mem[86] = 32'h00000000;    // addr = 0x158
    mem[87] = 32'h27bdffe0;    // addr = 0x15c
    mem[88] = 32'hafbf001c;    // addr = 0x160
    mem[89] = 32'hafbe0018;    // addr = 0x164
    mem[90] = 32'h03a0f025;    // addr = 0x168
    mem[91] = 32'h0c00000b;    // addr = 0x16c
    mem[92] = 32'h00000000;    // addr = 0x170
    mem[93] = 32'hafc00010;    // addr = 0x174
    mem[94] = 32'h10000012;    // addr = 0x178
    mem[95] = 32'h00000000;    // addr = 0x17c
    mem[96] = 32'h3c020000;    // addr = 0x180
    mem[97] = 32'h8fc30010;    // addr = 0x184
    mem[98] = 32'h00031880;    // addr = 0x188
    mem[99] = 32'h244202b8;    // addr = 0x18c
    mem[100] = 32'h00621021;    // addr = 0x190
    mem[101] = 32'h8c430000;    // addr = 0x194
    mem[102] = 32'h8fc20010;    // addr = 0x198
    mem[103] = 32'h10620006;    // addr = 0x19c
    mem[104] = 32'h00000000;    // addr = 0x1a0
    mem[105] = 32'h3c020000;    // addr = 0x1a4
    mem[106] = 32'h24030001;    // addr = 0x1a8
    mem[107] = 32'hac43000c;    // addr = 0x1ac
    mem[108] = 32'h08000009;    // addr = 0x1b0
    mem[109] = 32'h00000000;    // addr = 0x1b4
    mem[110] = 32'h8fc20010;    // addr = 0x1b8
    mem[111] = 32'h24420001;    // addr = 0x1bc
    mem[112] = 32'hafc20010;    // addr = 0x1c0
    mem[113] = 32'h8fc20010;    // addr = 0x1c4
    mem[114] = 32'h28420014;    // addr = 0x1c8
    mem[115] = 32'h1440ffec;    // addr = 0x1cc
    mem[116] = 32'h00000000;    // addr = 0x1d0
    mem[117] = 32'h8fc30010;    // addr = 0x1d4
    mem[118] = 32'h24020014;    // addr = 0x1d8
    mem[119] = 32'h10620006;    // addr = 0x1dc
    mem[120] = 32'h00000000;    // addr = 0x1e0
    mem[121] = 32'h3c020000;    // addr = 0x1e4
    mem[122] = 32'h24030001;    // addr = 0x1e8
    mem[123] = 32'hac43000c;    // addr = 0x1ec
    mem[124] = 32'h08000009;    // addr = 0x1f0
    mem[125] = 32'h00000000;    // addr = 0x1f4
    mem[126] = 32'h0c00000b;    // addr = 0x1f8
    mem[127] = 32'h00000000;    // addr = 0x1fc
    mem[128] = 32'hafc00010;    // addr = 0x200
    mem[129] = 32'h10000012;    // addr = 0x204
    mem[130] = 32'h00000000;    // addr = 0x208
    mem[131] = 32'h3c020000;    // addr = 0x20c
    mem[132] = 32'h8fc30010;    // addr = 0x210
    mem[133] = 32'h00031880;    // addr = 0x214
    mem[134] = 32'h244202b8;    // addr = 0x218
    mem[135] = 32'h00621021;    // addr = 0x21c
    mem[136] = 32'h8c430000;    // addr = 0x220
    mem[137] = 32'h8fc20010;    // addr = 0x224
    mem[138] = 32'h10620006;    // addr = 0x228
    mem[139] = 32'h00000000;    // addr = 0x22c
    mem[140] = 32'h3c020000;    // addr = 0x230
    mem[141] = 32'h24030001;    // addr = 0x234
    mem[142] = 32'hac43000c;    // addr = 0x238
    mem[143] = 32'h08000009;    // addr = 0x23c
    mem[144] = 32'h00000000;    // addr = 0x240
    mem[145] = 32'h8fc20010;    // addr = 0x244
    mem[146] = 32'h24420001;    // addr = 0x248
    mem[147] = 32'hafc20010;    // addr = 0x24c
    mem[148] = 32'h8fc20010;    // addr = 0x250
    mem[149] = 32'h28420014;    // addr = 0x254
    mem[150] = 32'h1440ffec;    // addr = 0x258
    mem[151] = 32'h00000000;    // addr = 0x25c
    mem[152] = 32'h8fc30010;    // addr = 0x260
    mem[153] = 32'h24020014;    // addr = 0x264
    mem[154] = 32'h10620006;    // addr = 0x268
    mem[155] = 32'h00000000;    // addr = 0x26c
    mem[156] = 32'h3c020000;    // addr = 0x270
    mem[157] = 32'h24030001;    // addr = 0x274
    mem[158] = 32'hac43000c;    // addr = 0x278
    mem[159] = 32'h08000009;    // addr = 0x27c
    mem[160] = 32'h00000000;    // addr = 0x280
    mem[161] = 32'h00001025;    // addr = 0x284
    mem[162] = 32'h03c0e825;    // addr = 0x288
    mem[163] = 32'h8fbf001c;    // addr = 0x28c
    mem[164] = 32'h8fbe0018;    // addr = 0x290
    mem[165] = 32'h27bd0020;    // addr = 0x294
    mem[166] = 32'h03e00008;    // addr = 0x298
    mem[167] = 32'h00000000;    // addr = 0x29c
    mem[168] = 32'h01200000;    // addr = 0x2a0
    mem[169] = 32'h01000101;    // addr = 0x2a4
    mem[170] = 32'h00000000;    // addr = 0x2a8
    mem[171] = 32'h00000000;    // addr = 0x2ac
    mem[172] = 32'h00000001;    // addr = 0x2b0
    mem[173] = 32'h00000000;    // addr = 0x2b4
    mem[174] = 32'h00000002;    // addr = 0x2b8
    mem[175] = 32'h0000000c;    // addr = 0x2bc
    mem[176] = 32'h0000000e;    // addr = 0x2c0
    mem[177] = 32'h00000006;    // addr = 0x2c4
    mem[178] = 32'h0000000d;    // addr = 0x2c8
    mem[179] = 32'h0000000f;    // addr = 0x2cc
    mem[180] = 32'h00000010;    // addr = 0x2d0
    mem[181] = 32'h0000000a;    // addr = 0x2d4
    mem[182] = 32'h00000000;    // addr = 0x2d8
    mem[183] = 32'h00000012;    // addr = 0x2dc
    mem[184] = 32'h0000000b;    // addr = 0x2e0
    mem[185] = 32'h00000013;    // addr = 0x2e4
    mem[186] = 32'h00000009;    // addr = 0x2e8
    mem[187] = 32'h00000001;    // addr = 0x2ec
    mem[188] = 32'h00000007;    // addr = 0x2f0
    mem[189] = 32'h00000005;    // addr = 0x2f4
    mem[190] = 32'h00000004;    // addr = 0x2f8
    mem[191] = 32'h00000003;    // addr = 0x2fc
    mem[192] = 32'h00000008;    // addr = 0x300
    mem[193] = 32'h00000011;    // addr = 0x304
    end
    
    //11. sum.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c00000b;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h27bdfff8;    // addr = 0x2c
    mem[12] = 32'h24020001;    // addr = 0x30
    mem[13] = 32'h24040065;    // addr = 0x34
    mem[14] = 32'hafa00000;    // addr = 0x38
    mem[15] = 32'h8fa30000;    // addr = 0x3c
    mem[16] = 32'h00621821;    // addr = 0x40
    mem[17] = 32'h24420001;    // addr = 0x44
    mem[18] = 32'hafa30000;    // addr = 0x48
    mem[19] = 32'h1444fffb;    // addr = 0x4c
    mem[20] = 32'h00000000;    // addr = 0x50
    mem[21] = 32'h8fa30000;    // addr = 0x54
    mem[22] = 32'h240213ba;    // addr = 0x58
    mem[23] = 32'h10620006;    // addr = 0x5c
    mem[24] = 32'h00000000;    // addr = 0x60
    mem[25] = 32'h24030001;    // addr = 0x64
    mem[26] = 32'h3c020000;    // addr = 0x68
    mem[27] = 32'hac43000c;    // addr = 0x6c
    mem[28] = 32'h08000009;    // addr = 0x70
    mem[29] = 32'h00000000;    // addr = 0x74
    mem[30] = 32'h00001025;    // addr = 0x78
    mem[31] = 32'h27bd0008;    // addr = 0x7c
    mem[32] = 32'h03e00008;    // addr = 0x80
    mem[33] = 32'h00000000;    // addr = 0x84
    mem[34] = 32'h01200000;    // addr = 0x88
    mem[35] = 32'h01000101;    // addr = 0x8c
    mem[36] = 32'h00000000;    // addr = 0x90
    mem[37] = 32'h00000000;    // addr = 0x94
    mem[38] = 32'h00000001;    // addr = 0x98
    mem[39] = 32'h00000000;    // addr = 0x9c
    end
    
    //12. switch.vh success
    wait(mem[3] == 0)
	begin
	#WaitTime;
	TestNumber = TestNumber+1;
	
    mem[0] = 32'h00000000;	// addr = 0x0
    mem[1] = 32'h08000004;    // addr = 0x4
    mem[2] = 32'h00000000;    // addr = 0x8
    mem[3] = 32'hffffffff;    // addr = 0xc
    mem[4] = 32'h241d0400;    // addr = 0x10
    mem[5] = 32'h0c000018;    // addr = 0x14
    mem[6] = 32'h00000000;    // addr = 0x18
    mem[7] = 32'h3c010000;    // addr = 0x1c
    mem[8] = 32'hac20000c;    // addr = 0x20
    mem[9] = 32'h08000009;    // addr = 0x24
    mem[10] = 32'h00000000;    // addr = 0x28
    mem[11] = 32'h2c82000d;    // addr = 0x2c
    mem[12] = 32'h10400008;    // addr = 0x30
    mem[13] = 32'h00000000;    // addr = 0x34
    mem[14] = 32'h3c020000;    // addr = 0x38
    mem[15] = 32'h24420118;    // addr = 0x3c
    mem[16] = 32'h00042080;    // addr = 0x40
    mem[17] = 32'h00822021;    // addr = 0x44
    mem[18] = 32'h8c820000;    // addr = 0x48
    mem[19] = 32'h03e00008;    // addr = 0x4c
    mem[20] = 32'h00000000;    // addr = 0x50
    mem[21] = 32'h2402ffff;    // addr = 0x54
    mem[22] = 32'h03e00008;    // addr = 0x58
    mem[23] = 32'h00000000;    // addr = 0x5c
    mem[24] = 32'h3c0a0000;    // addr = 0x60
    mem[25] = 32'h3c020000;    // addr = 0x64
    mem[26] = 32'h3c040000;    // addr = 0x68
    mem[27] = 32'h3c070000;    // addr = 0x6c
    mem[28] = 32'h8d49000c;    // addr = 0x70
    mem[29] = 32'h2442014c;    // addr = 0x74
    mem[30] = 32'h24840118;    // addr = 0x78
    mem[31] = 32'h24e70184;    // addr = 0x7c
    mem[32] = 32'h00001825;    // addr = 0x80
    mem[33] = 32'h00004025;    // addr = 0x84
    mem[34] = 32'h2405ffff;    // addr = 0x88
    mem[35] = 32'h10000007;    // addr = 0x8c
    mem[36] = 32'h00000000;    // addr = 0x90
    mem[37] = 32'h2405ffff;    // addr = 0x94
    mem[38] = 32'h14c00013;    // addr = 0x98
    mem[39] = 32'h00000000;    // addr = 0x9c
    mem[40] = 32'h24630001;    // addr = 0xa0
    mem[41] = 32'h24420004;    // addr = 0xa4
    mem[42] = 32'h24840004;    // addr = 0xa8
    mem[43] = 32'h8c460000;    // addr = 0xac
    mem[44] = 32'h10c50005;    // addr = 0xb0
    mem[45] = 32'h00000000;    // addr = 0xb4
    mem[46] = 32'h08000009;    // addr = 0xb8
    mem[47] = 32'h00000000;    // addr = 0xbc
    mem[48] = 32'h24080001;    // addr = 0xc0
    mem[49] = 32'h24090001;    // addr = 0xc4
    mem[50] = 32'h2c66000d;    // addr = 0xc8
    mem[51] = 32'h1447fff1;    // addr = 0xcc
    mem[52] = 32'h00000000;    // addr = 0xd0
    mem[53] = 32'h15000007;    // addr = 0xd4
    mem[54] = 32'h00000000;    // addr = 0xd8
    mem[55] = 32'h00001025;    // addr = 0xdc
    mem[56] = 32'h03e00008;    // addr = 0xe0
    mem[57] = 32'h00000000;    // addr = 0xe4
    mem[58] = 32'h8c850000;    // addr = 0xe8
    mem[59] = 32'h1000ffec;    // addr = 0xec
    mem[60] = 32'h00000000;    // addr = 0xf0
    mem[61] = 32'had49000c;    // addr = 0xf4
    mem[62] = 32'h1000fff8;    // addr = 0xf8
    mem[63] = 32'h00000000;    // addr = 0xfc
    mem[64] = 32'h01200000;    // addr = 0x100
    mem[65] = 32'h01000101;    // addr = 0x104
    mem[66] = 32'h00000000;    // addr = 0x108
    mem[67] = 32'h00000000;    // addr = 0x10c
    mem[68] = 32'h00000001;    // addr = 0x110
    mem[69] = 32'h00000000;    // addr = 0x114
    mem[70] = 32'h00000000;    // addr = 0x118
    mem[71] = 32'h00000002;    // addr = 0x11c
    mem[72] = 32'h00000005;    // addr = 0x120
    mem[73] = 32'h00000005;    // addr = 0x124
    mem[74] = 32'h00000008;    // addr = 0x128
    mem[75] = 32'h00000008;    // addr = 0x12c
    mem[76] = 32'h00000008;    // addr = 0x130
    mem[77] = 32'h00000008;    // addr = 0x134
    mem[78] = 32'h0000000a;    // addr = 0x138
    mem[79] = 32'h0000000a;    // addr = 0x13c
    mem[80] = 32'h0000000a;    // addr = 0x140
    mem[81] = 32'h0000000a;    // addr = 0x144
    mem[82] = 32'h0000000f;    // addr = 0x148
    mem[83] = 32'hffffffff;    // addr = 0x14c
    mem[84] = 32'h00000000;    // addr = 0x150
    mem[85] = 32'h00000002;    // addr = 0x154
    mem[86] = 32'h00000005;    // addr = 0x158
    mem[87] = 32'h00000005;    // addr = 0x15c
    mem[88] = 32'h00000008;    // addr = 0x160
    mem[89] = 32'h00000008;    // addr = 0x164
    mem[90] = 32'h00000008;    // addr = 0x168
    mem[91] = 32'h00000008;    // addr = 0x16c
    mem[92] = 32'h0000000a;    // addr = 0x170
    mem[93] = 32'h0000000a;    // addr = 0x174
    mem[94] = 32'h0000000a;    // addr = 0x178
    mem[95] = 32'h0000000a;    // addr = 0x17c
    mem[96] = 32'h0000000f;    // addr = 0x180
    mem[97] = 32'hffffffff;    // addr = 0x184
    end

    //congratulation : all succee !!!!!!!!!!!!!
    
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
