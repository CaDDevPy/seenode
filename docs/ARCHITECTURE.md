# Arquitetura do ESP32 RTOS

## Visão Geral

Este documento descreve a arquitetura e design do Sistema Operacional em tempo real (RTOS) desenvolvido em Assembly Xtensa para o ESP32.

## Componentes Principais

### 1. Bootloader

**Localização:** `src/boot/bootloader.s`

O bootloader é responsável por:
- Inicializar registradores gerais (a0-a15)
- Configurar Stack Pointer (SP)
- Inicializar periféricos essenciais
- Preparar a tabela de tarefas
- Ativar interrupções
- Saltar para a primeira tarefa

**Fluxo de Execução:**
```
_start
  ↓
Zerar Registradores
  ↓
Configurar SP
  ↓
init_peripherals()
  ↓
init_task_table()
  ↓
uart_init()
  ↓
gpio_init()
  ↓
timer_init()
  ↓
enable_interrupts()
  ↓
start_first_task()
```

### 2. Escalonador (Scheduler)

**Localização:** `src/kernel/scheduler.s`

O escalonador implementa algoritmo **Round-Robin** com as seguintes características:

#### Estrutura da Tabela de Controle de Tarefas (TCB)

```c
struct TCB {
    uint32_t task_id;        // +0x00
    uint32_t state;          // +0x04 (SUSPENDED, READY, RUNNING, BLOCKED)
    uint32_t sp;             // +0x08 (Stack Pointer)
    uint32_t pc;             // +0x0C (Program Counter)
    uint32_t regs[14];       // +0x10 (a2-a15)
    uint32_t priority;       // +0x50
    uint32_t time_slice;     // +0x54
}; // Total: ~128 bytes
```

#### Estados de Tarefa

- **SUSPENDED (0):** Tarefa não está na fila de pronta
- **READY (1):** Tarefa está pronta para executar
- **RUNNING (2):** Tarefa está executando no momento
- **BLOCKED (3):** Tarefa aguardando por um evento

#### Algoritmo Round-Robin

1. Tarefa em execução consome seu time slice
2. Ao fim do time slice (gerado por interrupção de timer), o scheduler é invocado
3. Contexto da tarefa atual é salvo
4. Próxima tarefa READY é restaurada
5. Execução continua

### 3. Context Switch

**Localização:** `src/kernel/context_switch.s`

#### Save Context

```assembly
save_context:
    ; Assumindo a0 = ponteiro TCB, a1 = SP
    s32i a1, a0, 0x08      ; Salvar SP
    s32i a2, a0, 0x10      ; Salvar a2
    s32i a3, a0, 0x14      ; Salvar a3
    ; ... (a4-a15)
```

#### Restore Context

```assembly
restore_context:
    ; Assumindo a0 = ponteiro TCB
    l32i a1, a0, 0x08      ; Restaurar SP
    l32i a2, a0, 0x10      ; Restaurar a2
    l32i a3, a0, 0x14      ; Restaurar a3
    ; ... (a4-a15)
    l32i a15, a0, 0x4C     ; Restaurar PC (a15 já pode ter PC ou usar l32i a0)
```

### 4. Manipulador de Interrupções (ISR)

**Localização:** `src/kernel/isr.s`

#### Interrupções Suportadas

- **Timer Interrupt (Level 1):** Preempção de tarefas
- **UART Interrupt (Level 1):** Recepção/Transmissão de dados
- **GPIO Interrupt (Edge 0):** Detecção de eventos de GPIO

#### Estrutura ISR Genérica

```assembly
generic_isr:
    ; Salvar contexto mínimo (a0, a1, SR)
    ; Determinar qual periférico causou interrupção
    ; Chamar handler específico
    ; Restaurar contexto
    reti
```

### 5. Drivers

#### UART Driver (`src/drivers/uart.s`)

**Funções:**
- `uart_init()` - Inicializar UART0
- `uart_putchar(char)` - Enviar caractere
- `uart_puts(string)` - Enviar string
- `uart_getchar()` - Receber caractere

**Registradores UART0 (Base: 0x60000000):**
```
0x00: FIFO (RX/TX)
0x04: INT_RAW
0x08: INT_ST
0x0C: INT_ENA
0x10: INT_CLR
0x14: CLKDIV
0x18: AUTOBAUD
0x1C: STATUS
0x20: CONF0
0x24: CONF1
```

