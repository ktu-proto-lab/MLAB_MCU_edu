#########################
# --- RISC-V COMPILER ---
#########################
RISCVGNU ?= riscv64-unknown-elf
RISCVPATH ?= # e.g. /opt/riscv/bin/

#########################
# --- DIRECTORY SETUP ---
#########################

# The build directory is where all intermediate and final files will go.
BUILD_DIR = build/

#########################
# --- COMPILER OPTS ---
#########################

# Architecture-specific options for the assembler.
AOPS = -march=rv32imc_zicsr

# Compilation options for C files.
COPS = $(AOPS) -mabi=ilp32 -Wall -O2 -Os -Oz -nostdlib -nostartfiles -ffreestanding -fdata-sections -g 


# Add the common include directory to the compiler flags.
# This allows using `#include "timer.h"` instead of `#include "../common/inc/timer.h"`.
COPS += $(C_INCLUDES)

##################################
# --- SOURCE FILE DISCOVERY ---
##################################

# Automatically find all C source files in the common 'src' directory.
SRCS := $(C_SOURCES)

OBJS = $(addprefix $(BUILD_DIR),$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))

######################
# --- MAIN TARGETS ---
######################

# The default 'all' target depends on creating the final binary.
all: directories $(BUILD_DIR)$(PROGRAM).bin

# Target to clean up all built files.
clean:
	rm -rf $(BUILD_DIR)

# Target to create the build directory.
directories: $(BUILD_DIR)

# Rule to create the build directory.
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

#########################
# --- COMPILATION ---
#########################

# Compile the assembly startup file `crt0.S`.
$(BUILD_DIR)novectors.o: $(COMMON_DIR)/crt0.S
	$(RISCVPATH)$(RISCVGNU)-as $(AOPS) $< -o $@

# Compile any `.c` source file into a `.o` object file.
$(BUILD_DIR)%.o: %.c
	$(RISCVPATH)$(RISCVGNU)-gcc $(COPS) -c $< -o $@

#################
# --- LINKING ---
#################

# Rule to link all object files into a single ELF executable.
$(BUILD_DIR)$(PROGRAM).elf: $(OBJS) $(BUILD_DIR)novectors.o
	$(RISCVPATH)$(RISCVGNU)-ld -m elf32lriscv $(filter %.o,$^) -T $(COMMON_DIR)/link.ld -o $@ \
	-L$(COMMON_DIR)/lib/newlib_build/riscv64-unknown-elf/lib \
	-lc -lm --gc-sections -lnosys

# 	-L$(COMMON_DIR)/lib/riscv-newlib/riscv32-unknown-elf/lib/ -lc_nano -lg_nano -lm_nano --gc-sections

# 	-L$(COMMON_DIR)/lib/newlib_build/riscv64-unknown-elf/lib \
# 	-lc -lm --gc-sections -lnosys

	$(RISCVPATH)$(RISCVGNU)-objdump -d -S $@ > $(BUILD_DIR)$(PROGRAM).list

####################################################
# --- POST-PROCESSING (BINARY & VERILOG FILES) ---
####################################################

# Rule to generate the final .bin file and all other simulation files from the .elf file.
$(BUILD_DIR)$(PROGRAM).bin: $(BUILD_DIR)$(PROGRAM).elf
	# Generate instructions memory binary file.
	$(RISCVPATH)$(RISCVGNU)-objcopy $< -O binary -j .vectors -j .text -j .nops -j .rodata $(BUILD_DIR)$(PROGRAM)_instr.bin
	# Generate data memory binary file.
	$(RISCVPATH)$(RISCVGNU)-objcopy $< -O binary -j .data -j .bss -j .stack $(BUILD_DIR)$(PROGRAM)_data.bin
	# Pad instructions and data memory to their full size.
	dd if=/dev/null of=$(BUILD_DIR)$(PROGRAM)_instr.bin bs=1 count=1 seek=8192
	dd if=/dev/null of=$(BUILD_DIR)$(PROGRAM)_data.bin bs=1 count=1 seek=4096
	# Combine the padded instruction and data binaries into the final .bin file.
	cat $(BUILD_DIR)$(PROGRAM)_instr.bin $(BUILD_DIR)$(PROGRAM)_data.bin > $@
	# Generate Verilog hex file.
	$(RISCVPATH)$(RISCVGNU)-objcopy $< -O verilog --verilog-data-width 1 -j .vectors -j .text -j .nops -j .rodata -j .bss -j .stack -j .data $(BUILD_DIR)verilog_hex.v
	sed -i '/^@9/s/^\(@9[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\)0/\12/' $(BUILD_DIR)verilog_hex.v
	sed -i '/^@/s/^@....\(.*\)/@\1/' $(BUILD_DIR)verilog_hex.v
	# Generate separate instruction and data memory images for memory initialization.
	$(RISCVPATH)$(RISCVGNU)-objcopy $< -O verilog --verilog-data-width 4 -j .vectors -j .text -j .nops -j .rodata --reverse-bytes=4 $(BUILD_DIR)instr_hex_temp.mem
	$(RISCVPATH)$(RISCVGNU)-objcopy $< -O verilog --verilog-data-width 4 -j .data --reverse-bytes=4 $(BUILD_DIR)data_hex.mem
	sed -i 's/@[0-9a-fA-F]\([0-9a-fA-F]*\)/@0\1/' $(BUILD_DIR)instr_hex_temp.mem
	sed -i 's/@[0-9a-fA-F]\([0-9a-fA-F]*\)/@0\1/' $(BUILD_DIR)data_hex.mem
	sed '0,/^@/!{/^@/d}' $(BUILD_DIR)instr_hex_temp.mem > $(BUILD_DIR)instr_hex.mem
	# Copy generated files to the parent `ibex_sw` directory for use by a simulator.
	cp $(BUILD_DIR)verilog_hex.v $(COMMON_DIR)/..
	cp $(BUILD_DIR)$(PROGRAM).bin $(COMMON_DIR)/../verilog_bin.bin
	# Report final program size.
	@echo "--- Program Size ---"
	@$(RISCVPATH)$(RISCVGNU)-size $<
	@echo "--------------------"
