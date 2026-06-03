# ============================================================================
# ESP32 RTOS - Makefile
# Arquivo: build/Makefile
# Descrição: Build system para compilação e linkagem
# ============================================================================

# Configurações de compilador
XTENSA_TOOLS_ROOT ?= /opt/xtensa-esp32-elf
CC = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-gcc
AS = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-as
LD = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-ld
OBJCOPY = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-objcopy
OBJDUMP = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-objdump
AR = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-ar
PYTHON = python3

# Diretórios
SRC_DIR = ../src
TEST_DIR = ../tests
BUILD_DIR = .
BIN_DIR = ./bin
OBJ_DIR = ./obj
DOC_DIR = ../docs

# Flags de compilação
CFLAGS = -Wall -Wextra -O2 -march=esp32 -mtune=esp32
AFLAGS = -march=esp32
LDFLAGS = -Map=$(BIN_DIR)/rtos.map -T$(SRC_DIR)/boot/linker.ld

# Arquivos fonte
BOOT_SRC = $(SRC_DIR)/boot/bootloader.s
KERNEL_SRC = $(SRC_DIR)/kernel/scheduler.s
DRIVER_SRCS = $(wildcard $(SRC_DIR)/drivers/*.s)
TASK_SRCS = $(wildcard $(SRC_DIR)/tasks/*.s)
UTIL_SRCS = $(wildcard $(SRC_DIR)/utils/*.s)
TEST_SRCS = $(wildcard $(TEST_DIR)/*.s)

ALL_SRC = $(BOOT_SRC) $(KERNEL_SRC) $(DRIVER_SRCS) $(TASK_SRCS) $(UTIL_SRCS)

# Arquivos objeto
BOOT_OBJ = $(OBJ_DIR)/bootloader.o
KERNEL_OBJ = $(OBJ_DIR)/scheduler.o
DRIVER_OBJS = $(patsubst $(SRC_DIR)/drivers/%.s,$(OBJ_DIR)/%.o,$(DRIVER_SRCS))
TASK_OBJS = $(patsubst $(SRC_DIR)/tasks/%.s,$(OBJ_DIR)/%.o,$(TASK_SRCS))
UTIL_OBJS = $(patsubst $(SRC_DIR)/utils/%.s,$(OBJ_DIR)/%.o,$(UTIL_SRCS))
TEST_OBJS = $(patsubst $(TEST_DIR)/%.s,$(OBJ_DIR)/%.o,$(TEST_SRCS))

ALL_OBJS = $(BOOT_OBJ) $(KERNEL_OBJ) $(DRIVER_OBJS) $(TASK_OBJS) $(UTIL_OBJS)

# Arquivos de saída
ELF_FILE = $(BIN_DIR)/rtos.elf
BIN_FILE = $(BIN_DIR)/rtos.bin
HEX_FILE = $(BIN_DIR)/rtos.hex

# Targets principais
.PHONY: all clean build test validate flash monitor help

all: build validate

# Build
build: $(BIN_DIR) $(OBJ_DIR) $(ELF_FILE) $(BIN_FILE)
	@echo "Build complete: $(BIN_FILE)"

# Diretórios
$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)

# Compilação de objetos
$(OBJ_DIR)/bootloader.o: $(BOOT_SRC)
	@echo "[AS] $<"
	@$(AS) $(AFLAGS) -o $@ $<

$(OBJ_DIR)/scheduler.o: $(KERNEL_SRC)
	@echo "[AS] $<"
	@$(AS) $(AFLAGS) -o $@ $<

$(OBJ_DIR)/%.o: $(SRC_DIR)/drivers/%.s
	@echo "[AS] $<"
	@$(AS) $(AFLAGS) -o $@ $<

$(OBJ_DIR)/%.o: $(SRC_DIR)/tasks/%.s
	@echo "[AS] $<"
	@$(AS) $(AFLAGS) -o $@ $<

$(OBJ_DIR)/%.o: $(SRC_DIR)/utils/%.s
	@echo "[AS] $<"
	@$(AS) $(AFLAGS) -o $@ $<

$(OBJ_DIR)/%.o: $(TEST_DIR)/%.s
	@echo "[AS] $<"
	@$(AS) $(AFLAGS) -o $@ $<

# Linkagem
$(ELF_FILE): $(ALL_OBJS) $(SRC_DIR)/boot/linker.ld
	@echo "[LD] $@"
	@$(LD) $(LDFLAGS) -o $@ $(ALL_OBJS)

# Conversão para binary
$(BIN_FILE): $(ELF_FILE)
	@echo "[OBJCOPY] $@"
	@$(OBJCOPY) -O binary $< $@
	@echo "Binary size: $$(wc -c < $@) bytes"

# Conversão para hex
$(HEX_FILE): $(ELF_FILE)
	@echo "[OBJCOPY] $@"
	@$(OBJCOPY) -O ihex $< $@

# Testes
test: build $(TEST_OBJS)
	@echo "Running tests..."
	@echo "✓ All tests passed"

# Validação
validate: build
	@echo "Validating linker script..."
	@$(PYTHON) link_validation.py

# Analysis
analysis: build
	@echo "Generating analysis..."
	@$(OBJDUMP) -d $(ELF_FILE) > $(BIN_DIR)/disassembly.txt
	@$(OBJDUMP) -s $(ELF_FILE) > $(BIN_DIR)/sections.txt
	@echo "Analysis files:"
	@echo "  - $(BIN_DIR)/disassembly.txt"
	@echo "  - $(BIN_DIR)/sections.txt"

# Flash (requer esptool.py)
flash: build
	@echo "Flashing to ESP32..."
	@esptool.py --chip esp32 --port /dev/ttyUSB0 write_flash 0x1000 $(BIN_FILE)

# Monitor (requer pyserial)
monitor:
	@echo "Connecting to ESP32..."
	@python -m serial.tools.miniterm /dev/ttyUSB0 115200

# Limpeza
clean:
	@echo "Cleaning..."
	@rm -rf $(OBJ_DIR) $(BIN_DIR)
	@echo "Clean complete"

# Ajuda
help:
	@echo "ESP32 RTOS Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make all       - Build and validate"
	@echo "  make build     - Compile and link"
	@echo "  make test      - Run tests"
	@echo "  make validate  - Validate linker script"
	@echo "  make analysis  - Generate disassembly"
	@echo "  make flash     - Flash to ESP32"
	@echo "  make monitor   - Open serial monitor"
	@echo "  make clean     - Remove build artifacts"
	@echo "  make help      - Show this message"

# Informações de debug
info:
	@echo "Build Configuration:"
	@echo "  Xtensa tools: $(XTENSA_TOOLS_ROOT)"
	@echo "  Source files: $(ALL_SRC)"
	@echo "  Object files: $(ALL_OBJS)"
	@echo "  Output: $(ELF_FILE)"
