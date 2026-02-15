# ethernet RX
set_property PACKAGE_PIN M17 [get_ports {ETH_RXD[3]}]
set_property PACKAGE_PIN M18 [get_ports {ETH_RXD[2]}]
set_property PACKAGE_PIN K14 [get_ports {ETH_RXD[1]}]
set_property PACKAGE_PIN J14 [get_ports {ETH_RXD[0]}]
set_property PACKAGE_PIN K17 [get_ports ETH_RXCK]
set_property PACKAGE_PIN K18 [get_ports ETH_RXDV]

# ethernet TX
set_property PACKAGE_PIN L14 [get_ports ETH_TXCK]

# ethernet reset (updated to J20 from H20)
set_property PACKAGE_PIN J20 [get_ports ETH_nRST]

# keys
set_property PACKAGE_PIN P16 [get_ports PL_KEY1]

# leds
set_property PACKAGE_PIN P15 [get_ports PL_LED1]
set_property PACKAGE_PIN U12 [get_ports PL_LED2]

# clk
set_property PACKAGE_PIN N18 [get_ports PL_CLK_50M]

# IO standards
set_property IOSTANDARD LVCMOS33 [get_ports ETH_*]
set_property IOSTANDARD LVCMOS33 [get_ports PL_KEY1]
set_property IOSTANDARD LVCMOS33 [get_ports PL_LED1]
set_property IOSTANDARD LVCMOS33 [get_ports PL_LED2]
set_property IOSTANDARD LVCMOS33 [get_ports PL_CLK_50M]

# RX clock constraint (25MHz)
create_clock -period 40.000 -name eth_rx_clk [get_ports ETH_RXCK]



connect_debug_port u_ila_0/probe4 [get_nets [list {mac_rx/mac_addr_test[0]} {mac_rx/mac_addr_test[1]} {mac_rx/mac_addr_test[2]} {mac_rx/mac_addr_test[3]} {mac_rx/mac_addr_test[4]} {mac_rx/mac_addr_test[5]} {mac_rx/mac_addr_test[6]} {mac_rx/mac_addr_test[7]}]]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list ETH_RXCK_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 11 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {mac_rx/byte_cnt[0]} {mac_rx/byte_cnt[1]} {mac_rx/byte_cnt[2]} {mac_rx/byte_cnt[3]} {mac_rx/byte_cnt[4]} {mac_rx/byte_cnt[5]} {mac_rx/byte_cnt[6]} {mac_rx/byte_cnt[7]} {mac_rx/byte_cnt[8]} {mac_rx/byte_cnt[9]} {mac_rx/byte_cnt[10]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {mac_rx/rx_byte[0]} {mac_rx/rx_byte[1]} {mac_rx/rx_byte[2]} {mac_rx/rx_byte[3]} {mac_rx/rx_byte[4]} {mac_rx/rx_byte[5]} {mac_rx/rx_byte[6]} {mac_rx/rx_byte[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {ETH_RXD_IBUF[0]} {ETH_RXD_IBUF[1]} {ETH_RXD_IBUF[2]} {ETH_RXD_IBUF[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 3 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {mac_rx/state[0]} {mac_rx/state[1]} {mac_rx/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list ETH_RXDV_IBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list frame_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list frame_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list mac_rx/rx_byte_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets ETH_RXCK_IBUF_BUFG]
