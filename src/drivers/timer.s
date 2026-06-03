; ============================================================================
; ESP32 RTOS - Timer Driver
; Arquivo: src/drivers/timer.s
; Descrição: Driver de Timer para ESP32 com suporte a preempção
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .kernel, "ax"
    .global timer_init
    .global timer_start
    .global timer_stop
    .global timer_set_period
    .global timer_get_counter
    .global timer_isr
    .global timer_tick
    .align 4

; ============================================================================
; Constantes - Timer (Base: 0x6001F000)
; ============================================================================

TIMER_BASE              = 0x6001F000

; Registradores TIMER_GROUP_0
TIMER_T0_LOAD           = 0x00          ; Load value
TIMER_T0_COUNT          = 0x04          ; Counter value
TIMER_T0_CTRL           = 0x08          ; Control register
TIMER_T0_ALARM          = 0x0C          ; Alarm value
TIMER_T0_SAMPLE         = 0x14          ; Sample register

TIMER_T1_LOAD           = 0x18          ; Load value
TIMER_T1_COUNT          = 0x1C          ; Counter value
TIMER_T1_CTRL           = 0x20          ; Control register
TIMER_T1_ALARM          = 0x24          ; Alarm value
TIMER_T1_SAMPLE         = 0x2C          ; Sample register

TIMER_INT_ST            = 0x34          ; Interrupt status
TIMER_INT_ENA           = 0x38          ; Interrupt enable
TIMER_INT_CLR           = 0x3C          ; Interrupt clear
TIMER_STATUS            = 0x40          ; Status
TIMER_HI                = 0x44          ; High 32 bits
TIMER_LO                = 0x48          ; Low 32 bits

; Bits de Controle (CTRL register)
TIMER_ENABLE            = (1 << 31)     ; Enable/Disable
TIMER_DIVIDER           = 16            ; Prescaler (2-65536)
TIMER_AUTORELOAD        = (1 << 29)     ; Auto reload on alarm
TIMER_INCREASE          = (1 << 30)     ; Direction
TIMER_ALARM_EN          = (1 << 10)     ; Alarm enable

; Constantes de Timer
TIMER_CLK_FREQ          = 80000000      ; 80 MHz (APB clock)
TIMER_PRESCALER         = 80            ; Prescaler padrão para 1 MHz
TIMER_PERIOD_MS         = 10            ; 10 ms period for preemption

; ============================================================================
; Timer State Structure (armazenado em 0x3FFAC320)
; ============================================================================

TIMER_STATE_BASE        = 0x3FFAC320
TIMER_INITIALIZED       = 0x00
TIMER_RUNNING           = 0x04
TIMER_PERIOD_US         = 0x08
TIMER_INTERRUPT_COUNT   = 0x0C
TIMER_ISR_HANDLER       = 0x10

; ============================================================================
; timer_init - Inicializar Timer
; Parâmetro: a2 = período em microsegundos (opcional, padrão 10000 = 10ms)
; ============================================================================

timer_init:
    entry a1, 32
    
    ; Se a2 == 0, usar padrão
    beqi a2, 0, timer_init_default
    mov a10, a2
    j timer_init_config
    
timer_init_default:
    ; Período padrão: 10 ms = 10000 us
    movi a10, 10000
    
timer_init_config:
    ; Base do Timer
    movi a3, TIMER_BASE
    
    ; ========== Configurar Prescaler ==========
    ; Prescaler = 80 (80 MHz -> 1 MHz)
    movi a4, 0x00000000
    ori a4, a4, (TIMER_PRESCALER & 0xFF)  ; 8 bits prescaler
    s32i a4, a3, TIMER_T0_CTRL
    
    ; ========== Calcular valor de alarme ==========
    ; alarm_value = (período_us * 1MHz) / prescaler
    ; alarm_value = período_us * (1000000 / TIMER_PRESCALER)
    ; = período_us * 1
    
    ; Para simplificar: alarm_value = período_us (já em 1 MHz com prescaler 80)
    s32i a10, a3, TIMER_T0_ALARM
    
    ; ========== Carregar período ==========
    s32i a10, a3, TIMER_T0_LOAD
    
    ; ========== Zerar contador ==========
    s32i a10, a3, TIMER_T0_COUNT
    
    ; ========== Configurar controle ==========
    movi a4, 0x00000000
    ori a4, a4, TIMER_ENABLE        ; Enable
    ori a4, a4, TIMER_AUTORELOAD    ; Auto reload
    ori a4, a4, TIMER_ALARM_EN      ; Alarm enable
    ori a4, a4, TIMER_INCREASE      ; Incremento
    s32i a4, a3, TIMER_T0_CTRL
    
    ; ========== Habilitar interrupções ==========
    ; Limpar interrupções anteriores
    movi a4, 0x01
    s32i a4, a3, TIMER_INT_CLR
    
    ; Habilitar interrupção
    movi a4, 0x01
    s32i a4, a3, TIMER_INT_ENA
    
    ; ========== Inicializar estado ==========
    movi a4, TIMER_STATE_BASE
    
    ; TIMER_INITIALIZED = 1
    movi a5, 1
    s32i a5, a4, TIMER_INITIALIZED
    
    ; TIMER_RUNNING = 0 (iniciará com timer_start)
    movi a5, 0
    s32i a5, a4, TIMER_RUNNING
    
    ; TIMER_PERIOD_US = período
    s32i a10, a4, TIMER_PERIOD_US
    
    ; TIMER_INTERRUPT_COUNT = 0
    s32i a5, a4, TIMER_INTERRUPT_COUNT
    
    retw

