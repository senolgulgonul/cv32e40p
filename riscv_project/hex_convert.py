#!/usr/bin/env python3
# =============================================================================
# hex_convert.py — Convert riscv objcopy -O verilog hex to Gowin-compatible
# word-per-line $readmemh format
#
# Usage: python hex_convert.py firmware.hex firmware_gowin.hex
# =============================================================================

import sys

def convert(input_file, output_file):
    # 4KB = 1024 words, initialize to NOP (addi x0,x0,0 = 0x00000013)
    mem = [0x00000013] * 1024

    with open(input_file, 'r') as f:
        byte_addr = 0
        bytes_buf = []
        current_addr = 0

        for line in f:
            line = line.strip()
            if not line:
                continue

            if line.startswith('@'):
                # Flush previous bytes if any
                if bytes_buf:
                    for i, b in enumerate(bytes_buf):
                        addr = current_addr + i
                        word_idx = addr // 4
                        byte_pos = addr % 4
                        if word_idx < 1024:
                            mem[word_idx] = (mem[word_idx] & ~(0xFF << (byte_pos * 8))) | (b << (byte_pos * 8))
                    bytes_buf = []

                current_addr = int(line[1:], 16)
            else:
                # Parse bytes on this line
                parts = line.split()
                for p in parts:
                    if len(p) == 2:
                        try:
                            b = int(p, 16)
                            addr = current_addr + len(bytes_buf)
                            word_idx = addr // 4
                            byte_pos = addr % 4
                            if word_idx < 1024:
                                mem[word_idx] = (mem[word_idx] & ~(0xFF << (byte_pos * 8))) | (b << (byte_pos * 8))
                            bytes_buf.append(b)
                        except ValueError:
                            pass

    # Write word-per-line hex (Gowin $readmemh format)
    with open(output_file, 'w') as f:
        for i, word in enumerate(mem):
            f.write(f'{word:08X}\n')

    print(f"Converted {input_file} → {output_file}")
    print(f"First 16 words:")
    for i in range(16):
        print(f"  [{i:3d}] 0x{mem[i]:08X}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: python hex_convert.py <input.hex> <output.hex>")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])