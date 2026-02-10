from scapy.all import Ether, IP, ICMP, UDP, raw, hexdump
import binascii

def generates_frames(filename):
    # ping packet
    pkt = Ether(dst="04:a4:dd:09:35:c7", src="00:11:22:33:44:55") / \
          IP(dst="192.168.1.10", src="192.168.1.50") / \
          ICMP() / \
          "Test Frame!!!"

    frame_bytes = raw(pkt)

    # calculate CRC over entire frame
    crc = binascii.crc32(frame_bytes) & 0xffffffff
    fcs = crc.to_bytes(4, byteorder='little') # transmits FCS LSb first
    
    # assemble full MII message
    full_stream = frame_bytes + fcs
    hexdump(full_stream)
    # export
    with open(filename, 'w') as f:
        for b in full_stream:
            f.write(f"{b:02x}\n")

frames = [
    # ICMP ping
    Ether(dst="04:a4:dd:09:35:c7", src="00:11:22:33:44:55")/IP(dst="192.168.1.10")/ICMP()/"Ping_1",
    
    # UDP packet
    Ether(dst="04:a4:dd:09:35:c7", src="00:11:22:33:44:55")/IP(dst="192.168.1.10")/UDP(sport=1234, dport=80)/"UDP_Data",
    
    # ICMP ping
    Ether(dst="04:a4:dd:09:35:c7", src="00:11:22:33:44:55")/IP(dst="192.168.1.10")/ICMP()/"Ping_2"
]

generates_frames("..\\generated\\frames.mem")