`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.02.2026 22:28:29
// Design Name: 
// Module Name: tb_ip_parser
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

module tb_ip_parser;

    parameter CLK_FREQ = 50_000_000;
    parameter CLK_PERIOD = 1.0e9/CLK_FREQ;
    parameter IP_ADDRESS = 32'hC0A80101;
    parameter TRANSPORT_PROTOCOL = 8'd17;
    
    logic clk;
    logic rst_n;
    byte_t eth_data_in;
    logic eth_eof;
    logic eth_err;
    logic eth_byte_valid;
    byte_t ip_data_out;
    logic ip_byte_valid;
    logic ip_eof;
    logic ip_err;
    
    byte_t rx_data_q[$]; // data outputted to IP parser 
    byte_t tx_data_q[$]; // data inputted from FIFO
    logic error_expected = 1'b0;
    logic error_found = 1'b0;
    
    // instantiate uut
    ip_parser #(
        .TRANSPORT_PROTOCOL(TRANSPORT_PROTOCOL),
        .IP_ADDRESS(IP_ADDRESS)
    ) uut (
        .*
    );
    
    // clk generation
    initial clk = 0;
    always #(CLK_PERIOD) clk <= ~clk;
    
    // checksum calculation function
    function automatic logic [15:0] calculate_ip_checksum(input byte_t header[]);
        logic [31:0] sum = 0;
        logic [15:0] word;
        for (int i = 0; i < header.size(); i += 2) begin
            word = {header[i], header[i+1]};
            sum = sum + word;
        end
        // while carry bit
        while (sum >> 16) begin
            sum = (sum & 32'hFFFF) + (sum >> 16);
        end
        return ~sum[15:0];
    endfunction
    
    task reset;
        rst_n <= 1'b0;
        eth_err <= 1'b0;
        eth_eof <= 1'b0;
        eth_byte_valid <= 1'b0;
        @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
    endtask
    
    task send_data (
        input byte_t data,
        input logic eof = 0,
        input logic err = 0
    );
        eth_byte_valid <= 1'b1;
        eth_data_in <= data;
        if (eof) eth_eof <= 1'b1;
        if (err) eth_err <= 1'b1;
        // simulate tvalid from fifo (1 pulse every 4 cycles)
        @(posedge clk);
        eth_eof <= 1'b0;
        eth_err <= 1'b0;
        eth_byte_valid <= 1'b0;
        repeat(3) @(posedge clk);
    endtask
    
    // driver
    task send_frame (
        input logic [3:0] ip_version,
        input byte_t trans_protocol,
        input byte_t [3:0] src_ip_addr,
        input byte_t [3:0] dest_ip_addr,
        input byte_t payload[],
        input logic crc_err,
        input logic total_len_err = 0,
        input logic force_bad_checksum = 0
    );
        byte_t header[20];
        logic [15:0] total_len;
        logic [15:0] checksum;
        
        if (total_len_err)
            total_len = 16'd20 + payload.size()+5;
        else total_len = 16'd20 + payload.size();


        // assemble header for checksum calculation
        header = {>>{
            {ip_version, 4'd5}, // version & ihl
            8'h00,              // dscp & ecn
            total_len,          // total length
            16'h1234,           // identification
            16'h0000,           // flags & fragment offset
            8'h40,              // ttl
            trans_protocol,     // protocol
            16'h0000,           // checksum placeholder
            src_ip_addr,        // source address
            dest_ip_addr        // destination address
        }};

        checksum = calculate_ip_checksum(header);
        {header[10], header[11]} = checksum;    

        if (force_bad_checksum) header[10] = ~header[10];

        error_expected = ip_version !== 4'd4 || dest_ip_addr !== IP_ADDRESS || 
                         crc_err || trans_protocol !== TRANSPORT_PROTOCOL || 
                         force_bad_checksum || total_len_err;
        
        // send header
        foreach (header[i]) send_data(header[i]);
        
        // send payload
        foreach (payload[i]) begin
            tx_data_q.push_back(payload[i]);
            if (i == payload.size()-1) begin
                send_data(payload[i], 1, crc_err);
                break;
            end
            send_data(payload[i]);
        end

        cleanup();
       
    endtask
    
    task cleanup;
        eth_byte_valid <= 1'b0;
        eth_eof <= 1'b0;
        eth_err <= 1'b0;
        repeat(4) @(posedge clk);
    endtask
    
    function automatic byte_array_t random_payload(input int length);
        byte_array_t payload;
        payload = new[length];
    
        for (int i = 0; i < length; i++) begin
            payload[i] = $urandom_range(0, 255);
        end
    
        return payload;
    endfunction
    
    // scoreboard
    always @(posedge clk) begin
        // add received byte to queue
        if (ip_byte_valid) rx_data_q.push_back(ip_data_out);
        
        // if error occurs log it
        if (ip_err) error_found = 1'b1;
        
        // check results once frame complete
        if (ip_eof || ip_err) check_frame();
    end
    
    task check_frame;
        if (error_expected) begin
            // check error handling
            if (error_found) begin
                $display("SUCCESS: Correctly caught expected error");
            end else begin
                $display("FAIL: Expected error not caught");
            end
            
        end else if (rx_data_q.size() != tx_data_q.size())
            $display("ERROR: Frame size mismatch. Expected %d; Result %d", tx_data_q.size(), rx_data_q.size());
        else begin
            // check data was received correctly
            automatic bit match = 1;
            foreach (tx_data_q[i]) begin
                if (tx_data_q[i] != rx_data_q[i]) begin
                    $display("ERROR: Byte mismatch. Expected: %h, Result: %h", tx_data_q[i], rx_data_q[i]);
                    match = 0;
                end
            end
            if (match) begin
                $display("SUCCESS: Frame received correctly.");
            end
        end
        // clear queues for new frame
        tx_data_q.delete();
        rx_data_q.delete();
        error_found = 1'b0;
        error_expected = 1'b0;
    endtask
    
    initial begin
    
        reset();
        
        $display("Sending valid frame");
        // valid frame
        send_frame(
            4'd4,
            8'd17,
            32'h12341234,
            IP_ADDRESS,
            random_payload(20),
            0,
            1
        );
        
        $display("Sending invalid frame - wrong ip protocol");
        // invalid version
        send_frame(
            4'd3,
            8'd17,
            32'h12341234,
            IP_ADDRESS,
            random_payload(55),
            0
        );
        
        $display("Sending invalid frame - bad checksum");
        // bad checksum
        send_frame(
            4'd4,
            8'd17,
            32'h12341234,
            IP_ADDRESS,
            random_payload(55),
            0,
            0,
            1 // force_bad_checksum
        );

        $display("Sending invalid frame - crc error");
        // crc error
        send_frame(
            4'd4,
            8'd17,
            32'h12341234,
            IP_ADDRESS,
            random_payload(55),
            1
        );
        
        $display("\nSimulation Finished at %t", $time);
        $finish;
    end
    
endmodule