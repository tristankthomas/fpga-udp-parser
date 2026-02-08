`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.02.2026 22:48:45
// Design Name: 
// Module Name: crc_engine
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


module crc_engine(
    input logic clk,
    input logic rst_n,
    input logic [7:0] byte_in,
    input logic en,
    output logic [31:0] crc
    );
    
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            crc <= 32'h00000000;
        end else if (en) begin
            crc <= next_crc(crc, byte_in);
        end
    end
    
    
    // generated in scripts/crc_engine_gen.py
    // simulates 8 shifts of the LFSR
    function [31:0] next_crc;
        input [31:0] c;
        input [7:0] d;
        begin
            next_crc[0] = c[24] ^ c[30] ^ d[7];
            next_crc[1] = c[24] ^ c[25] ^ c[30] ^ c[31] ^ d[6];
            next_crc[2] = c[24] ^ c[25] ^ c[26] ^ c[30] ^ c[31] ^ d[5];
            next_crc[3] = c[25] ^ c[26] ^ c[27] ^ c[31] ^ d[4];
            next_crc[4] = c[24] ^ c[26] ^ c[27] ^ c[28] ^ c[30] ^ d[3];
            next_crc[5] = c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[29] ^ c[30] ^ c[31] ^ d[2];
            next_crc[6] = c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ c[31] ^ d[1];
            next_crc[7] = c[24] ^ c[26] ^ c[27] ^ c[29] ^ c[31] ^ d[0];
            next_crc[8] = c[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
            next_crc[9] = c[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29];
            next_crc[10] = c[2] ^ c[24] ^ c[26] ^ c[27] ^ c[29];
            next_crc[11] = c[3] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
            next_crc[12] = c[4] ^ c[24] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30];
            next_crc[13] = c[5] ^ c[25] ^ c[26] ^ c[27] ^ c[29] ^ c[30] ^ c[31];
            next_crc[14] = c[6] ^ c[26] ^ c[27] ^ c[28] ^ c[30] ^ c[31];
            next_crc[15] = c[7] ^ c[27] ^ c[28] ^ c[29] ^ c[31];
            next_crc[16] = c[8] ^ c[24] ^ c[28] ^ c[29];
            next_crc[17] = c[9] ^ c[25] ^ c[29] ^ c[30];
            next_crc[18] = c[10] ^ c[26] ^ c[30] ^ c[31];
            next_crc[19] = c[11] ^ c[27] ^ c[31];
            next_crc[20] = c[12] ^ c[28];
            next_crc[21] = c[13] ^ c[29];
            next_crc[22] = c[14] ^ c[24];
            next_crc[23] = c[15] ^ c[24] ^ c[25] ^ c[30];
            next_crc[24] = c[16] ^ c[25] ^ c[26] ^ c[31];
            next_crc[25] = c[17] ^ c[26] ^ c[27];
            next_crc[26] = c[18] ^ c[24] ^ c[27] ^ c[28] ^ c[30];
            next_crc[27] = c[19] ^ c[25] ^ c[28] ^ c[29] ^ c[31];
            next_crc[28] = c[20] ^ c[26] ^ c[29] ^ c[30];
            next_crc[29] = c[21] ^ c[27] ^ c[30] ^ c[31];
            next_crc[30] = c[22] ^ c[28] ^ c[31];
            next_crc[31] = c[23] ^ c[29];
        end
    endfunction
    
    
    

endmodule
