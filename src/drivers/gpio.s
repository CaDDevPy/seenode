; ============================================================================
; ESP32 RTOS - GPIO Driver
; Arquivo: src/drivers/gpio.s
; Descrição: Driver GPIO para ESP32 com suporte a I/O digital
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .kernel, "ax"
    .global gpio_init
    .global gpio_set_direction
    .global gpio_set_level
    .global gpio_get_level
    .global gpio_toggle
    .global gpio_set_isr
    .global gpio_isr
    .align 4

; ============================================================================
; Constantes - Registradores GPIO (Base: 0x60004000)
; ============================================================================

GPIO_BASE               = 0x60004000

; Registradores GPIO
GPIO_OUT                = 0x04          ; Output level
GPIO_OUT_W1TS           = 0x08          ; Set output (write 1 to set)
GPIO_OUT_W1TC           = 0x0C          ; Clear output (write 1 to clear)
GPIO_ENABLE             = 0x20          ; Output enable
GPIO_ENABLE_W1TS        = 0x24          ; Output enable set
GPIO_ENABLE_W1TC        = 0x28          ; Output enable clear
GPIO_IN                 = 0x3C          ; Input level
GPIO_STATUS             = 0x44          ; Pin status
GPIO_STATUS_W1TS        = 0x48          ; Pin status set
GPIO_STATUS_W1TC        = 0x4C          ; Pin status clear
GPIO_STRAP              = 0x38          ; Strap pins

; Modo de pino
GPIO_INTR_DISABLE       = 0
GPIO_INTR_POSEDGE       = 1
GPIO_INTR_NEGEDGE       = 2
GPIO_INTR_ANYEDGE       = 3
GPIO_INTR_LOLEVEL       = 4
GPIO_INTR_HILEVEL       = 5

; IO_MUX (GPIO Control Registers) - Base: 0x60009000
IO_MUX_BASE             = 0x60009000
IO_MUX_GPIO0            = 0x44          ; GPIO0 control
IO_MUX_STRIDE           = 0x04          ; Intervalo entre registros

; Bits de Controle
FUNC_GPIO               = 2             ; GPIO function select
FUNC_IE                 = 13            ; Input enable
FUNC_OE                 = 12            ; Output enable

; ============================================================================
; GPIO State Structure (armazenado em 0x3FFAC310)
; ============================================================================

GPIO_STATE_BASE         = 0x3FFAC310
GPIO_INITIALIZED        = 0x00
GPIO_CONFIGURED_MASK    = 0x04          ; Bitmap de pinos configurados
GPIO_ISR_HANDLER_PTR    = 0x08          ; Ponteiro para handler ISR
GPIO_INTERRUPT_COUNT    = 0x0C

; ============================================================================
; gpio_init - Inicializar GPIO
; Parâmetros: nenhum
; ============================================================================

gpio_init:
    entry a1, 16
    
    ; Inicializar estado GPIO
    movi a2, GPIO_STATE_BASE
    
    ; GPIO_INITIALIZED = 1
    movi a3, 1
    s32i a3, a2, GPIO_INITIALIZED
    
    ; GPIO_CONFIGURED_MASK = 0 (nenhum pino configurado)
    movi a3, 0
    s32i a3, a2, GPIO_CONFIGURED_MASK
    
    ; GPIO_INTERRUPT_COUNT = 0
    s32i a3, a2, GPIO_INTERRUPT_COUNT
    
    retw

; ============================================================================
; gpio_set_direction - Configurar direção de pino (entrada/saída)
; Parâmetros:
;   a2 = GPIO pin (0-39)
;   a3 = direção (0=entrada, 1=saída)
; ============================================================================

gpio_set_direction:
    entry a1, 24
    
    ; a2 = pin number
    ; a3 = direction (0=input, 1=output)
    
    ; Salvar registradores
    mov a10, a2
    mov a11, a3
    
    ; Calcular máscara: 1 << pin
    movi a4, 1
    ssl a10                 ; Setar shift amount
    sll a4, a4              ; Deslocar para posição correta
    
    ; Base GPIO
    movi a5, GPIO_BASE
    
    ; Verificar direção
    beqi a11, 0, gpio_set_direction_input
    
    ; ========== Saída (Output) ==========
    s32i a4, a5, GPIO_ENABLE_W1TS   ; Setar output enable
    j gpio_set_direction_done
    
    ; ========== Entrada (Input) ==========
gpio_set_direction_input:
    s32i a4, a5, GPIO_ENABLE_W1TC   ; Limpar output enable
    
gpio_set_direction_done:
    ; Atualizar máscara configurado
    movi a2, GPIO_STATE_BASE
    l32i a3, a2, GPIO_CONFIGURED_MASK
    or a3, a3, a4
    s32i a3, a2, GPIO_CONFIGURED_MASK
    
    retw

; ============================================================================
; gpio_set_level - Setar nível de saída (HIGH/LOW)
; Parâmetros:
;   a2 = GPIO pin (0-39)
;   a3 = nível (0=LOW, 1=HIGH)
; ============================================================================

