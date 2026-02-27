`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.01.2026 20:47:06
// Design Name: 
// Module Name: mii_mac_rx
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

import eth_pkg::*;


module mii_mac_rx #(
    parameter byte_t [5:0] MAC_ADDR
)(
    input logic rx_clk,
    input logic rst_n,
    input logic [3:0] rx_data,
    input logic rx_valid,
    output byte_t data_out,
    output logic frame_err,
    output logic frame_valid,
    output logic wr_en
);
    
    logic rx_byte_valid;
    byte_t rx_byte;
    logic compute_crc;
    logic [31:0] curr_crc;
    logic init_crc;
    logic [$clog2(MAX_PAYLOAD_LEN)-1:0] byte_cnt;
    
    typedef enum logic [2:0] { IDLE, PREAMBLE, HEADER, PAYLOAD, FLUSH, FINISH } state_t;
    state_t state;
    
    mii_to_byte u_mii_to_byte (
        .rx_clk(rx_clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .byte_out(rx_byte),
        .byte_valid(rx_byte_valid)
    );
    
    crc_engine u_crc_engine (
        .clk(rx_clk),
        .rst_n(rst_n),
        .init(init_crc),
        .byte_in(rx_byte),
        .en(compute_crc),
        .crc(curr_crc) 
    );
    
    localparam SHIFT = 5;
    // create a 5 cycle delay so that the last payload byte aligns with the crc result (valid | err)
    byte_t [SHIFT-1:0] data_pipe;
    logic [SHIFT-1:0] wr_pipe;
    logic [SHIFT-1:0] mac_err_pipe;
    logic crc_err;
    logic mac_err;

    logic incoming_mac_err;
    assign incoming_mac_err = (state == HEADER) && (byte_cnt < MAC_LEN) && (rx_byte !== MAC_ADDR[MAC_LEN-1-byte_cnt]);
   
    // shift pipelines
    always_ff @(posedge rx_clk or negedge rst_n) begin
        if (~rst_n) begin
            data_pipe <= '0;
            wr_pipe <= '0;
            mac_err_pipe <= '0;
        end else if (rx_byte_valid) begin
            data_pipe <= {data_pipe[3:0], rx_byte};
            wr_pipe <= {wr_pipe[3:0], (state == HEADER || state == PAYLOAD)};
            mac_err_pipe <= {mac_err_pipe[3:0], incoming_mac_err};
        end
    end
    
    
    always_ff @(posedge rx_clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            byte_cnt <= '0;
            frame_valid <= 1'b0;
            crc_err <= 1'b0;
            init_crc <= 1'b1;
        end else begin
            init_crc <= 1'b0;
            case (state)
                IDLE : begin
                    frame_valid <= 1'b0;
                    crc_err <= 1'b0;
                    if (rx_byte_valid && rx_byte === PREAMBLE_BYTE) state <= PREAMBLE;
                end
                
                PREAMBLE: begin
                
                    if (rx_byte_valid) begin
                        if (rx_byte === SFD_BYTE) begin
                            byte_cnt <= '0;
                            state <= HEADER;
                            init_crc <= 1'b1;
                        end else if (rx_byte !== PREAMBLE_BYTE) begin
                            state <= IDLE;
                        end
                    
                    end
                end
                
                HEADER: begin
                    if (rx_byte_valid) begin
                        // check if byte 5 cycles ago had mac error
                        if (mac_err) begin
                            state <= FLUSH;
                            wr_pipe <= 5'b0;
                            mac_err_pipe <= 5'b0;
                        end


                        if (byte_cnt == ETH_HEADER_LEN + SHIFT - 1) begin
                            // ensure we only leave HEADER once all the header bytes have been sent to data_out
                            state <= PAYLOAD;
                            byte_cnt <= '0;
                        end else 
                            // increment byte count
                            byte_cnt <= byte_cnt + 1'b1;
                        
                        
                    end
                end
                
                PAYLOAD: begin
                    if (~rx_valid) begin
                        // perform FCS check on live bytes - reversed order
                        if (curr_crc == 32'hDEBB20E3) begin
                            frame_valid <= 1'b1;
                            crc_err <= 1'b0;
                        end else begin
                            frame_valid <= 1'b0;
                            crc_err <= 1'b1;
                        end
                        
                        state <= FINISH;
                        byte_cnt <= '0;
                    end
                end
                
                FLUSH: begin
                    if (~rx_valid) state <= FINISH; 
                end
                
                FINISH: begin
                    frame_valid <= 1'b0;
                    crc_err <= 1'b0;
                    wr_pipe <= 5'b0;
                    if (byte_cnt == IFG_CYCLES) state <= IDLE;
                    else byte_cnt <= byte_cnt + 1'b1;
                end
            endcase
            
        end
        
    end
    
    
    assign compute_crc = rx_byte_valid & (state == HEADER || state == PAYLOAD);
    // want wr_en to pulse with available byte & 5th shift for crc result (valid/err)
    assign wr_en = wr_pipe[4] && (rx_byte_valid || crc_err || frame_valid); 
    assign data_out = data_pipe[4];
    assign frame_err = (mac_err || crc_err);
    assign mac_err = mac_err_pipe[4] && rx_byte_valid;
    
endmodule



