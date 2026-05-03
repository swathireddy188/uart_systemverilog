module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,  // 100 MHz clock
    parameter BAUD_RATE = 9600
)(
    input  logic       clk,
    input  logic       rst_n,      // active-low reset
    input  logic       tx_start,   // pulse HIGH to send
    input  logic [7:0] tx_data,    // byte to transmit
    output logic       tx,         // serial output line
    output logic       tx_busy     // HIGH while sending
);

// Baud rate clock divider
localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE; // 10417

// State machine states
typedef enum logic [2:0] {
    IDLE    = 3'd0,
    START   = 3'd1,
    DATA    = 3'd2,
    STOP    = 3'd3
} state_t;

state_t              state;
logic [13:0]         clk_count;  // counts up to CLKS_PER_BIT
logic [2:0]          bit_idx;    // which bit we are sending (0-7)
logic [7:0]          tx_shift;   // shift register holds the byte

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        tx        <= 1'b1;   // idle line is HIGH
        tx_busy   <= 1'b0;
        clk_count <= 0;
        bit_idx   <= 0;
    end else begin
        case (state)

            IDLE: begin
                tx      <= 1'b1;
                tx_busy <= 1'b0;
                if (tx_start) begin
                    tx_shift  <= tx_data;
                    state     <= START;
                    clk_count <= 0;
                    tx_busy   <= 1'b1;
                end
            end

            START: begin
                tx <= 1'b0;  // start bit is LOW
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    bit_idx   <= 0;
                    state     <= DATA;
                end else
                    clk_count <= clk_count + 1;
            end

            DATA: begin
                tx <= tx_shift[bit_idx];  // send LSB first
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    if (bit_idx == 7)
                        state <= STOP;
                    else
                        bit_idx <= bit_idx + 1;
                end else
                    clk_count <= clk_count + 1;
            end

            STOP: begin
                tx <= 1'b1;  // stop bit is HIGH
                if (clk_count == CLKS_PER_BIT - 1) begin
                    state     <= IDLE;
                    clk_count <= 0;
                    tx_busy   <= 1'b0;
                end else
                    clk_count <= clk_count + 1;
            end

        endcase
    end
end
endmodule