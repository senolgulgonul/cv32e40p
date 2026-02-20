# =============================================================================
# tangnano9k.sdc — Timing Constraints
# Target: 27 MHz onboard oscillator
# CV32E40P should close timing at 27 MHz on GW1NR-9C with margin.
# =============================================================================

create_clock -name clk_27mhz -period 37.037 [get_ports {clk_27mhz}]

# Relax I/O paths (LEDs and UART are not timing-critical)
set_false_path -from [get_ports {rst_n}]
set_false_path -to   [get_ports {led[*]}]
set_false_path -to   [get_ports {uart_tx}]
