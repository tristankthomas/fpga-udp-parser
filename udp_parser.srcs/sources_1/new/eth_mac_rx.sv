import eth_pkg::*;

module eth_mac_rx #(
    parameter mac_addr_t MAC_ADDR
    )(
    input logic eth_rx_clk,
    input logic rst_n,
    input logic [3:0] eth_rx_data,
    input logic eth_rx_valid,
    output logic [7:0] byte_out,
    output logic flush_frame,
    output logic frame_valid,
    output logic wr_en
    );
    
    logic rx_byte_valid;
    logic [7:0] rx_byte;
    
    mii_to_byte u_mii_to_byte (
        .rx_clk(eth_rx_clk),
        .rst_n(rst_n),
        .rx_data(eth_rx_data),
        .rx_valid(eth_rx_valid),
        .byte_out(rx_byte),
        .byte_valid(rx_byte_valid)
    );
    
    typedef enum logic [2:0] { IDLE, PREAMBLE, HEADER, PAYLOAD, FCS, FINISH } state_t;
    state_t state, next_state;
    logic [$clog2(MAX_PAYLOAD_LEN)-1:0] byte_cnt;
    
    
    
    always_ff @(posedge eth_rx_clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            byte_cnt <= 0;
            frame_valid <= 1'b0;
            flush_frame <= 1'b0;
            byte_out <= 8'b0;
            wr_en <= 1'b0;
            
        end else if (rx_byte_valid) begin
                
            case (state)
                IDLE : begin
                    if (rx_byte == PREAMBLE_BYTE) state <= PREAMBLE;
                    flush_frame <= 1'b0;
                end
                
                PREAMBLE: begin
                    if (rx_byte == SFD_BYTE) begin
                        byte_cnt <= 1'b0;
                        state <= HEADER;
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
                            flush_frame <= 1'b1;
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
            case (state)
            
                PAYLOAD: begin
                    state <= FCS;
                    wr_en <= 1'b0;
                
                end
                FCS: begin
                    // perform FCS check on fcs_buffer
                    frame_valid <= 1'b1;
                    state <= FINISH;
                end
                
                
                FINISH: begin
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
     
    
endmodule



