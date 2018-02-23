`timescale 10ns / 1ns

module mips_cpu_test
();

	reg				mips_cpu_clk;
    reg				mips_cpu_reset;

    wire            mips_cpu_pc_sig;
	wire [7:0]		mips_cpu_perf_sig;

	initial begin
		mips_cpu_clk = 1'b0;
		mips_cpu_reset = 1'b1;
		# 3
		mips_cpu_reset = 1'b0;

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
		.mips_cpu_perf_sig	(mips_cpu_perf_sig)
    );

endmodule
