; ============================================================================
; ESP32 RTOS - Bootloader
; Arquivo: src/boot/bootloader.s
; Descrição: Código de inicialização do sistema operacional
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .init, "ax"
    .global _start
    .align 4

; Constantes de Endereços de Memória
DRAM0_CACHE_ADDRESS_LOW     = 0x40000000
DRAM0_CACHE_ADDRESS_HIGH    = 0x3FFF0000
IRAM0_ADDRESS_LOW           = 0x40000000
IRAM0_ADDRESS_HIGH          = 0x40070000
SRAM_BASE                   = 0x3FFAC000
SRAM_SIZE                   = 0x54000        ; 340KB

; Constantes de TCB (Task Control Block)
TCB_SIZE                    = 128            ; bytes por tarefa
TCB_BASE                    = 0x3FFAC000     ; Início da tabela TCB
MAX_TASKS                   = 4              ; Número máximo de tarefas

; Endereços de Periféricos
UART0_BASE                  = 0x60000000
GPIO_BASE                   = 0x60004000
TIMER_BASE                  = 0x6001F000
RTC_BASE                    = 0x60008000

; Macros úteis
.macro PUSH_REG reg
    s32i \reg, a1, 0
    addi a1, a1, 4
.endm

.macro POP_REG reg
    addi a1, a1, -4
    l32i \reg, a1, 0
.endm

; ============================================================================
; SEÇÃO: Ponto de Entrada
; ============================================================================

_start:
    ; Limpar registradores
    xor a0, a0, a0
    xor a2, a2, a2
    xor a3, a3, a3
    xor a4, a4, a4
    xor a5, a5, a5
    xor a6, a6, a6
    xor a7, a7, a7
    xor a8, a8, a8
    xor a9, a9, a9
    xor a10, a10, a10
    xor a11, a11, a11
    xor a12, a12, a12
    xor a13, a13, a13
    xor a14, a14, a14
    xor a15, a15, a15

    ; Inicializar stack pointer
    ; Usar topo da SRAM interna
    movi a1, 0x3FFFFFFF    ; SP aponta para topo da RAM
    
    ; Inicializar Window ABI (se necessário para funcionalidade de call)
    movi a12, 0            ; a12 = 0 (alguns kernels usam para PSP)

    ; Chamar rotina de inicialização de periféricos
    call init_peripherals

    ; Inicializar tabela de tarefas
    call init_task_table

    ; Inicializar driver UART para debug
    call uart_init

    ; Inicializar GPIO
    call gpio_init

    ; Inicializar Timer
    call timer_init

    ; Ativar interrupções
    call enable_interrupts

    ; Imprimir mensagem de boot
    movi a2, uart_boot_msg
    call uart_puts

    ; Iniciar primeira tarefa
    call start_first_task

    ; Este ponto não deve ser alcançado
    j _start

; ============================================================================
; SEÇÃO: Inicialização de Periféricos
; ============================================================================

init_peripherals:
    entry a1, 16

    ; Ativar clock da UART
    movi a2, RTC_BASE
    l32i a3, a2, 0x000     ; Ler APB_CTRL_TICK_CONF
    ori a3, a3, 0x1        ; Ativar clocks
    s32i a3, a2, 0x000

    ; Configurar clock do sistema (usar PLL padrão)
    ; O ESP32 bootrom já configura isso, aqui apenas verificamos

    retw

; ============================================================================
; SEÇÃO: Inicialização da Tabela de Tarefas (TCB)
; ============================================================================

init_task_table:
    entry a1, 32
    
    ; a2 = ponteiro para TCB
    movi a2, TCB_BASE
    
    ; a3 = contador (i)
    movi a3, 0
    
    ; a4 = MAX_TASKS
    movi a4, MAX_TASKS
    
init_task_loop:
    ; Verificar se chegamos ao fim
    bgeu a3, a4, init_task_done
    
    ; Inicializar TCB[i]
    ; Offset = i * TCB_SIZE
    muli a5, a3, TCB_SIZE
    add a6, a2, a5
    
    ; Task ID (offset 0x00)
    s32i a3, a6, 0x00
    
    ; State = SUSPENDED (offset 0x04)
    movi a7, 0              ; 0 = SUSPENDED
    s32i a7, a6, 0x04
    
    ; Stack Pointer (offset 0x08) - alocar stack em RAM
    ; Stack[i] = SRAM_BASE + (i+1) * 4KB
    movi a8, 0x1000        ; 4KB por tarefa
    muli a7, a3, 0x1000
    add a7, a7, 0x3FFC0000 ; Base de stack para tarefas
    s32i a7, a6, 0x08
    
    ; Program Counter (offset 0x0C) - será definido quando tarefa for criada
    movi a7, 0
    s32i a7, a6, 0x0C
    
    ; Priority (offset 0x50)
    movi a7, 10             ; Prioridade padrão
    s32i a7, a6, 0x50
    
    ; Próxima iteração
    addi a3, a3, 1
    j init_task_loop
    
init_task_done:
    retw

; ============================================================================
; SEÇÃO: Inicialização UART (stub)
; ============================================================================

uart_init:
    entry a1, 16
    ; TODO: Implementar inicialização de UART
    retw

; ============================================================================
; SEÇÃO: Inicialização GPIO (stub)
; ============================================================================

gpio_init:
    entry a1, 16
    ; TODO: Implementar inicialização de GPIO
    retw

; ============================================================================
; SEÇÃO: Inicialização Timer (stub)
; ============================================================================

timer_init:
    entry a1, 16
    ; TODO: Implementar inicialização de Timer
    retw

; ============================================================================
; SEÇÃO: Habilitar Interrupções
; ============================================================================

enable_interrupts:
    entry a1, 16
    
    ; Lê SR (Shift Register) e seta bit IE (Interrupt Enable)
    rsr a2, sr              ; Ler SR
    ori a2, a2, 0x8         ; Bit 3 = IE (Interrupt Enable)
    wsr a2, sr              ; Escrever SR
    
    retw

; ============================================================================
; SEÇÃO: Iniciar Primeira Tarefa
; ============================================================================

start_first_task:
    entry a1, 16
    
    ; Restaurar primeiro contexto (TCB[0])
    movi a2, TCB_BASE
    call restore_context
    
    ; Não retorna daqui - executa a tarefa
    retw

; ============================================================================
; SEÇÃO: Restaurar Contexto
; ============================================================================

restore_context:
    entry a1, 16
    
    ; a2 = ponteiro para TCB
    
    ; Restaurar SP (Stack Pointer)
    l32i a1, a2, 0x08
    
    ; Restaurar PC (Program Counter)
    l32i a0, a2, 0x0C
    
    ; Restaurar registradores (a2-a15)
    ; (Este exemplo simplifica - em uma implementação real, seriam todos restaurados)
    
    retw

; ============================================================================
; SEÇÃO: Funções de Debug UART
; ============================================================================

uart_puts:
    ; a2 = ponteiro para string
    entry a1, 16
    ; TODO: Implementar função puts
    retw

; ============================================================================
; STRINGS PARA DEBUG
; ============================================================================

    .section .rodata
    
uart_boot_msg:
    .string "ESP32 RTOS Boot - Iniciando Sistema Operacional\r\n"

    .end