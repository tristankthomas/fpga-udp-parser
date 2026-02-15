from scapy.all import Ether, Raw, sendp

dst_mac = "04:A4:DD:09:35:C7" # FPGA MAC
src_mac = "00:E0:4C:B3:02:F6" # NIC MAC

payload = b'Hello FPGA'

# build ethernet frame
frame = Ether(dst=dst_mac, src=src_mac, type=0x1234)/Raw(load=payload)

# send frame to FPGA
sendp(frame, iface="Ethernet", verbose=True)