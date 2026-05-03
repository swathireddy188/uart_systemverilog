module uart_loopback #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       tx_busy
);

logic serial_line;  // wire connecting TX output to RX input

uart_tx #(CLK_FREQ, BAUD_RATE) u_tx (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_start (tx_start),
    .tx_data  (tx_data),
    .tx       (serial_line),
    .tx_busy  (tx_busy)
);

uart_rx #(CLK_FREQ, BAUD_RATE) u_rx (
    .clk      (clk),
    .rst_n    (rst_n),
    .rx       (serial_line),
    .rx_data  (rx_data),
    .rx_valid (rx_valid)
);

endmodule