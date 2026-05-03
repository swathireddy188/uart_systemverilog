module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx,          // serial input line
    output logic [7:0] rx_data,     // received byte
    output logic       rx_valid      // pulses HIGH when byte ready
);

localparam int CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;
localparam int HALF_BIT      = CLKS_PER_BIT / 2; // sample at mid-bit

typedef enum logic [1:0] {
    IDLE  = 2'd0,
    START = 2'd1,
    DATA  = 2'd2,
    STOP  = 2'd3
} state_t;

state_t              state;
logic [13:0]         clk_count;
logic [2:0]          bit_idx;
logic [7:0]          rx_shift;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        rx_valid  <= 1'b0;
        clk_count <= 0;
        bit_idx   <= 0;
    end else begin
        rx_valid <= 1'b0;  // default: not valid

        case (state)

            IDLE: begin
                // Detect falling edge = start bit
                if (!rx) begin
                    state     <= START;
                    clk_count <= 0;
                end
            end

            START: begin
                // Wait to middle of start bit to confirm
                if (clk_count == HALF_BIT - 1) begin
                    if (!rx) begin  // still LOW = valid start
                        clk_count <= 0;
                        bit_idx   <= 0;
                        state     <= DATA;
                    end else
                        state <= IDLE;  // was noise, go back
                end else
                    clk_count <= clk_count + 1;
            end

            DATA: begin
                // Sample at middle of each bit period
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count        <= 0;
                    rx_shift[bit_idx] <= rx;  // capture bit
                    if (bit_idx == 7)
                        state <= STOP;
                    else
                        bit_idx <= bit_idx + 1;
                end else
                    clk_count <= clk_count + 1;
            end

            STOP: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    rx_data   <= rx_shift;
                    rx_valid  <= 1'b1;  // byte is ready!
                    state     <= IDLE;
                    clk_count <= 0;
                end else
                    clk_count <= clk_count + 1;
            end

        endcase
    end
end
endmodule