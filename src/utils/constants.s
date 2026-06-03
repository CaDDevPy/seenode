; ============================================================================
; ESP32 RTOS - Utilitários e Constantes
; Arquivo: src/utils/constants.s
; Descrição: Definições de constantes do sistema
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .rodata
    .align 4

; ============================================================================
; Constantes de Memória
; ============================================================================

; Endereços de Memória
.set SRAM_BASE,                 0x3FFAC000
.set SRAM_SIZE,                 0x54000
.set TCB_BASE,                  0x3FFAC000
.set TCB_SIZE,                  128
.set MAX_TASKS,                 4
.set TASK_STACK_SIZE,           0x4000      ; 16 KB por tarefa
.set TASK_STACK_BASE,           0x3FFB0000

; Estados de Tarefa
.set STATE_SUSPENDED,           0
.set STATE_READY,               1
.set STATE_RUNNING,             2
.set STATE_BLOCKED,             3

; Offsets de TCB
.set TCB_TASK_ID_OFFSET,        0x00
.set TCB_STATE_OFFSET,          0x04
.set TCB_SP_OFFSET,             0x08
.set TCB_PC_OFFSET,             0x0C
.set TCB_REG_A2_OFFSET,         0x10
.set TCB_PRIORITY_OFFSET,       0x50
.set TCB_TIME_SLICE_OFFSET,     0x54

; ============================================================================
; Constantes de Periféricos
; ============================================================================

; UART0
.set UART0_BASE,                0x60000000
.set UART_BAUD_RATE,            115200
.set UART_CLK_FREQ,             80000000    ; 80 MHz
.set UART_PRESCALER,            80

; GPIO
.set GPIO_BASE,                 0x60004000
.set GPIO_LED_PIN,              2
.set GPIO_BUTTON_PIN,           0
.set GPIO_PIN_COUNT,            40

; Timer
.set TIMER_BASE,                0x6001F000
.set TIMER_CLK_FREQ,            80000000    ; 80 MHz
.set TIMER_PRESCALER,           80          ; 1 MHz
.set TIMER_PERIOD_MS,           10          ; 10 ms

; ============================================================================
; Constantes de Drivers
; ============================================================================

; UART State
.set UART_STATE_BASE,           0x3FFAC300
.set UART_INITIALIZED,          0x00
.set UART_RX_ENABLED,           0x04
.set UART_TX_ENABLED,           0x08
.set UART_BAUD_CONF,            0x0C
.set UART_TX_COUNT,             0x10
.set UART_RX_COUNT,             0x14
.set UART_ERROR_COUNT,          0x18

; GPIO State
.set GPIO_STATE_BASE,           0x3FFAC310
.set GPIO_INITIALIZED,          0x00
.set GPIO_CONFIGURED_MASK,      0x04
.set GPIO_ISR_HANDLER_PTR,      0x08
.set GPIO_INTERRUPT_COUNT,      0x0C

; Timer State
.set TIMER_STATE_BASE,          0x3FFAC320
.set TIMER_INITIALIZED,         0x00
.set TIMER_RUNNING,             0x04
.set TIMER_PERIOD_US,           0x08
.set TIMER_INTERRUPT_COUNT,     0x0C
.set TIMER_ISR_HANDLER,         0x10

; Scheduler State
.set SCHED_STATE_BASE,          0x3FFAC200
.set CURRENT_TASK_ID_OFFSET,    0x00
.set NEXT_TASK_ID_OFFSET,       0x04
.set TASK_QUEUE_HEAD_OFFSET,    0x08
.set TASK_QUEUE_TAIL_OFFSET,    0x0C
.set TIMER_TICKS_OFFSET,        0x10
.set INTERRUPT_MASK_OFFSET,     0x14

; ============================================================================
; Constantes de Configuração
; ============================================================================

; Scheduler
.set SCHEDULER_TIME_SLICE,      10          ; Ticks por tarefa
.set SCHEDULER_TICK_MS,         1           ; 1 ms por tick

; Tasks
.set TASK_PRIORITY_LOW,         0
.set TASK_PRIORITY_NORMAL,      10
.set TASK_PRIORITY_HIGH,        20
.set TASK_PRIORITY_CRITICAL,    31

; Debug
.set DEBUG_ENABLED,             1
.set UART_DEBUG_ENABLED,        1
.set LOG_LEVEL_ERROR,           0
.set LOG_LEVEL_WARNING,         1
.set LOG_LEVEL_INFO,            2
.set LOG_LEVEL_DEBUG,           3

; ============================================================================
; Constantes de Interrupção
; ============================================================================

; Níveis de Interrupção Xtensa
.set INTR_LEVEL_0,              0           ; Nível 0 (mask 0x1)
.set INTR_LEVEL_1,              1           ; Nível 1 (mask 0x2)
.set INTR_LEVEL_2,              2           ; Nível 2 (mask 0x4)
.set INTR_LEVEL_3,              3           ; Nível 3 (mask 0x8)
.set INTR_LEVEL_4,              4           ; Nível 4 (mask 0x10)
.set INTR_LEVEL_5,              5           ; Nível 5 (mask 0x20)
.set INTR_LEVEL_6,              6           ; Nível 6 (mask 0x40)

; Tipos de Interrupção GPIO
.set GPIO_INTR_DISABLE,         0
.set GPIO_INTR_POSEDGE,         1
.set GPIO_INTR_NEGEDGE,         2
.set GPIO_INTR_ANYEDGE,         3
.set GPIO_INTR_LOLEVEL,         4
.set GPIO_INTR_HILEVEL,         5

; ============================================================================
; Constantes de Timing
; ============================================================================

; Delays simulados (em iterações)
.set DELAY_1MS,                 80000       ; 1 ms @ 80 MHz
.set DELAY_10MS,                800000      ; 10 ms
.set DELAY_100MS,               8000000     ; 100 ms
.set DELAY_1S,                  80000000    ; 1 s

; Debounce
.set BUTTON_DEBOUNCE_MS,        20          ; 20 ms
.set BUTTON_DEBOUNCE_ITER,      1600000     ; Iterações para 20ms

; ============================================================================
; Constantes de Caracteres
; ============================================================================

.set ASCII_NULL,                0x00
.set ASCII_CR,                  0x0D        ; \r
.set ASCII_LF,                  0x0A        ; \n
.set ASCII_SPACE,               0x20
.set ASCII_0,                   0x30        ; '0'
.set ASCII_9,                   0x39        ; '9'
.set ASCII_A,                   0x41        ; 'A'
.set ASCII_F,                   0x46        ; 'F'
.set ASCII_a,                   0x61        ; 'a'
.set ASCII_f,                   0x66        ; 'f'

; ============================================================================
; Constantes de Teste/Debug
; ============================================================================

; Contadores para teste
.set TEST_COUNTER_1,            0x3FFC0000
.set TEST_COUNTER_2,            0x3FFC0004
.set TEST_COUNTER_3,            0x3FFC0008

; Flags de teste
.set TEST_FLAG_LED,             0x3FFC0100
.set TEST_FLAG_BUTTON,          0x3FFC0104
.set TEST_FLAG_UART,            0x3FFC0108

    .end