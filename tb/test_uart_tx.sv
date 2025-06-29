module test_uart_tx;
    timeunit 1ns; timeprecision 1ps;
    import tb_utils_pkg::*;
    // Parameters
    localparam CLK_FREQ     = 100_000_000;
    localparam BAUD_RATE    = 115200;
    localparam BAUD_PERIOD  = CLK_FREQ/BAUD_RATE; // Clock cycle
    localparam DW           = 8;
    localparam CLK_PERIOD   = 10; // 100MHz = 10ns period

    // Signals
    logic          clk_i;
    logic          rst_n_i;
    logic          tx_start;
    logic [DW-1:0] tx_data;
    logic          tx_busy;
    logic          tx;

    int error_count = 0;
    //------------------------------------------------------------------
    `ifdef SDF_TEST
    initial
    begin
    $sdf_annotate("delays.sdf",uart_tx_tb.dut,,"sdf.log","MAXIMUM");
    end
    `endif
    //------------------------------------------------------------------
    // DUT instantiation
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DW(DW)
    ) dut (.*);
    //------------------------------------------------------------------
    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end
    //------------------------------------------------------------------
    // Clock cycle wait task
    task wait_clocks(input int cycles);
        repeat(cycles) @(posedge clk_i);
    endtask
    //------------------------------------------------------------------
    // Task to transmit one byte
    task send_byte(input logic [DW-1:0] data);
        @(posedge clk_i);
        tx_start = 1'b1;
        tx_data  = data;
        @(posedge clk_i);
        tx_start = 1'b0;
        // Wait for transmission to complete
        wait(tx_busy);  // Wait until tx_busy is high
        wait(!tx_busy); // Now wait for it to become low
    endtask
    //------------------------------------------------------------------
    // Task to verify one byte transmission
    task verify_tx_byte(input logic [7:0] expected_data);
        logic [7:0] received_data;
        
        // Wait for start bit
        @(negedge tx);
        wait_clocks(BAUD_PERIOD/2);  // Middle of start bit
        
        // Verify start bit
        if (tx !== 0) begin
            error_count++;
            $error("Start bit not 0 at time %0t", $time);
            return;
        end
        
        // Sample 8 data bits
        for (int i = 0; i < 8; i++) begin
            wait_clocks(BAUD_PERIOD);
            received_data[i] = tx;
        end
        
        // Verify stop bit
        wait_clocks(BAUD_PERIOD);
        if (tx !== 1) begin
            error_count++;
            $error("Stop bit not 1 at time %0t", $time);
            return;
        end
        
        // Compare data
        if (received_data !== expected_data) begin
            error_count++;
            $error("Data mismatch at time %0t. Expected: %8b, Got: %8b", 
                   $time, expected_data, received_data);
        end else begin
            $display("Data verified successfully at time %0t. Data: %8b", 
                     $time, received_data);
        $display("-----------------------");
        end
    endtask
    //------------------------------------------------------------------
    // Test stimulus
    initial begin
        // Initialize
        rst_n_i = 1'b1; // Start with reset de-asserted
        tx_start = 0;
        tx_data = '0;
        
        // Reset sequence
        #(CLK_PERIOD * 2); // Wait a bit
        rst_n_i = 1'b0; // Assert reset
        #(CLK_PERIOD * 5);
        rst_n_i = 1;
        #(CLK_PERIOD * 5);

        // Test case 1: Send single byte
        fork                              // Launches both tasks simultaneously
            send_byte(8'b10101010);       // 1. Starts transmitting data
            verify_tx_byte(8'b10101010);  // 2. Starts monitoring tx line
        join                              // Waits for both tasks to complete
            
        // #(CLK_PERIOD * 20);
        wait_clocks(BAUD_PERIOD * 2);
        
        fork
            send_byte(8'b01010101);
            verify_tx_byte(8'b01010101);
        join
            
        // #(CLK_PERIOD * 20);
        wait_clocks(BAUD_PERIOD * 2);

        // Test case 2: Back-to-back transmission
        fork
            send_byte(8'b11110000);
            verify_tx_byte(8'b11110000);
        join
        
        fork
            send_byte(8'b00001111);
            verify_tx_byte(8'b00001111);
        join

        // Test case 3: Send all ones
        fork
            send_byte(8'hFF);
            verify_tx_byte(8'hFF);
        join

        // Test case 4: Send all zeros
        fork
            send_byte(8'h00);
            verify_tx_byte(8'h00);
        join

        // End simulation
        #(CLK_PERIOD * 1000);
        display_result(error_count);
        if (error_count==0) $display("All tests passed!");
        else $display("Some tests failed!");
        $finish;
    end
    //------------------------------------------------------------------
    // Monitor
    initial begin
        $monitor("Time=%0t rst_n_i=%b tx_start=%b tx_data=%b tx_busy=%b tx=%b",
                 $time, rst_n_i, tx_start, tx_data, tx_busy, tx);
    end
    //------------------------------------------------------------------
    // Assertions
    property reset_state;
        @(posedge clk_i) !rst_n_i |-> tx === 1'b1;                 // When reset is active (!rst_n_i is true), tx must be 1'b1 (idle state).
    endproperty

    property busy_on_start;
        @(posedge clk_i) tx_start |-> ##1 tx_busy;               // When tx_start is asserted, tx_busy must be high in the next clock cycle.
    endproperty

    property start_bit;
        @(posedge clk_i) (tx_start && !tx_busy) |-> ##[1:2] !tx; // When transmission starts (tx_start high and tx_busy low), tx must go low (start bit) within 1-2 clock cycles.
    endproperty

    assert property (reset_state)
        else begin $error("Reset state failed: tx should be 1"); error_count++; end
    
    assert property (busy_on_start)
        else begin $error("tx_busy not asserted after tx_start"); error_count++; end
    
    assert property (start_bit)
        else begin $error("Start bit not detected"); error_count++; end
    //------------------------------------------------------------------
    //------------------------------------------------------------------
endmodule
