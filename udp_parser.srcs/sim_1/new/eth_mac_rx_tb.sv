`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2026 22:15:15
// Design Name: 
// Module Name: eth_mac_rx_tb
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

module eth_mac_rx_tb;

    parameter RX_CLK_FREQ = 25_000_000; // 25MHz clk
    parameter RX_CLK_PERIOD = 1.0e9/RX_CLK_FREQ;
    parameter mac_addr_t DEST_MAC = 48'h04_A4_DD_09_35_C7;
    
    logic rx_clk;
    logic rx_rst_n;
    logic rx_valid;
    logic [3:0] rx_data;
    logic [7:0] byte_out;
    logic flush_frame, frame_valid, wr_en;
    logic [7:0] rx_frame_q[$]; // queue used to store uut result
    logic [7:0] tx_frame_q[$]; // queue used to store send data
    
    // instantiate MAC
    eth_mac_rx #(
        .MAC_ADDR(DEST_MAC)
    ) uut (
        .eth_rx_clk(rx_clk),
        .rst_n(rx_rst_n),
        .eth_rx_data(rx_data),
        .eth_rx_valid(rx_valid),
        .byte_out(byte_out),
        .flush_frame(flush_frame),
        .frame_valid(frame_valid),
        .wr_en(wr_en)
    );
    
    // setup clk
    initial rx_clk = 0;
    always #(RX_CLK_PERIOD) rx_clk <= ~rx_clk;
    
    
    // driver
    task send_nibble (input logic [3:0] nibble);
        rx_data <= nibble;
    endtask
    
    task send_byte (input logic [7:0] data);
        $display("DEBUG: Sending byte %h", data);
        send_nibble(data[3:0]);
        @(posedge rx_clk);
        send_nibble(data[7:4]);
    endtask
    
    task send_frame (
        input mac_addr_t dest_mac,
        input mac_addr_t source_mac,
        input logic [1:0] [7:0] ether_type,
        input logic [7:0] payload[],
        input logic [3:0] [7:0] fcs
        );
        
        // populate the expected results
        for (int i = MAC_LEN-1; i >= 0; i--) tx_frame_q.push_back(dest_mac[i]);
        for (int i = MAC_LEN-1; i >= 0; i--) tx_frame_q.push_back(source_mac[i]);
        tx_frame_q.push_back(ether_type[15:8]);
        tx_frame_q.push_back(ether_type[7:0]);
        foreach(payload[i]) tx_frame_q.push_back(payload[i]);
        for (int i = 3; i >= 0; i--) tx_frame_q.push_back(fcs[i]);
        
        // let mac know data is available
        rx_valid <= 1'b1;
        
        // preamble
        repeat(PREAMBLE_LEN) begin
            send_byte(PREAMBLE_BYTE);
            @(posedge rx_clk);
        end
        
        send_byte(SFD_BYTE);
        @(posedge rx_clk);
        
        // send destination mac
        for (int i = MAC_LEN-1; i >= 0; i--) begin
            send_byte(dest_mac[i]);
            @(posedge rx_clk);
        end
        
        // send source mac
        for (int i = MAC_LEN-1; i >= 0; i--) begin
            send_byte(source_mac[i]);
            @(posedge rx_clk);
        end
        
        // send ethertype
        send_byte(ether_type[1]);
        @(posedge rx_clk);
        send_byte(ether_type[0]);
        @(posedge rx_clk);
        
        // send payload
        foreach(payload[i]) begin
            send_byte(payload[i]);
            @(posedge rx_clk);
        
        end
        
        // send FSC
        for (int i = 3; i >= 0; i--) begin
            send_byte(fcs[i]);
            @(posedge rx_clk);
        end 
        
        
        // end of frame
        rx_valid <= 1'b0;
        rx_data  <= 4'h0;
        
    endtask
    
    
    task reset;
        rx_rst_n <= 1'b0;
        rx_valid <= 1'b0;
        rx_data <= 4'h0;
        repeat(4) @(posedge rx_clk);
        rx_rst_n <= 1'b1;
    endtask
    
    
    // storing result
    // probably need to add a clocking block to avoid race conditions
    logic byte_valid_reg;
    always @(posedge rx_clk) begin
        byte_valid_reg <= uut.rx_byte_valid;
        if (wr_en && byte_valid_reg) begin
            rx_frame_q.push_back(byte_out);
            $display("[%0t] DEBUG: wr_en=%b, valid=%b, byte=%h", $time, wr_en, uut.rx_byte_valid, byte_out);
        end
    
    end
   
   
    // scoreboard
    always @(posedge frame_valid) begin
        if (rx_frame_q.size() != tx_frame_q.size()) begin   
            $display("ERROR: Frame size mismatch. Expected: %d, Result: %d", tx_frame_q.size(), rx_frame_q.size());
            $write("DEBUG: tx_frame_q contents: ");
            foreach (tx_frame_q[i]) $write("%02h ", tx_frame_q[i]);
            $display("");
        
            $write("DEBUG: rx_frame_q contents: ");
            foreach (rx_frame_q[i]) $write("%02h ", rx_frame_q[i]);
            $display("");
            
        end else begin
            automatic bit match = 1;
            foreach (tx_frame_q[i]) begin
                if (tx_frame_q[i] != rx_frame_q[i]) begin
                    $display("ERROR: Byte mismatch. Expected: %h, Result: %h", tx_frame_q[i], rx_frame_q[i]);
                    match = 0;
                end
            
            end
            if (match) begin
                $display("SUCCESS: Frame recevied correctly.");
            end
            
            // clear queues for new frame
            tx_frame_q.delete();
            rx_frame_q.delete();
        
        end   
    end
    
    always @(posedge flush_frame) begin
        $display("WARNING: Frame not received correctly.");
        tx_frame_q.delete();
        rx_frame_q.delete();
   
    end
    
   
   
    initial begin
        
        reset();
        
        // valid frame
        send_frame(
            DEST_MAC,
            48'h71_AB_D9_7E_01_10,
            16'h0800,
            '{8'hDE, 8'hAD, 8'hBE, 8'hEF},
            $urandom()
        );
        
        repeat(20) @(posedge rx_clk);
        
        $display("Simulation Finished at %t", $time);
        $finish;        
        
    
    end
    
endmodule
