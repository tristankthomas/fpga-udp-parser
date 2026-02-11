import eth_pkg::*;

module eth_mac_rx #(
    parameter byte_t [3:0] MAC_ADDR
)(
    input logic eth_rx_clk,
    input logic rst_n,
    input logic [3:0] eth_rx_data,
    input logic eth_rx_valid,
    output logic [7:0] byte_out,
    output logic frame_err,
    output logic frame_valid,
    output logic wr_en
);
    
    logic rx_byte_valid;
    logic [7:0] rx_byte;
    logic compute_crc;
    logic [31:0] curr_crc;
    logic init_crc;
    
    mii_to_byte u_mii_to_byte (
        .rx_clk(eth_rx_clk),
        .rst_n(rst_n),
        .rx_data(eth_rx_data),
        .rx_valid(eth_rx_valid),
        .byte_out(rx_byte),
        .byte_valid(rx_byte_valid)
    );
    
    crc_engine u_crc_engine (
        .clk(eth_rx_clk),
        .rst_n(rst_n),
        .init(init_crc),
        .byte_in(rx_byte),
        .en(compute_crc),
        .crc(curr_crc) 
    );
    
    typedef enum logic [2:0] { IDLE, PREAMBLE, HEADER, PAYLOAD, FCS, FINISH } state_t;
    state_t state, next_state;
    logic [$clog2(MAX_PAYLOAD_LEN)-1:0] byte_cnt;
    
    
    
    always_ff @(posedge eth_rx_clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            byte_cnt <= 0;
            frame_valid <= 1'b0;
            frame_err <= 1'b0;
            byte_out <= 8'b0;
            wr_en <= 1'b0;
            init_crc <= 1'b1;
                
        end else begin
            init_crc <= 1'b0;
        
            if (rx_byte_valid) begin
                // while valid bytes are received
                case (state)
                    IDLE : begin
                        if (rx_byte == PREAMBLE_BYTE) state <= PREAMBLE;
                        frame_err <= 1'b0;
                    end
                    
                    PREAMBLE: begin
                        if (rx_byte == SFD_BYTE) begin
                            byte_cnt <= 1'b0;
                            state <= HEADER;
                            init_crc <= 1'b1;
                        end else if (rx_byte != PREAMBLE_BYTE) begin
                            frame_valid <= 1'b0;
                            wr_en <= 1'b0;
                            state <= IDLE;
                        end 
                    end
                    
                    HEADER: begin
                        // read in the header with 4 cycle delay for FCS
                        byte_out <= rx_byte;
                        wr_en <= 1'b1;
                    
                        if (byte_cnt < MAC_LEN) begin
                            // if fpga mac is invalid then flush frame
                            if (rx_byte != MAC_ADDR[MAC_LEN-1-byte_cnt]) begin
                                frame_err <= 1'b1;
                                state <= IDLE;
                                wr_en <= 1'b0;
                            end
                            byte_cnt <= byte_cnt + 1'b1;
                        end else if (byte_cnt < HEADER_LEN) begin
                            // source mac and ethertype
                            byte_cnt <= byte_cnt + 1'b1;
                        end else begin
                            // header complete
                            state <= PAYLOAD;
                            byte_cnt <= 1'b0;
                        end
                    end
                    
                    PAYLOAD: begin
                        byte_cnt <= byte_cnt + 1'b1;
                        byte_out <= rx_byte;
                        wr_en <= 1'b1;
                    end
                    
                    default: state <= IDLE;
                endcase        
            end else if (~eth_rx_valid) begin
                // while the PHY has no more data
                case (state)
                
                    PAYLOAD: begin
                        state <= FCS;
                        wr_en <= 1'b0;
                    
                    end
                    
                    FCS: begin
                        state <= FINISH;
                        // perform FCS check - reversed order
                        if (curr_crc == 32'hDEBB20E3) begin
                            frame_valid <= 1'b1;
                            frame_err <= 1'b0;
                        end else begin
                            frame_valid <= 1'b0;
                            frame_err <= 1'b1;
                        end
                    end
                    
                    FINISH: begin
                        frame_valid <= 1'b0;
                        if (byte_cnt == IFG_CYCLES) begin
                            state <= IDLE;           
                            byte_cnt <= 1'b0;
                        end else begin
                            byte_cnt <= byte_cnt + 1'b1;
                        end    
                    
                    end
                    
                endcase
            
            end
        end
        
    end
    
    
    assign compute_crc = rx_byte_valid & (state == HEADER | state == PAYLOAD);
     
    
endmodule



