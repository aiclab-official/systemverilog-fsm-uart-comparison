#==============================================================================
# XDC Constraints File for UART Transmitter FSM Comparison
# Author: AICLAB
# Date: 2025-06-27
# Board: Nexys Video (Artix-7 XC7A200T)
# Description: Pin assignments and timing constraints for UART TX module
#==============================================================================

#==============================================================================
# Clock Constraints
#==============================================================================

# 100 MHz system clock from crystal oscillator
create_clock -period 10.0 -name sys_clk [get_ports clk_i]
set_property PACKAGE_PIN R4 [get_ports clk_i]
set_property IOSTANDARD LVCMOS33 [get_ports clk_i]

#==============================================================================
# Reset Constraints
#==============================================================================

# Active-low reset
set_property PACKAGE_PIN C22 [get_ports rst_n_i]
set_property IOSTANDARD LVCMOS12 [get_ports rst_n_i]

#==============================================================================
# Control Signal Constraints
#==============================================================================

# Start transmission signal
set_property PACKAGE_PIN D14 [get_ports tx_start]
set_property IOSTANDARD LVCMOS12 [get_ports tx_start]

#==============================================================================
# Data Input Constraints
#==============================================================================

# 8-bit parallel data input [7:0]
set_property PACKAGE_PIN E22 [get_ports {tx_data[0]}]
set_property PACKAGE_PIN F21 [get_ports {tx_data[1]}]
set_property PACKAGE_PIN G21 [get_ports {tx_data[2]}]
set_property PACKAGE_PIN G22 [get_ports {tx_data[3]}]
set_property PACKAGE_PIN H17 [get_ports {tx_data[4]}]
set_property PACKAGE_PIN J16 [get_ports {tx_data[5]}]
set_property PACKAGE_PIN K13 [get_ports {tx_data[6]}]
set_property PACKAGE_PIN M17 [get_ports {tx_data[7]}]

# I/O standards for data inputs
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[2]}]
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[4]}]
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[5]}]
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[6]}]
set_property IOSTANDARD LVCMOS12 [get_ports {tx_data[7]}]

#==============================================================================
# Output Signal Constraints
#==============================================================================

# Transmission busy status
set_property PACKAGE_PIN T14 [get_ports tx_busy]
set_property IOSTANDARD LVCMOS12 [get_ports tx_busy]

# Serial UART output
set_property PACKAGE_PIN AB22 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

#==============================================================================
# Timing Constraints
#==============================================================================

# Input delay constraints (2ns setup time relative to clock)
set_input_delay 2.0 -clock sys_clk [get_ports {tx_start tx_data rst_n_i}]

# Relax timing for slow UART outputs by treating them as asynchronous paths.
set_false_path -to [get_ports {tx tx_busy}]


#==============================================================================
# Additional Design Constraints
#==============================================================================

# Asynchronous reset constraint
set_false_path -from [get_ports rst_n_i]


#==============================================================================
# Power and Signal Integrity
#==============================================================================

# Drive strength for outputs (optional optimization)
set_property DRIVE 12 [get_ports tx]
set_property DRIVE 8 [get_ports tx_busy]

# Slew rate control for outputs
set_property SLEW SLOW [get_ports tx]
set_property SLEW FAST [get_ports tx_busy]