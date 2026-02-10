
package eth_pkg;

    typedef logic [7:0] byte_t;
    typedef byte_t byte_array_t[];
    localparam PREAMBLE_LEN = 7;
    localparam SFD_LEN = 1;
    localparam MAC_LEN = 6;
    localparam ETHERTYPE_LEN = 2;
    localparam MAX_PAYLOAD_LEN = 1500;
    localparam FCS_LEN = 4;
    localparam HEADER_LEN = (2 * MAC_LEN) + ETHERTYPE_LEN;
    
    localparam IFG_CYCLES = 12;
   
    
    localparam PREAMBLE_BYTE = 8'h55;
    localparam SFD_BYTE = 8'hD5;
     
    
endpackage
