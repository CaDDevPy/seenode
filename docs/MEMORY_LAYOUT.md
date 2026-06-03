# Mapa de Memória do ESP32 RTOS

## Visão Geral da Memória

O ESP32 possui várias regiões de memória com características diferentes:

```
┌─────────────────────────────────────────────────────────────┐
│                   ESP32 Memory Map                          │
├─────────────────────────────────────────────────────────────┤
│ 0x00000000 - 0x3FFAC000                                    │
│  Espaço de Endereços Vazio                                 │
├─────────────────────────────────────────────────────────────┤
│ 0x3FFAC000 - 0x3FFB0000  [16 KB]                           │
│  Kernel Data & TCB                                         │
├─────────────────────────────────────────────────────────────┤
│ 0x3FFB0000 - 0x3FFFC000  [300 KB aprox]                    │
│  Task Stacks & Heap                                        │
├─────────────────────────────────────────────────────────────┤
│ 0x3FFFC000 - 0x40000000  [16 KB]                           │
│  RTC Fast Memory                                           │
├─────────────────────────────────────────────────────────────┤
│ 0x40000000 - 0x40070000  [448 KB]                          │
│  Instruction ROM (IROM)                                    │
├─────────────────────────────────────────────────────────────┤
│ 0x60000000 - 0x60007000  [28 KB]                           │
│  Periféricos (UART, GPIO, Timer, etc)                      │
└─────────────────────────────────────────────────────────────┘
```

## Regiões Detalhadas

### 1. Kernel Data (0x3FFAC000 - 0x3FFB0000)

**Tamanho:** 16 KB (16,384 bytes)

**Uso:**

```
0x3FFAC000: Task Control Block Table
├─ TCB[0]: 0x3FFAC000 - 0x3FFAC080 (128 bytes)
├─ TCB[1]: 0x3FFAC080 - 0x3FFAC100 (128 bytes)
├─ TCB[2]: 0x3FFAC100 - 0x3FFAC180 (128 bytes)
└─ TCB[3]: 0x3FFAC180 - 0x3FFAC200 (128 bytes)
           (Total: 512 bytes)

0x3FFAC200: Scheduler State
├─ current_task_id:     uint32_t (4 bytes)
├─ next_task_id:        uint32_t (4 bytes)
├─ task_queue_head:     uint32_t (4 bytes)
├─ task_queue_tail:     uint32_t (4 bytes)
├─ timer_ticks:         uint32_t (4 bytes)
└─ interrupt_mask:      uint32_t (4 bytes)
           (Total: 24 bytes)

0x3FFAC300: Driver State
├─ UART State:         (32 bytes)
├─ GPIO State:         (32 bytes)
└─ Timer State:        (32 bytes)
           (Total: 96 bytes)

0x3FFAC400: Free space (~15 KB)
```

### 2. Task Stacks (0x3FFB0000 - 0x3FFFC000)

**Tamanho:** ~300 KB

**Distribuição (para 4 tarefas):**

```
Task 0 Stack:
├─ Start:   0x3FFB0000
├─ Size:    16 KB (0x4000)
└─ End:     0x3FFB4000 (grow downward from this addr)

Task 1 Stack:
├─ Start:   0x3FFB4000
├─ Size:    16 KB (0x4000)
└─ End:     0x3FFB8000

Task 2 Stack:
├─ Start:   0x3FFB8000
├─ Size:    16 KB (0x4000)
└─ End:     0x3FFBC000

Task 3 Stack:
├─ Start:   0x3FFBC000
├─ Size:    16 KB (0x4000)
└─ End:     0x3FFC0000

Heap:
├─ Start:   0x3FFC0000
├─ Size:    ~252 KB
└─ End:     0x3FFFBFFF
```

**Stack Layout (cada tarefa - crescimento descendente):**

```
[Topo da Stack] 0x3FFB4000
├─ Local Variables
├─ Saved Registers (a2-a15, SR, PC)
├─ Function Call Frames
└─ [Stack Pointer (SP)] ← a1

... espaço livre ...

[Base da Stack] 0x3FFB0000
```

### 3. RTC Fast Memory (0x3FFFC000 - 0x40000000)

**Tamanho:** 16 KB

**Uso:**
- Dados que permanecem durante deep sleep
- Não usado nesta implementação básica

### 4. IROM (0x40000000 - 0x40070000)

