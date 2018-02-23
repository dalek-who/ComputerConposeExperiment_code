# parsing argument
if {$argc != 1} {
	puts "The argument should be board or simu"
} else {
	set exp_mode [lindex $argv 0]
}

# setting parameters
if {$exp_mode == "simu"} {
	set project_name "mips_cpu_simu"
} else {
	set project_name "mips_cpu_board"
}

if {$exp_mode == "simu"} {
	set topmodule_src "mips_cpu_top"
} else {
	set topmodule_src "mips_cpu_fpga"
}

if {$exp_mode == "simu"} {
	set topmodule_test "mips_cpu_test"
}

set device xc7z020-1-clg484
set board interwise.com:zypi:part0:1.1
set mips_dir mips_core
set mips_top_dir mips_core_top

# setting up the project
set project_dir [file dirname [info script]]
create_project $project_name -force -dir "./${project_name}" -part ${device}
set_property board_part $board [current_project] 

# create Board Design (BD) with Zynq processing system
if {$exp_mode == "board"} {
	source ${project_dir}/zynq_soc.tcl
	
	make_wrapper -files [get_files ./${project_name}/${project_name}.srcs/sources_1/bd/zynq_soc/zynq_soc.bd] -top
	import_files -force -norecurse -fileset sources_1 ./${project_name}/${project_name}.srcs/sources_1/bd/zynq_soc/hdl/zynq_soc_wrapper.v
	
	validate_bd_design
	save_bd_design
	close_bd_design zynq_soc
}

# Verilog define macro
if {$exp_mode == "simu"} {
	set_property verilog_define { {MIPS_CPU_FULL_SIMU} } [get_fileset sources_1]
	set_property verilog_define { {MIPS_CPU_FULL_SIMU} } [get_fileset sim_1]
}

# src files
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../${mips_dir}/alu.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../${mips_dir}/reg_file.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../${mips_dir}/mips_cpu.v"]"

add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../${mips_top_dir}/ideal_mem.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../${mips_top_dir}/mips_cpu_top.v"]"

if {$exp_mode == "board"} {
	add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../${mips_top_dir}/axi_lite_if.v"]"
	add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../mips_cpu_fpga.v"]"
}

# sim files
if {$exp_mode == "simu"} {
	add_files -norecurse -fileset sim_1 "[file normalize "${project_dir}/../sim.v"]"
	set_property "top" $topmodule_test [get_filesets sim_1]
}

# contraints files
if {$exp_mode == "simu"} {
	add_files -fileset constrs_1 -norecurse "${project_dir}/../mips_cpu.xdc"
}

# setting top module for FPGA flow and simulation flow
set_property "top" $topmodule_src [get_filesets sources_1]

# setting Synthesis options
set_property strategy {Vivado Synthesis defaults} [get_runs synth_1]
#keep module port names in the netlist
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY {none} [get_runs synth_1]

# setting Implementation options
set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
# the following implementation options will increase runtime, but get the best timing results
#set_property strategy Performance_Explore [get_runs impl_1]
