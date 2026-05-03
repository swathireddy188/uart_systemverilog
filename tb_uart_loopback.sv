module tb_uart_loopback;

parameter CLK_FREQ  = 100_000_000;
parameter BAUD_RATE = 9600;
parameter CLK_PERIOD = 10;  // 10ns = 100MHz

logic       clk, rst_n;
logic       tx_start;
logic [7:0] tx_data;
logic [7:0] rx_data;
logic       rx_valid;
logic       tx_busy;
int         pass_count = 0;
int         fail_count = 0;

uart_loopback #(CLK_FREQ, BAUD_RATE) dut (.*);

// Generate 100MHz clock
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// Task: send one byte and check it comes back correctly
task automatic send_and_check(input logic [7:0] data);
    logic [7:0] received;

    // Wait until TX is free
    @(posedge clk);
    tx_data  = data;
    tx_start = 1'b1;
    @(posedge clk);
    tx_start = 1'b0;

    // Wait for rx_valid (byte received)
    @(posedge rx_valid);
    received = rx_data;
    @(posedge clk);

    // Compare sent vs received
    if (received === data) begin
        $display("PASS: sent 0x%02X, received 0x%02X", data, received);
        pass_count++;
    end else begin
        $display("FAIL: sent 0x%02X, received 0x%02X", data, received);
        fail_count++;
    end
endtask

// Main test sequence
initial begin
    // Reset
    rst_n    = 0;
    tx_start = 0;
    tx_data  = 0;
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);

    $display("=== UART loopback test start ===");

    // Test different byte values
    send_and_check(8'h41);  // 'A'
    send_and_check(8'h55);  // alternating bits 01010101
    send_and_check(8'hAA);  // alternating bits 10101010
    send_and_check(8'hFF);  // all ones
    send_and_check(8'h00);  // all zeros
    send_and_check(8'h5A);  // random pattern

    $display("=== Results: PASS=%0d  FAIL=%0d ===",
              pass_count, fail_count);
    $finish;
end

// Timeout watchdog - fail if test hangs
initial begin
    #(CLK_FREQ * 10);  // 10 second timeout
    $display("TIMEOUT - test did not complete");
    $finish;
end

endmodule