**Tamanho:** 448 KB

**Conteúdo:**
- Código do kernel (bootloader, scheduler, drivers)
- Tabelas de ISR
- Strings de debug/log
- Constantes

### 5. Periféricos (0x60000000 - 0x60007000)

**UART0:** 0x60000000 - 0x60000100
**GPIO:** 0x60004000 - 0x60004100
**Timer:** 0x6001F000 - 0x6001F100

## Estrutura de TCB (Task Control Block)

**Tamanho Total:** 128 bytes por tarefa

```c
struct TCB_t {
    // Offset 0x00
    uint32_t task_id;              // ID da tarefa (0-3)
    
    // Offset 0x04
    uint32_t state;                // Estado: SUSPENDED(0), READY(1), RUNNING(2), BLOCKED(3)
    
    // Offset 0x08
    uint32_t stack_pointer;        // SP (a1 quando tarefa foi suspensa)
    
    // Offset 0x0C
    uint32_t program_counter;      // PC (a0 quando tarefa foi suspensa)
    
    // Offset 0x10-0x4C (Registradores)
    uint32_t reg_a2;               // Offset 0x10
    uint32_t reg_a3;               // Offset 0x14
    uint32_t reg_a4;               // Offset 0x18
    uint32_t reg_a5;               // Offset 0x1C
    uint32_t reg_a6;               // Offset 0x20
    uint32_t reg_a7;               // Offset 0x24
    uint32_t reg_a8;               // Offset 0x28
    uint32_t reg_a9;               // Offset 0x2C
    uint32_t reg_a10;              // Offset 0x30
    uint32_t reg_a11;              // Offset 0x34
    uint32_t reg_a12;              // Offset 0x38
    uint32_t reg_a13;              // Offset 0x3C
    uint32_t reg_a14;              // Offset 0x40
    uint32_t reg_a15;              // Offset 0x44
    
    // Offset 0x48
    uint32_t status_register;      // SR (Status Register)
    
    // Offset 0x4C
    uint32_t stack_base;           // Base (topo) da stack da tarefa
    
    // Offset 0x50
    uint32_t priority;             // Prioridade (0-31, maior = mais importante)
    
    // Offset 0x54
    uint32_t time_slice;           // Ticks de tempo para Round-Robin
    
    // Offset 0x58-0x7F
    uint32_t reserved[10];         // Espaço reservado para futura expansão
}; // Total: 128 bytes
```

## Alocação de Stack por Tarefa

### Cálculo de Endereços

```python
BASE_TASK_STACK = 0x3FFB0000
STACK_PER_TASK = 0x4000  # 16 KB

for task_id in range(4):
    stack_base = BASE_TASK_STACK + (task_id * STACK_PER_TASK)
    stack_top = stack_base + STACK_PER_TASK
    print(f"Task {task_id}: 0x{stack_base:08X} - 0x{stack_top:08X}")

# Saída:
# Task 0: 0x3FFB0000 - 0x3FFB4000
# Task 1: 0x3FFB4000 - 0x3FFB8000
# Task 2: 0x3FFB8000 - 0x3FFBC000
# Task 3: 0x3FFBC000 - 0x3FFC0000
```

## Diretrizes de Linkagem

No arquivo `src/boot/linker.ld`:

```ld
MEMORY {
    IROM (rx)  : ORIGIN = 0x40000000, LENGTH = 448K
    SRAM (rwx) : ORIGIN = 0x3FFAC000, LENGTH = 340K
    RTC  (rw)  : ORIGIN = 0x3FFFC000, LENGTH = 16K
}

SECTIONS {
    .init :
    {
        *(.init .init.*)
    } > SRAM
    
    .text :
    {
        *(.text .text.*)
    } > IROM
    
    .data :
    {
        *(.data .data.*)
    } > SRAM
    
    .bss :
    {
        *(.bss .bss.*)
    } > SRAM
}
```

## Considerações Importantes

1. **Stack Growth:** Stacks crescem para baixo (endereços decrescentes)
2. **Proteção:** Sem proteção de buffer overflow (seria necessário watchdog)
3. **Heap:** Alocação dinâmica pode fragmentar memória
4. **Cache:** IROM usa cache de instrução para melhor performance

---

Para consultas sobre layout de memória específico, revise os constantes em `src/utils/constants.s`