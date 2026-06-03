# ============================================================================
# ESP32 RTOS - Build System
# Arquivo: build/Makefile
# ============================================================================

# Variáveis de Ambiente
XTENSA_TOOLS_ROOT ?= /opt/xtensa-esp32-elf
ESP_IDF_PATH ?= ~/esp-idf
ESP_PORT ?= /dev/ttyUSB0
ESP_BAUD ?= 115200

# Ferramentas
CC = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-gcc
AS = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-as
LD = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-ld
OBJCOPY = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-objcopy
OBJDUMP = $(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-objdump

# Flags de Compilação
ASFLAGS = -march=esp32 -mlongcalls
LDFLAGS = -Map=esp32_rtos.map -T ../src/boot/linker.ld
OBJCOPYFLAGS = -O binary

# Diretórios
SRC_DIR = ../src
OBJ_DIR = ./obj
BIN_DIR = ./bin
DEP_DIR = ./dep

# Arquivos Fonte
BOOT_SRC = $(SRC_DIR)/boot/bootloader.s
KERNEL_SRC = $(SRC_DIR)/kernel/scheduler.s
DRIVERS_SRC = $(SRC_DIR)/drivers/uart.s $(SRC_DIR)/drivers/gpio.s $(SRC_DIR)/drivers/timer.s
TASKS_SRC = $(SRC_DIR)/tasks/demo_tasks.s
UTILS_SRC = $(SRC_DIR)/utils/constants.s $(SRC_DIR)/utils/macros.s

ALL_SRC = $(BOOT_SRC) $(KERNEL_SRC) $(DRIVERS_SRC) $(TASKS_SRC) $(UTILS_SRC)

# Objetos
BOOT_OBJ = $(OBJ_DIR)/bootloader.o
KERNEL_OBJ = $(OBJ_DIR)/scheduler.o
DRIVERS_OBJ = $(OBJ_DIR)/uart.o $(OBJ_DIR)/gpio.o $(OBJ_DIR)/timer.o
TASKS_OBJ = $(OBJ_DIR)/demo_tasks.o
UTILS_OBJ = $(OBJ_DIR)/constants.o $(OBJ_DIR)/macros.o

ALL_OBJ = $(BOOT_OBJ) $(KERNEL_OBJ) $(DRIVERS_OBJ) $(TASKS_OBJ) $(UTILS_OBJ)

# Targets
TARGET_ELF = $(BIN_DIR)/esp32_rtos.elf
TARGET_BIN = $(BIN_DIR)/esp32_rtos.bin

# Phony targets
.PHONY: all clean flash monitor size help

# Target padrão
all: $(TARGET_BIN)

# Criar diretórios
$(OBJ_DIR) $(BIN_DIR) $(DEP_DIR):
	@mkdir -p $@

# Compilar Assembly para Object
$(OBJ_DIR)/%.o: $(SRC_DIR)/**/%.s | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/bootloader.o: $(BOOT_SRC) | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/scheduler.o: $(KERNEL_SRC) | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/uart.o: $(SRC_DIR)/drivers/uart.s | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/gpio.o: $(SRC_DIR)/drivers/gpio.s | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/timer.o: $(SRC_DIR)/drivers/timer.s | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/demo_tasks.o: $(TASKS_SRC) | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/constants.o: $(SRC_DIR)/utils/constants.s | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJ_DIR)/macros.o: $(SRC_DIR)/utils/macros.s | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

# Link
$(TARGET_ELF): $(ALL_OBJ) | $(BIN_DIR)
	$(LD) $(LDFLAGS) -o $@ $^

# Convert to Binary
$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) $(OBJCOPYFLAGS) $< $@
	@echo "✓ Build successful: $@"

# Flash para ESP32
flash: $(TARGET_BIN)
	@echo "Flashing to ESP32..."
	@esptool.py -p $(ESP_PORT) -b $(ESP_BAUD) write_flash 0x1000 $<
	@echo "✓ Flash complete"

# Monitor Serial
monitor:
	@screen $(ESP_PORT) $(ESP_BAUD)

# Mostrar tamanho
size: $(TARGET_ELF)
	@$(XTENSA_TOOLS_ROOT)/bin/xtensa-esp32-elf-size $<

# Disassemble
disasm: $(TARGET_ELF)
	@$(OBJDUMP) -d $< > $(BIN_DIR)/esp32_rtos.dis
	@echo "✓ Disassembly saved to $(BIN_DIR)/esp32_rtos.dis"

# Limpar
clean:
	@rm -rf $(OBJ_DIR) $(BIN_DIR) $(DEP_DIR)
	@echo "✓ Clean complete"

# Help
help:
	@echo "ESP32 RTOS Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build the entire project (default)"
	@echo "  clean    - Remove build artifacts"
	@echo "  flash    - Build and flash to ESP32"
	@echo "  monitor  - Open serial monitor"
	@echo "  size     - Show binary size"
	@echo "  disasm   - Generate disassembly"
	@echo ""
	@echo "Variables:"
	@echo "  XTENSA_TOOLS_ROOT - Path to Xtensa toolchain (default: /opt/xtensa-esp32-elf)"
	@echo "  ESP_PORT          - Serial port (default: /dev/ttyUSB0)"
	@echo "  ESP_BAUD          - Baud rate (default: 115200)"

.DEFAULT_GOAL := all