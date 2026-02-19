# CV32E40P on Tang Nano 9K — Minimal Bare-Metal Test

## Overview
This project wraps the **CV32E40P** open-source RISC-V core (RV32IMC) in a
minimal SoC targeting the **Tang Nano 9K** (Gowin GW1NR-9C FPGA).

**What it does out of the box:**
- Sends `Hello, CV32!\r\n` over UART at 115200 baud on startup
- Walks a LED pattern across all 6 onboard LEDs in a repeating loop

---

## File Structure

```
cv32e40p_nano9k/
├── top.v              ← Top-level SoC wrapper
├── imem.v             ← 8 KB instruction ROM (program embedded)
├── dmem.v             ← 8 KB data RAM
├── uart_tx.v          ← 8N1 UART transmitter (115200 @ 27 MHz)
├── tangnano9k.cst     ← Pin constraints for Gowin EDA
├── tangnano9k.sdc     ← Timing constraints
└── README.md
```

---

## Step 1: Get the CV32E40P Source

The CV32E40P RTL is **not included here** — get it from OpenHW Group:

```bash
git clone https://github.com/openhwgroup/cv32e40p.git
cd cv32e40p
git checkout v2.0.0   # stable release
```

You need these files from the repo (add them all to your Gowin project):
```
rtl/cv32e40p_top.sv
rtl/cv32e40p_core.sv
rtl/cv32e40p_if_stage.sv
rtl/cv32e40p_id_stage.sv
rtl/cv32e40p_ex_stage.sv
rtl/cv32e40p_lsu.sv
rtl/cv32e40p_wb_stage.sv
rtl/cv32e40p_alu.sv
rtl/cv32e40p_mult.sv
rtl/cv32e40p_register_file_ff.sv
rtl/cv32e40p_controller.sv
rtl/cv32e40p_cs_registers.sv
rtl/cv32e40p_decoder.sv
rtl/cv32e40p_load_store_unit.sv
rtl/cv32e40p_prefetch_buffer.sv
rtl/cv32e40p_obi_interface.sv
rtl/cv32e40p_sleep_unit.sv
rtl/include/cv32e40p_pkg.sv       ← package file, add as include
```

> **Note:** The CV32E40P uses SystemVerilog. Gowin EDA supports `.sv` files —
> add them normally. If you hit issues, run them through sv2v first:
> `pip install sv2v` or get the binary from https://github.com/zachjs/sv2v

---

## Step 2: Create a Gowin Project

1. Open **Gowin EDA** (GOWIN FPGA Designer)
2. New Project → select **GW1NR-9C C6/I5** (Tang Nano 9K exact part)
3. Add all `.sv` files from cv32e40p/rtl/ above
4. Add `top.v`, `imem.v`, `dmem.v`, `uart_tx.v` from this project
5. Set **top.v** as the top module
6. Add `tangnano9k.cst` as Physical Constraints
7. Add `tangnano9k.sdc` as Timing Constraints

---

## Step 3: Synthesis Settings

In Gowin EDA → Process → Synthesis:
- **Top Module:** `top`
- **Use BSRAM:** Yes (default)
- **Synthesize Goal:** Area (the core is LUT-heavy)

Expected resource usage:
| Resource | Available | Used (approx) |
|----------|-----------|---------------|
| LUT4     | 8,640     | ~5,000–6,500  |
| BSRAM    | 26        | 4 (IMEM+DMEM) |
| FF       | 6,480     | ~2,000        |

It will be **tight but should fit** on the 9K.

---

## Step 4: Flash

```bash
# Using openFPGALoader (recommended)
openFPGALoader -b tangnano9k impl/pnr/top.fs

# Or use Gowin Programmer GUI (comes with EDA suite)
```

---

## Step 5: Verify

Connect a USB-UART adapter to **Pin 17** (GND to GND):

```bash
# Linux
screen /dev/ttyUSB0 115200

# or
minicom -D /dev/ttyUSB0 -b 115200

# Windows: PuTTY → Serial → COMx → 115200
```

You should see:
```
Hello, CV32!
```
...and the 6 LEDs will chase in a walking-one pattern.

---

## Address Map

| Address         | Description          |
|-----------------|----------------------|
| `0x0000_0000`   | IMEM base (8 KB ROM) |
| `0x0001_0000`   | DMEM base (8 KB RAM) |
| `0x2000_0000`   | LED register (W: bits[5:0] = LED on/off) |
| `0x2000_0004`   | UART TX (W: byte to send; R: bit0 = busy) |

---

## Customising the Program

The test program is hard-coded in `imem.v` as 32-bit machine code words.

To run your own program:

1. Write C code and compile with RISC-V GCC:
   ```bash
   riscv32-unknown-elf-gcc -march=rv32imc -mabi=ilp32 \
       -nostartfiles -T link.ld -o prog.elf main.c
   riscv32-unknown-elf-objcopy -O verilog prog.elf prog.hex
   ```

2. Replace the `initial begin` block in `imem.v` with:
   ```verilog
   initial $readmemh("prog.hex", mem);
   ```

A minimal linker script (`link.ld`) example:
```ld
MEMORY {
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 8K
    DMEM (rw) : ORIGIN = 0x00010000, LENGTH = 8K
}
SECTIONS {
    .text : { *(.text*) } > IMEM
    .data : { *(.data*) } > DMEM
    .bss  : { *(.bss*)  } > DMEM
}
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Synthesis fails with "unknown identifier" | Make sure cv32e40p_pkg.sv is added as an include/source |
| Doesn't fit (LUT overflow) | Try Gowin EDA "Performance Balanced" strategy or reduce IMEM/DMEM to 4KB |
| LEDs all off or stuck | Check rst_n polarity; hold button to reset |
| No UART output | Check Pin 17 wiring; verify 115200 8N1 no flow control |
| sv2v needed | `sv2v *.sv > merged.v` then add merged.v instead |

---

## License
This wrapper code is MIT licensed. CV32E40P is Apache 2.0 (OpenHW Group).
