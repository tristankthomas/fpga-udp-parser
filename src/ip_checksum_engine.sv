`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.02.2026 12:42:27
// Design Name: 
// Module Name: ip_checksum_engine
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ip_checksum_engine (
    input logic clk,
    input logic rst_n,
    input logic byte_valid,
    input logic [7:0] byte_in,
    input logic init,
    input logic en,
    output logic [15:0] checksum
);
    logic [7:0] first_byte;
    logic byte_num;
    logic [16:0] sum_acc;
    logic [16:0] sum_nxt;

    // update checksum as soon as byte is received/valid - not the cycle after
    always_comb begin
        if (en && byte_valid && byte_num) begin
            // 1's complement addition
            sum_nxt = sum_acc[15:0] + sum_acc[16] + {first_byte, byte_in};
        end else begin
            sum_nxt = sum_acc;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum_acc <= 17'h0;
            first_byte <= 8'b0;
            byte_num <= 1'b0;
        end else if (init) begin
            sum_acc <= 17'h0;
            first_byte <= 8'b0;
            byte_num <= 1'b0;
        end else if (en && byte_valid) begin
            // only update checksum after full word is received
            byte_num <= ~byte_num;
            if (~byte_num) begin
                first_byte <= byte_in;
            end else begin
                sum_acc <= sum_nxt;
            end
        end

    end

    assign checksum = ~(sum_nxt[15:0] + sum_nxt[16]);

endmodule