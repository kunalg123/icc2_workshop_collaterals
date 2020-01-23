create_clock -name ext_clk -period 4.0 -waveform {0.0 2.0} [get_ports ext_clk]
create_clock -name pll_clk -period 4.0 -waveform {0.0 2.0} [get_ports pll_clk]
create_clock -name spi_sck -period 4.0 -waveform {0.0 2.0} [get_ports spi_sck]
set_input_transition -min -corners func1 -modes func1 -clock [get_clocks ext_clk] 0.1 [get_ports -filter direction==in]
set_input_transition -max -corners func1 -modes func1 -clock [get_clocks ext_clk] 0.5 [get_ports -filter direction==in]
set_input_delay -min -corners func1 -modes func1 -clock ext_clk 0.2 [get_ports -filter direction==in]
set_input_delay -max -corners func1 -modes func1 -clock ext_clk 0.6 [get_ports -filter direction==in]