gpio_set_level:
    entry a1, 16
    
    ; a2 = pin number
    ; a3 = level (0=LOW, 1=HIGH)
    
    ; Calcular máscara: 1 << pin
    movi a4, 1
    ssl a2                  ; Setar shift amount
    sll a4, a4              ; Deslocar para posição correta
    
    ; Base GPIO
    movi a5, GPIO_BASE
    
    ; Verificar nível
    beqi a3, 0, gpio_set_level_low
    
    ; ========== HIGH ==========
    s32i a4, a5, GPIO_OUT_W1TS      ; Set bit
    j gpio_set_level_done
    
    ; ========== LOW ==========
gpio_set_level_low:
    s32i a4, a5, GPIO_OUT_W1TC      ; Clear bit
    
gpio_set_level_done:
    retw

; ============================================================================
; gpio_get_level - Ler nível de entrada
; Parâmetro: a2 = GPIO pin (0-39)
; Retorna: a2 = nível (0=LOW, 1=HIGH)
; ============================================================================

gpio_get_level:
    entry a1, 16
    
    ; a2 = pin number
    movi a3, GPIO_BASE
    
    ; Ler GPIO_IN
    l32i a4, a3, GPIO_IN
    
    ; Extrair bit do pin
    sra a4, a4, a2          ; Deslocar bit para posição 0
    andi a2, a4, 0x01       ; Mascarar para 1 bit
    
    retw

; ============================================================================
; gpio_toggle - Alternar estado de pino
; Parâmetro: a2 = GPIO pin (0-39)
; ============================================================================

gpio_toggle:
    entry a1, 16
    
    ; a2 = pin number
    ; Salvar pin
    mov a10, a2
    
    ; Ler nível atual
    call gpio_get_level
    
    ; Inverter
    xori a2, a2, 0x01
    
    ; Recuperar pin e restaurar para a2
    mov a3, a2              ; a3 = novo nível
    mov a2, a10             ; a2 = pin
    
    ; Setar novo nível
    call gpio_set_level
    
    retw

; ============================================================================
; gpio_set_isr - Configurar ISR para pino
; Parâmetros:
;   a2 = GPIO pin (0-39)
;   a3 = tipo de interrupção (0-5)
;   a4 = ponteiro para handler
; ============================================================================

gpio_set_isr:
    entry a1, 32
    
    ; a2 = pin
    ; a3 = intr_type
    ; a4 = handler_ptr
    
    ; TODO: Implementar configuração de ISR
    ; Seria necessário:
    ; 1. Calcular endereço GPIO_INT* para o pin
    ; 2. Configurar tipo de interrupção
    ; 3. Salvar ponteiro do handler em tabela
    ; 4. Habilitar interrupção no GPIO
    
    retw

; ============================================================================
; gpio_isr - Interrupt Service Routine para GPIO
; ============================================================================

gpio_isr:
    entry a1, 32
    
    ; TODO: Implementar handler de interrupção GPIO
    ; Seria necessário:
    ; 1. Ler GPIO_STATUS para identificar qual pino acionou
    ; 2. Chamar handler correspondente
    ; 3. Limpar flag de interrupção
    
    retw

; ============================================================================
; Funções Auxiliares
; ============================================================================

; gpio_set_multiple - Setar múltiplos pinos
; Parâmetros:
;   a2 = máscara de pinos a setar
;   a3 = valores (onde bit=1 -> HIGH, bit=0 -> LOW)

gpio_set_multiple:
    entry a1, 16
    
    ; a2 = mask
    ; a3 = values
    
    movi a4, GPIO_BASE
    
    ; Setar pinos que devem ficar HIGH
    s32i a3, a4, GPIO_OUT_W1TS
    
    ; Limpar pinos que devem ficar LOW
    xor a3, a3, a2          ; Inverter dentro da máscara
    s32i a3, a4, GPIO_OUT_W1TC
    
    retw

; gpio_read_multiple - Ler múltiplos pinos
; Parâmetro: a2 = máscara de pinos a ler
; Retorna: a2 = valores lidos

gpio_read_multiple:
    entry a1, 16
    
    ; a2 = mask
    movi a3, GPIO_BASE
    
    ; Ler GPIO_IN
    l32i a4, a3, GPIO_IN
    
    ; Mascarar resultado
    and a2, a4, a2
    
    retw

; gpio_clear_all - Limpar todos os pinos de saída

gpio_clear_all:
    entry a1, 16
    
    movi a2, GPIO_BASE
    movi a3, 0xFFFFFFFF    ; Máscara para todos os 32 pinos
    
    s32i a3, a2, GPIO_OUT_W1TC   ; Limpar todos
    
    retw

; gpio_set_all - Setar todos os pinos de saída

gpio_set_all:
    entry a1, 16
    
    movi a2, GPIO_BASE
    movi a3, 0xFFFFFFFF    ; Máscara para todos os 32 pinos
    
    s32i a3, a2, GPIO_OUT_W1TS   ; Setar todos
    
    retw

    .end