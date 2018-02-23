`timescale 10ns / 1ns

module mips_cpu_test
();

	reg				mips_cpu_clk;
    reg				mips_cpu_reset;

    wire            mips_cpu_pc_sig;
    wire [7:0]      mips_cpu_perf_sig;

    //对位拼接语法的测试
    
    wire[10:0] test1,test2,test3,test4;
    assign test1 = {13-2{1}};
    assign test2 = {(13-2){1}};
    assign test3 = {13-2{1'b1}};
    assign test4 = {(13-2){1'b1}};
    
    
	initial begin
		mips_cpu_clk = 1'b0;
		mips_cpu_reset = 1'b1;
		# 3
		mips_cpu_reset = 1'b0;

/*
        //loader异常的模拟
        wait(u_mips_cpu.u_ideal_mem.mem[3] === 0)
        mips_cpu_reset = 1'b1;
        # 3
        mips_cpu_reset = 1'b0;
   */   
   
       $display("test1   : %b",test1);
       $display("test2   : %b",test2);
       $display("test3   : %b",test3);
       $display("test4   : %b",test4);
       $display("13-2'b11: %11b",13-2'b11);
     
		# 2000000
		$finish;
	end

	always begin
		# 1 mips_cpu_clk = ~mips_cpu_clk;
	end

    mips_cpu_top    u_mips_cpu (
        .mips_cpu_clk       (mips_cpu_clk),
        .mips_cpu_reset     (mips_cpu_reset),

        .mips_cpu_pc_sig    (mips_cpu_pc_sig),
        .mips_cpu_perf_sig  (mips_cpu_perf_sig)
    );

endmodule
