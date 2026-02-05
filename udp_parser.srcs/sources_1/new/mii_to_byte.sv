`timescale 1ns / 1ps

module mii_to_byte(
    input logic rx_clk,
    input logic rst_n,
    input logic [3:0] rx_data,
    input logic rx_valid,
    output logic [7:0] byte_out,
    output logic byte_valid
    );
    
    logic [3:0] low_nibble;
    logic nibble_phase;
    
    always_ff @(posedge rx_clk or negedge rst_n) begin
        if (~rst_n) begin
            byte_out <= 8'b0;
            nibble_phase <= 1'b0;
            byte_valid <= 1'b0;
            low_nibble <= 4'h0;
        end else if (rx_valid) begin
            if (nibble_phase == 1'b0) begin
                // captures first nibble
                low_nibble <= rx_data;
                nibble_phase <= 1'b1;
                byte_valid <= 1'b0;
            end else begin
                // captures second nibble
                byte_out <= {rx_data, low_nibble};
                byte_valid <= 1'b1;
                nibble_phase <= 1'b0;
            end
        end else begin
            // data not valid so reset
            nibble_phase <= 1'b0;
            byte_valid <= 1'b0;
        end    
        
    end
    
endmodule
