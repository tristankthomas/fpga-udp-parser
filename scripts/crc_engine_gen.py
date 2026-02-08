

def generate_crc(data_width, crc_width, poly, msb_first=False):
    
    # state[i] is a set of strings representing the XOR sum for that bit
    # the whole XOR tree is relative to these initial c[x] states
    state = [{f"c[{i}]"} for i in range(crc_width)]

    # reverse for ethernet lsb first
    bit_indices = range(data_width - 1, -1, -1) if msb_first else range(data_width)

    # process each message bit one by one to simulate 8 serial shifts
    for k in bit_indices:
        new_state = [set() for _ in range(crc_width)]
        
        fb = state[crc_width-1]
        
        # new data bit enters at the LSB
        data_bit = {f"d[{k}]"}
        
        # LSB is always a tap so data_bit gets XORd
        new_state[0] = fb ^ data_bit
        
        # updates the state of the whole lhsr when a new message bit enters
        for i in range(1, crc_width):
            # must use previous state as there is only 1 shift per new data bit
            if (poly >> i) & 1:
                # if the bit position is a polynomial tap, XOR with MSB
                new_state[i] = state[i-1] ^ fb
            else:
                # simple shift from the previous bit
                new_state[i] = state[i-1]
        
        state = new_state

    return state

def generate_verilog(filename):
    crc_size = 32
    data_width = 8
    polynomial = 0x04C11DB7

    state = generate_crc(data_width, crc_size, polynomial)
    with open(filename, "w") as f:
        f.write(f"function [{crc_size-1}:0] next_crc;\n")
        f.write(f"    input [{crc_size-1}:0] c;\n")
        f.write(f"    input [{data_width-1}:0] d;\n")
        f.write(f"    begin\n")
        
        for i in range(crc_size):
            # sort the c terms first, followed by d terms
            sorted_terms = sorted(list(state[i]), key=lambda x: (x[0], int(x[x.find('[')+1:x.find(']')])))
            equation = " ^ ".join(sorted_terms)
            f.write(f"        next_crc[{i}] = {equation};\n")
            
        f.write(f"    end\n")
        f.write(f"endfunction\n")

generate_verilog("..\\generated\\crc_engine.v")
