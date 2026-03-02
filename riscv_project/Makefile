# =============================================================================
# Makefile — Build bare-metal C program for CV32E40P on Tang Nano 9K
# Requires: riscv-none-elf-gcc (xpack) in PATH
# =============================================================================

TOOLCHAIN = riscv-none-elf
CC        = $(TOOLCHAIN)-gcc
OBJCOPY   = $(TOOLCHAIN)-objcopy
OBJDUMP   = $(TOOLCHAIN)-objdump
SIZE      = $(TOOLCHAIN)-size

# Flags: RV32IMC, no stdlib, no startup files
CFLAGS = -march=rv32imc -mabi=ilp32 \
         -Os \
         -ffreestanding -nostdlib -nostartfiles \
         -Wall -Wextra \
         -I.

LDFLAGS = -T link.ld -nostdlib

SRCS = start.S main.c
TARGET = firmware

all: $(TARGET).hex $(TARGET).dump

$(TARGET).elf: $(SRCS) link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRCS) -o $@
	$(SIZE) $@

# Verilog hex format for $readmemh
$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O verilog $< $@
	@echo ""
	@echo ">>> Copy $(TARGET).hex to your Gowin project folder <<<"
	@echo ">>> Then synthesize and flash <<<" 

$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -d -S $< > $@
	@echo "Disassembly written to $(TARGET).dump"

clean:
	rm -f $(TARGET).elf $(TARGET).hex $(TARGET).dump

.PHONY: all clean
