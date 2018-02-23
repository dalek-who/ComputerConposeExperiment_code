`timescale 10ns / 1ns

module mips_cpu_test
();

	// TODO: implement your testbench
	reg		mips_cpu_clk;
    reg     mips_cpu_reset;

	initial begin
		mips_cpu_clk = 1'b0;
		mips_cpu_reset = 1'b1;
		# 3
		mips_cpu_reset = 1'b0;

		# 20000
		$finish;
	end
    
    //自己加的，用于一次跑完12个用例（内存的用例更新是在ideal_mem.v里写的）
    /*
    always
    begin
    # 160_000
    mips_cpu_reset = 1'b1;
    # 3
    mips_cpu_reset = 1'b0;
    end
    */
    initial
    begin
        repeat(12)
        begin
            wait(u_mips_cpu_top.u_ideal_mem.mem[3] == 0)
            begin
            #20_050;
            mips_cpu_reset = 1'b1;
            # 3
            mips_cpu_reset = 1'b0;
            end//wait
        end//repeat
    end//initial
    
	always begin
		# 2 mips_cpu_clk = ~mips_cpu_clk;
	end

    mips_cpu_top    u_mips_cpu_top (
        .mips_cpu_clk       (mips_cpu_clk),
        .mips_cpu_reset   (mips_cpu_reset)
    );
    
endmodule
