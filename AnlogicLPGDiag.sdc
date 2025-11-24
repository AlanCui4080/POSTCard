create_clock -name clk -period 40 -waveform {0 20} [get_ports {clk}]
create_clock -name lpc_clk -period 30 -waveform {0 20} [get_ports {lpc_clk}]