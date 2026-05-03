# 100 MHz clock constraint for Artix-7 / Basys3
create_clock -period 20.000 -name clk [get_ports clk]

# Input/output delay
set_input_delay  -clock clk 2.0 [get_ports {rst_n tx_start tx_data[*]}]
set_output_delay -clock clk 2.0 [get_ports {rx_data[*] rx_valid tx_busy}]