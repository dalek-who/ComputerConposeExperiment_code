# setting parameters
set project_name "mips_cpu_perf_counter"
set topmodule_src "mips_cpu_top"
set topmodule_test "mips_cpu_test"
set device xc7z020-1-clg484
set board interwise.com:zypi:part0:1.1

# setting up the project
set project_dir [file dirname [info script]]
create_project $project_name -force -dir "./${project_name}" -part ${device}
set_property board_part $board [current_project] 

# src files
# TODO: add all RTL source files of your single cycle MIPS CPU design here
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../alu.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../reg_file.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../mips_cpu.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../ideal_mem.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${project_dir}/../mips_cpu_top.v"]"

# sim files
add_files -norecurse -fileset sim_1 "[file normalize "${project_dir}/../sim.v"]"
#set_property verilog_define { {FULL_SIMU} } [get_fileset sim_1]

# contraints files
add_files -fileset constrs_1 -norecurse "${project_dir}/../mips_cpu.xdc"

# setting top module for FPGA flow and simulation flow
set_property "top" $topmodule_src [get_filesets sources_1]
set_property "top" $topmodule_test [get_filesets sim_1]

# setting Synthesis options
set_property strategy {Vivado Synthesis defaults} [get_runs synth_1]
#keep module port names in the netlist
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY {none} [get_runs synth_1]

# setting Implementation options
set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
# the following implementation options will increase runtime, but get the best timing results
#set_property strategy Performance_Explore [get_runs impl_1]
