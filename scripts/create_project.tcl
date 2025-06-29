# This file is a Tcl script used to automate the creation of the Vivado project.

# Define project name and directory
set project_name "fsm_comparison"
set project_dir [file normalize [pwd]]

# Create the project
create_project $project_name "$project_dir/vivado" -part xc7a200tsbg484-1 -force

# Add constraints file to the constraints fileset
add_files -fileset constrs_1 "$project_dir/constraints/top.xdc"

# Define the FSM styles
set fsm_styles [list "one_block_style" "two_block_combinational" "two_block_sequential" "three_block_style"]

# Create a simulation set for each FSM style
foreach style $fsm_styles {
    create_fileset -simset -quiet "sim_$style"
    
    # Add the specific FSM implementation to the simulation set
    add_files -fileset "sim_$style" -norecurse "$project_dir/src/$style/uart_tx.sv"
    
    # Add the common testbench files to the simulation set
    add_files -fileset "sim_$style" -norecurse [glob "$project_dir/tb/*.sv"]
    
    # Set the top module for the simulation set
    set_property top test_uart_tx [get_filesets "sim_$style"]
}

# Create synthesis runs for each FSM style
foreach style $fsm_styles {
    # Create a synthesis run for this style
    create_run "synth_$style" -flow {Vivado Synthesis 2024}
    
    # Create a separate source fileset for this synthesis run
    create_fileset -srcset "sources_$style"
    
    # Add the specific FSM implementation to this source fileset
    add_files -fileset "sources_$style" -norecurse "$project_dir/src/$style/uart_tx.sv"
    
    # Set the top module for this source fileset
    set_property top uart_tx [get_filesets "sources_$style"]
    
    # Associate this source fileset with the synthesis run
    set_property srcset "sources_$style" [get_runs "synth_$style"]
}

# Create implementation runs for each synthesis run
foreach style $fsm_styles {
    # Create an implementation run for this style, based on its synthesis run
    create_run "impl_$style" -parent_run "synth_$style" -flow {Vivado Implementation 2024}
}

# Set the default synthesis run to the three_block_style
current_run [get_runs "synth_three_block_style"]

current_fileset -simset [get_filesets sim_three_block_style]

# Delete the default simulation fileset
if {[llength [get_filesets -quiet sim_1]] > 0} {
    delete_fileset [get_filesets sim_1]
    puts "Deleted default simulation fileset: sim_1"
} else {
    puts "Default simulation fileset sim_1 not found or already deleted"
} 


# Delete the default synthesis run (we created our own)
if {[llength [get_runs -quiet synth_1]] > 0} {
    delete_runs [get_runs synth_1]
    puts "Deleted default synthesis run: synth_1"
} else {
    puts "Default synthesis run synth_1 not found or already deleted"
}

# Delete the default implementation run (we created our own)
if {[llength [get_runs -quiet impl_1]] > 0} {
    delete_runs [get_runs impl_1]
    puts "Deleted default implementation run: impl_1"
} else {
    puts "Default implementation run impl_1 not found or already deleted"
}

# Print completion message
puts "Project $project_name created successfully in $project_dir/vivado."
puts "Created synthesis runs for all FSM styles:"
foreach style $fsm_styles {
    puts "  - synth_$style"
}
puts "Created implementation runs for all FSM styles:"
foreach style $fsm_styles {
    puts "  - impl_$style"
}
puts ""
puts "To run synthesis for all styles, use:"
puts "  launch_runs \[get_runs synth_*\]"
puts ""
puts "To run implementation for all styles (after synthesis), use:"
puts "  launch_runs \[get_runs impl_*\]"
puts ""
puts "To run both synthesis and implementation sequentially:"
puts "  launch_runs \[get_runs synth_*\] -to_step write_bitstream"