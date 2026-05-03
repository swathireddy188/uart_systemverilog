create_project uart_proj ./vivado_project -part xc7a35tcpg236-1 -force
add_files {./src/uart_tx.sv ./src/uart_rx.sv ./src/uart_loopback.sv}
add_files -fileset sim_1 ./sim/tb_uart_loopback.sv
add_files -fileset constrs_1 ./constraints/constraints.xdc
set_property top uart_loopback [current_fileset]
set_property top tb_uart_loopback [get_filesets sim_1]
launch_simulation
run 50ms
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1
file mkdir ./reports
report_timing_summary -file ./reports/timing_summary.rpt
report_utilization -file ./reports/utilization.rpt
