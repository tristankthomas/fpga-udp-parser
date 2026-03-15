# ethernet RX
set_property PACKAGE_PIN M17 [get_ports {ETH_RXD[3]}]
set_property PACKAGE_PIN M18 [get_ports {ETH_RXD[2]}]
set_property PACKAGE_PIN K14 [get_ports {ETH_RXD[1]}]
set_property PACKAGE_PIN J14 [get_ports {ETH_RXD[0]}]
set_property PACKAGE_PIN K17 [get_ports ETH_RXCK] # 25MHz
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
set_property PACKAGE_PIN N18 [get_ports PL_CLK_50M] # 50MHz

# IO standards
set_property IOSTANDARD LVCMOS33 [get_ports ETH_*]
set_property IOSTANDARD LVCMOS33 [get_ports PL_KEY1]
set_property IOSTANDARD LVCMOS33 [get_ports PL_LED1]
set_property IOSTANDARD LVCMOS33 [get_ports PL_LED2]
set_property IOSTANDARD LVCMOS33 [get_ports PL_CLK_50M]

# clock constraints
create_clock -period 40.000 -name eth_rx_clk [get_ports ETH_RXCK]
create_clock -period 20.000 -name sys_clk [get_ports PL_CLK_50M]

# set delays for PHY to FPGA
set_input_delay -clock [get_clocks eth_rx_clk] -max 10.000 [get_ports {ETH_RXD[*] ETH_RXDV}]
set_input_delay -clock [get_clocks eth_rx_clk] -min 2.000  [get_ports {ETH_RXD[*] ETH_RXDV}]

# ignore async data paths (all synchronised in RTL)
set_max_delay -from [get_clocks eth_rx_clk] -to [get_clocks sys_clk] 20.000 -datapath_only
set_max_delay -from [get_clocks sys_clk] -to [get_clocks eth_rx_clk] 20.000 -datapath_only

# ignore asynchronous inputs/outputs
set_false_path -to [get_ports PL_LED1]
set_false_path -to [get_ports PL_LED2]
set_false_path -to [get_ports ETH_nRST]
set_false_path -from [get_ports PL_KEY1]