; ============================================================================
; timer_start - Iniciar Timer
; ============================================================================

timer_start:
    entry a1, 16
    
    movi a2, TIMER_BASE
    
    ; Ler CTRL
    l32i a3, a2, TIMER_T0_CTRL
    
    ; Setar bit ENABLE
    ori a3, a3, TIMER_ENABLE
    s32i a3, a2, TIMER_T0_CTRL
    
    ; Marcar como RUNNING
    movi a4, TIMER_STATE_BASE
    movi a5, 1
    s32i a5, a4, TIMER_RUNNING
    
    retw

; ============================================================================
; timer_stop - Parar Timer
; ============================================================================

timer_stop:
    entry a1, 16
    
    movi a2, TIMER_BASE
    
    ; Ler CTRL
    l32i a3, a2, TIMER_T0_CTRL
    
    ; Limpar bit ENABLE
    movi a4, ~TIMER_ENABLE
    and a3, a3, a4
    s32i a3, a2, TIMER_T0_CTRL
    
    ; Marcar como parado
    movi a4, TIMER_STATE_BASE
    movi a5, 0
    s32i a5, a4, TIMER_RUNNING
    
    retw

; ============================================================================
; timer_set_period - Alterar período do Timer
; Parâmetro: a2 = novo período em microsegundos
; ============================================================================

timer_set_period:
    entry a1, 16
    
    ; a2 = novo período
    movi a3, TIMER_BASE
    
    ; Parar timer
    call timer_stop
    
    ; Configurar novo período
    movi a3, TIMER_BASE
    s32i a2, a3, TIMER_T0_ALARM
    s32i a2, a3, TIMER_T0_LOAD
    s32i a2, a3, TIMER_T0_COUNT
    
    ; Atualizar estado
    movi a4, TIMER_STATE_BASE
    s32i a2, a4, TIMER_PERIOD_US
    
    ; Reiniciar timer
    call timer_start
    
    retw

; ============================================================================
; timer_get_counter - Obter valor atual do contador
; Retorna: a2 = valor do contador
; ============================================================================

timer_get_counter:
    entry a1, 16
    
    movi a2, TIMER_BASE
    l32i a2, a2, TIMER_T0_COUNT
    
    retw

; ============================================================================
; timer_isr - Interrupt Service Routine do Timer
; ============================================================================

timer_isr:
    entry a1, 32
    
    movi a2, TIMER_BASE
    
    ; Verificar status de interrupção
    l32i a3, a2, TIMER_INT_ST
    
    ; Verificar se é interrupção de timer T0 (bit 0)
    andi a4, a3, 0x01
    beqi a4, 0, timer_isr_done
    
    ; Incrementar contador de interrupções
    movi a5, TIMER_STATE_BASE
    l32i a6, a5, TIMER_INTERRUPT_COUNT
    addi a6, a6, 1
    s32i a6, a5, TIMER_INTERRUPT_COUNT
    
    ; Chamar timer_tick (preemption)
    call timer_tick
    
    ; Limpar interrupção
    movi a3, 0x01
    s32i a3, a2, TIMER_INT_CLR
    
timer_isr_done:
    retw

; ============================================================================
; timer_tick - Handler chamado a cada tick de timer
; ============================================================================

timer_tick:
    entry a1, 16
    
    ; Este é o ponto de preempção
    ; Aqui devemos chamar scheduler.yield() para fazer preempção
    ; Mas é necessário salvar contexto antes
    
    ; TODO: Integrar com scheduler para preempção
    
    retw

; ============================================================================
; Funções Auxiliares
; ============================================================================

; timer_get_period - Obter período configurado
; Retorna: a2 = período em microsegundos

timer_get_period:
    entry a1, 16
    
    movi a2, TIMER_STATE_BASE
    l32i a2, a2, TIMER_PERIOD_US
    
    retw

; timer_get_interrupt_count - Obter contador de interrupções
; Retorna: a2 = número de interrupções ocorridas

timer_get_interrupt_count:
    entry a1, 16
    
    movi a2, TIMER_STATE_BASE
    l32i a2, a2, TIMER_INTERRUPT_COUNT
    
    retw

; timer_reset_interrupt_count - Resetar contador de interrupções

timer_reset_interrupt_count:
    entry a1, 16
    
    movi a2, TIMER_STATE_BASE
    movi a3, 0
    s32i a3, a2, TIMER_INTERRUPT_COUNT
    
    retw

    .end