#### GPIO Driver (`src/drivers/gpio.s`)

**Funções:**
- `gpio_init()` - Inicializar GPIO
- `gpio_set_direction(pin, direction)` - Configurar pino como I/O
- `gpio_set(pin)` - Setar pino HIGH
- `gpio_clear(pin)` - Limpar pino (LOW)
- `gpio_toggle(pin)` - Alternar estado
- `gpio_read(pin)` - Ler valor do pino

**Registradores GPIO (Base: 0x60004000):**
```
0x00-0x04: GPIO_OUT (OUTPUT LEVEL)
0x08: GPIO_OUT_W1TS (SET)
0x0C: GPIO_OUT_W1TC (CLEAR)
0x10-0x14: GPIO_IN (INPUT LEVEL)
0x20-0x24: GPIO_ENABLE
```

#### Timer Driver (`src/drivers/timer.s`)

**Funções:**
- `timer_init(period_us)` - Inicializar timer
- `timer_start()` - Iniciar timer
- `timer_stop()` - Parar timer
- `timer_isr()` - Handler de interrupção de timer

**Registradores Timer (Base: 0x6001F000):**
```
0x00: TIMER_LOAD
0x04: TIMER_COUNT
0x08: TIMER_CTRL
0x0C: TIMER_INT_ST
0x10: TIMER_INT_ENA
```

## Mapa de Memória

```
0x00000000 - 0x3FFAC000: Espaço vazio

0x3FFAC000 - 0x3FFB0000: Kernel Data (16 KB)
  - Tabela de Tarefas (TCB)
  - Variáveis globais
  - Filas de eventos

0x3FFB0000 - 0x3FFFC000: Task Stacks (300 KB aprox)
  - Task 0: 0x3FFB0000 - 0x3FFB4000 (16 KB)
  - Task 1: 0x3FFB4000 - 0x3FFB8000 (16 KB)
  - Task 2: 0x3FFB8000 - 0x3FFBC000 (16 KB)
  - Task 3: 0x3FFBC000 - 0x3FFC0000 (16 KB)
  - Heap:   0x3FFC0000 - 0x3FFFC000

0x3FFFC000 - 0x40000000: RTC Fast Memory (16 KB)

0x40000000 - 0x40070000: IROM (Instruction ROM)

0x60000000 - 0x60007000: Periféricos (UART, GPIO, etc)
```

## Fluxo de Execução

### Inicialização

```
_start (Bootloader)
  └─→ init_peripherals()
  └─→ init_task_table()
  └─→ uart_init()
  └─→ gpio_init()
  └─→ timer_init()
  └─→ enable_interrupts()
  └─→ start_first_task()
      └─→ Task 0 executa
```

### Context Switch Cooperativo (Yield)

```
Task A executa
  └─→ yield() chamado
      └─→ save_context(Task A)
      └─→ next_task = scheduler.get_next_ready()
      └─→ restore_context(next_task)
          └─→ Task B executa
```

### Context Switch Preemptivo (Interrupção de Timer)

```
Task A executa
  └─→ Timer expira
      └─→ timer_isr() ativada
          └─→ save_context(Task A)
          └─→ next_task = scheduler.get_next_ready()
          └─→ restore_context(next_task)
              └─→ Task B executa
```

## Considerações de Design

### Por que Assembly Xtensa?

1. **Controle Total:** Acesso direto a registradores e hardware
2. **Performance:** Sem overhead de C/C++
3. **Real-time:** Timing determinístico
4. **Educacional:** Compreender baixo nível de SO

### Limitações

1. **Multicore:** Implementação atual usa apenas 1 núcleo
2. **Proteção de Memória:** Sem MMU (Memory Management Unit)
3. **Escalabilidade:** Máximo de tarefas limitado pelo TCB

### Melhorias Futuras

1. Sincronização de tarefas (mutex, semáforo)
2. Gerenciamento dinâmico de memória
3. Suporte multicore
4. Proteção de seção crítica
5. Power management

---

Para mais detalhes, consulte os comentários no código-fonte de cada módulo.