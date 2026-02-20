🚀 Built a RISC-V SoC on FPGA from scratch — Version 1.0

⚡ Synthesized the open-source CV32E40P (OpenHW Group) RISC-V RV32IMC core on a Tang Nano 9K FPGA (Gowin GW1NR-9C)

🔧 Converted the entire CV32E40P SystemVerilog codebase to Verilog using sv2v to work around Gowin EDA limitations

🧠 Implemented a correct OBI (Open Bus Interface) memory controller with proper pending transaction tracking

💾 Designed custom 4KB IMEM + 4KB DMEM block SRAM peripherals fitting within the 8,640 LUT budget (~98% utilization)

💡 Built an LED peripheral and UART TX peripheral memory-mapped into the RISC-V address space

🛠️ Set up a complete bare-metal C toolchain (RISC-V GCC → ELF → hex → FPGA)

🐍 Wrote a Python hex converter to translate GCC objcopy output into Gowin-compatible $readmemh format

📟 Successfully ran a C program on the core printing to UART and controlling LEDs in real time

🎯 Achieved full edit → compile → flash workflow: write C, make, convert, synthesize, flash
