`timescale 1ns / 1ps

module udp_parser_top(
    input logic ETH_RXCK,
    input logic ETH_RXDV,
    input logic [3:0] ETH_RXD,
    input logic PL_KEY1,
    output logic ETH_nRST
);

    parameter MAC_ADDR = 48'h04_A4_DD_09_35_C7;
    logic rst_n;
    logic [3:0] rx_data;
    logic [7:0] fifo_byte;
    logic frame_err, frame_valid;
    logic wr_en;
    
    
    // instantiate mac
    eth_mac_rx #(
        .MAC_ADDR(MAC_ADDR)
    ) mac_rc (
        .eth_rx_clk(ETH_RXCK),
        .rst_n(rst_n),
        .eth_rx_data(ETH_RXD),
        .eth_rx_valid(ETH_RXDV),
        .byte_out(fifo_byte),
        .frame_err(frame_err),
        .frame_valid(frame_valid),
        .wr_en(wr_en)
    );
    
    // synchronise key1 into rst_n
    sync_ff sync_rst_n (
        .clk(ETH_RXCK),
        .rst_n(PL_KEY1),
        .data(1'b1),
        .data_sync(rst_n)
    ); 

    
    // feed output data into fifo (todo)

    assign ETH_nRST = rst_n;
    
endmodule
