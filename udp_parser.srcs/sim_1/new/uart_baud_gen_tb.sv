`timescale 1ns / 1ps

module uart_baud_gen_tb();

    parameter CLK_FREQ = 50_000_000;
    parameter real CLK_PERIOD = 1.0e9/CLK_FREQ;

    reg clk;
    reg rst;
    wire tick;

    uart_baud_gen uut (
        .clk(clk),
        .rst(rst),
        .baud_tick(tick)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    realtime last_tick_time = 0;
    realtime current_period = 0;

    always @(posedge tick) begin
        if (last_tick_time > 0) begin
            current_period = $realtime - last_tick_time;
            $display("[TIME: %0t] Tick detected. Period since last: %0f ns", $realtime, current_period);
        end
        last_tick_time = $realtime;
    end

    initial begin
        $display("Simulation Started.");

        clk = 0;
        rst = 1;
        
        #(CLK_PERIOD * 5);
        rst = 0;

        #100000;

        $display("Simulation Finished.");
        $finish;
    end

endmodule