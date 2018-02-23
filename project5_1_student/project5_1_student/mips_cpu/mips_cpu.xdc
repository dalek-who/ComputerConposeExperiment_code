create_clock -period 20 -name clk -waveform {0 10} [get_ports mips_cpu_clk]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_clk]
set_property package_pin D18 [get_ports mips_cpu_clk]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_reset]
set_property package_pin F16 [get_ports mips_cpu_reset]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_pc_sig]
set_property package_pin D16 [get_ports mips_cpu_pc_sig]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[0]]
set_property package_pin G16 [get_ports mips_cpu_perf_sig[0]]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[1]]
set_property package_pin F18 [get_ports mips_cpu_perf_sig[1]]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[2]]
set_property package_pin E18 [get_ports mips_cpu_perf_sig[2]]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[3]]
set_property package_pin G17 [get_ports mips_cpu_perf_sig[3]]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[4]]
set_property package_pin F17 [get_ports mips_cpu_perf_sig[4]]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[5]]
set_property package_pin C15 [get_ports mips_cpu_perf_sig[5]]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[6]]
set_property package_pin B15 [get_ports mips_cpu_perf_sig[6]]

set_property IOSTANDARD LVCMOS18 [get_ports mips_cpu_perf_sig[7]]
set_property package_pin B16 [get_ports mips_cpu_perf_sig[7]]
