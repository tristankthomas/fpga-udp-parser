def generate_crc(data_width, crc_width, poly):
    
    # state[i] is a set of strings representing the XOR sum for that bit
    state = [{f"c[{i}]"} for i in range(crc_width)]

    # process each message bit LSb-first (Ethernet style)
    for k in range(data_width):
        new_state = [set() for _ in range(crc_width)]
        
        # reflected CRC: feedback is from LSb (if using left shift/MSb first we would do 7-k)
        fb = state[0] ^ {f"d[{k}]"}
        
        # reflected shift: bits shift right toward LSb
        for i in range(crc_width - 1):
            if (poly >> i) & 1:
                new_state[i] = state[i + 1] ^ fb
            else:
                new_state[i] = state[i + 1]

        # MSb gets the feedback bit
        new_state[crc_width - 1] = fb
        
        state = new_state

    return state


def generate_verilog(filename):
    crc_size = 32
    data_width = 8
    polynomial = 0xEDB88320  # reflected polynomial (Ethernet)

    state = generate_crc(data_width, crc_size, polynomial)
    with open(filename, "w") as f:
        f.write(f"function [{crc_size-1}:0] next_crc;\n")
        f.write(f"    input [{crc_size-1}:0] c;\n")
        f.write(f"    input [{data_width-1}:0] d;\n")
        f.write(f"    begin\n")
        
        for i in range(crc_size):
            sorted_terms = sorted(
                list(state[i]),
                key=lambda x: (x[0], int(x[x.find('[')+1:x.find(']')]))
            )
            equation = " ^ ".join(sorted_terms)
            f.write(f"        next_crc[{i}] = {equation};\n")
            
        f.write(f"    end\n")
        f.write(f"endfunction\n")


generate_verilog("..\\generated\\crc_engine.v")