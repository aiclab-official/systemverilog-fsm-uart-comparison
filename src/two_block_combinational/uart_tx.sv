// UART Transmitter FSM Example - Two-Block Coding Style (Combined Next State + Output Logic)

module uart_tx #(
    parameter CLK_FREQ = 100_000_000, // 100 MHz clock
    parameter BAUD_RATE = 115200,     // Standard baud rate
    parameter DW = 8                  // Standard data width
)(
    input  logic           clk_i,
    input  logic           rst_n_i,
    input  logic           tx_start,  // Start transmission
    input  logic [DW-1:0]  tx_data,   // Data to transmit
    output logic           tx_busy,   // Transmission in progress
    output logic           tx         // Serial output
);
    timeunit 1ns; timeprecision 1ps;
    // State encoding (one-hot)
    typedef enum logic [3:0] {
        IDLE  = 4'b0001,
        START = 4'b0010,
        DATA  = 4'b0100,
        STOP  = 4'b1000
    } state_t;

    state_t current_state, next_state;
    
    // Baud rate generator
    localparam BAUD_COUNT = CLK_FREQ/BAUD_RATE;
    logic [$clog2(BAUD_COUNT)-1:0] baud_counter;
    logic baud_tick;

    // Bit counter
    logic [$clog2(DW)-1:0] bit_count;
    logic [DW-1:0] tx_shift_reg;

    // Baud rate generator
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            baud_counter <= '0;
        else if (baud_counter == BAUD_COUNT-1)
            baud_counter <= '0;
        else if (current_state != IDLE)
            baud_counter <= baud_counter + 1'b1;
    end

    assign baud_tick = (baud_counter == BAUD_COUNT-1);

    // State register
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Bit counter
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            bit_count <= '0;
        else if (current_state == IDLE)
            bit_count <= '0;
        else if (current_state == DATA && baud_tick)
            bit_count <= bit_count + 1'b1;
    end

    // Shift register
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            tx_shift_reg <= '1;
        else if (current_state == IDLE && tx_start)
            tx_shift_reg <= tx_data;
        else if (current_state == DATA && baud_tick)
            tx_shift_reg <= {1'b1, tx_shift_reg[DW-1:1]};
    end

    // Two-block style: Combined Next State and Output Logic
    always_comb begin
        // Default assignments
        next_state = current_state;
        tx = 1'b1; // Default output (idle)
        
        case (current_state)
            IDLE: begin
                tx = 1'b1;
                if (tx_start)
                    next_state = START;
            end
            START: begin
                tx = 1'b0;
                if (baud_tick)
                    next_state = DATA;
            end
            DATA: begin
                tx = tx_shift_reg[0];
                if (baud_tick && bit_count == DW-1)
                    next_state = STOP;
            end
            STOP: begin
                tx = 1'b1;
                if (baud_tick)
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
                tx = 1'b1;
            end
        endcase
    end

    assign tx_busy = (current_state != IDLE);

endmodule