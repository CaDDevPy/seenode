# ESP32 RTOS em Assembly Xtensa

Um Sistema Operacional em tempo real (RTOS) minimalista desenvolvido em **Assembly Xtensa** para o microcontrolador **ESP32**, demonstrando arquitetura de SO embarcado com escalonamento de tarefas, manipulação de interrupções e drivers de periféricos.

## 📋 Características

- ✅ Bootloader customizado
- ✅ Gerenciador de tarefas (escalonador cooperativo/preemptivo)
- ✅ Manipulação de interrupções
- ✅ Context switching com salva/restaura de registradores
- ✅ Driver UART para debug
- ✅ Driver GPIO
- ✅ Timer do sistema
- ✅ Tabela de Controle de Tarefas (TCB)

## 🏗️ Estrutura do Projeto

```
esp32-rtos-assembly/
├── docs/
│   ├── ARCHITECTURE.md          # Arquitetura detalhada do SO
│   ├── MEMORY_LAYOUT.md         # Mapa de memória do ESP32
│   └── XTENSA_ISA.md            # Referência da Arquitetura Xtensa
├── src/
│   ├── boot/
│   │   ├── bootloader.s         # Inicialização e setup
│   │   └── linker.ld            # Script de linkagem
│   ├── kernel/
│   │   ├── kernel.s             # Núcleo do SO
│   │   ├── scheduler.s          # Escalonador de tarefas
│   │   ├── context_switch.s     # Context switching
│   │   └── isr.s                # Handlers de interrupção
│   ├── drivers/
│   │   ├── uart.s               # Driver UART
│   │   ├── gpio.s               # Driver GPIO
│   │   └── timer.s              # Driver Timer
│   ├── tasks/
│   │   ├── task_template.s      # Template de tarefa
│   │   └── demo_tasks.s         # Tarefas de demonstração
│   └── utils/
│       ├── macros.s             # Macros úteis
│       └── constants.s          # Constantes do sistema
├── build/
│   └── Makefile                 # Build configuration
├── docs/
│   └── EXAMPLES.md              # Exemplos de uso
└── README.md                    # Este arquivo
```

## 🚀 Quick Start

### Pré-requisitos

- Toolchain Xtensa ESP32 (xtensa-esp32-elf)
- ESP-IDF (opcional, para referência)
- esptool.py (para upload)
- GNU Make

### Compilação

```bash
cd build
make all
```

### Upload para ESP32

```bash
make flash
```

### Monitor Serial

```bash
make monitor
```

## 📚 Documentação

### Componentes Principais

#### 1. **Bootloader** (`src/boot/bootloader.s`)
- Inicializa stack pointer
- Configura cache e clocks
- Inicializa memória RAM
- Salta para o kernel

#### 2. **Scheduler** (`src/kernel/scheduler.s`)
- Mantém lista de tarefas
- Implementa algoritmo Round-Robin
- Gerencia transições de estados de tarefas

#### 3. **Context Switch** (`src/kernel/context_switch.s`)
- Salva registradores da tarefa atual
- Restaura registradores da próxima tarefa
- Atualiza stack pointer

#### 4. **Drivers**
- UART: Transmissão e recepção de dados
- GPIO: Controle de pinos
- Timer: Geração de interrupções para preempção

## 🔧 Arquitetura do Sistema

### Mapa de Memória

```
0x40000000 - 0x40070000:  Cache/Flash
0x3F800000 - 0x3FA00000:  SRAM (Externa)
0x3FFAC000 - 0x40000000:  SRAM (Interna)
                          ├─ Kernel
                          ├─ Tabela de Tarefas
                          ├─ Task Stacks
                          └─ Heap (livre)
```

### Tabela de Controle de Tarefas (TCB)

```
TCB: 
  +0x00: Task ID
  +0x04: State (READY, RUNNING, BLOCKED, SUSPENDED)
  +0x08: Stack Pointer (SP)
  +0x0C: Program Counter (PC)
  +0x10: Registradores (a2-a15)
  +0x50: Priority
  +0x54: Time Slice
```

## 📖 Exemplos de Uso

### Criando uma Tarefa

```assembly
task_led_blink:
    ; Toggle LED a cada iteração
    movi a2, GPIO_PORT
    l32i a3, a2, GPIO_OUT_OFFSET
    xori a3, a3, (1 << LED_PIN)
    s32i a3, a2, GPIO_OUT_OFFSET
    
    ; Yield para próxima tarefa
    call yield
    jx a0
```

Veja mais exemplos em [EXAMPLES.md](docs/EXAMPLES.md)

## 🔗 Referências

- [ESP32 Technical Reference Manual](https://www.espressif.com/en/products/hardware/esp32/resources)
- [Xtensa ISA Reference](https://www.cadence.com/content/dam/cadence-www/global/en_US/documents/tools/ip/tensilica/Xtensa_Instruction_Set_Architecture.pdf)
- [ESP-IDF Documentation](https://docs.espressif.com/projects/esp-idf/)

## 📝 Licença

MIT License - veja LICENSE para detalhes

## 👨‍💻 Autor

Desenvolvido por CaDDevPy como exercício de Arquitetura de Sistemas Operacionais.

---

**Status:** Em Desenvolvimento 🚧

Contribuições e feedback são bem-vindos!
