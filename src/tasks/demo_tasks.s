; ============================================================================
; ESP32 RTOS - Tarefas de Demonstração
; Arquivo: src/tasks/demo_tasks.s
; Descrição: Exemplos práticos de tarefas do RTOS
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .tasks, "ax"
    .global task_led_blink
    .global task_uart_monitor
    .global task_gpio_button
    .global task_idle
    .align 4

; ============================================================================
; Constantes
; ============================================================================

GPIO_LED_PIN            = 2             ; LED no GPIO2
GPIO_BUTTON_PIN         = 0             ; Botão no GPIO0
LED_TOGGLE_COUNT        = 1000000       ; Iterações antes de toggle
UART_LOG_PERIOD         = 2000000       ; Iterações entre logs

; Endereços de periféricos
GPIO_BASE               = 0x60004000
UART_BASE               = 0x60000000
TIMER_BASE              = 0x6001F000

; Offsets GPIO
GPIO_OUT_W1TS           = 0x08
GPIO_OUT_W1TC           = 0x0C
GPIO_IN                 = 0x3C

; Offsets UART
UART_FIFO               = 0x00
UART_STATUS             = 0x1C

; ============================================================================
; Task 0: LED Blink - Pisca LED no GPIO2 a cada período
; ============================================================================

task_led_blink:
    entry a1, 32
    
    ; Inicializar contador
    movi a10, 0             ; a10 = contador
    movi a11, 0             ; a11 = estado LED (0=LOW, 1=HIGH)
    
    ; Configurar GPIO2 como saída
    movi a2, GPIO_LED_PIN
    movi a3, 1              ; output mode
    call gpio_set_direction
    
task_led_blink_loop:
    ; Incrementar contador
    addi a10, a10, 1
    
    ; Verificar se deve fazer toggle
    movi a12, LED_TOGGLE_COUNT
    blt a10, a12, task_led_blink_loop  ; Continuar se contador < threshold
    
    ; Reset contador
    movi a10, 0
    
    ; Toggle LED
    movi a2, GPIO_LED_PIN
    call gpio_toggle
    
    ; Log via UART
    movi a2, UART_BASE
    l32i a3, a2, UART_STATUS
    
    ; Enviar mensagem de status
    movi a2, msg_led_on
    call uart_puts
    
    ; Yield para próxima tarefa
    call scheduler_yield
    
    ; Continuar loop
    j task_led_blink_loop

; ============================================================================
; Task 1: UART Monitor - Log periódico no console serial
; ============================================================================

task_uart_monitor:
    entry a1, 32
    
    ; Inicializar contador
    movi a10, 0             ; a10 = contador
    movi a11, 0             ; a11 = contador de logs
    
task_uart_monitor_loop:
    ; Incrementar contador
    addi a10, a10, 1
    
    ; Verificar se deve fazer log
    movi a12, UART_LOG_PERIOD
    blt a10, a12, task_uart_monitor_loop
    
    ; Reset contador
    movi a10, 0
    
    ; Incrementar contador de logs
    addi a11, a11, 1
    
    ; Imprimir linha de status
    movi a2, msg_monitor_header
    call uart_puts
    
    ; Enviar contador de logs
    movi a2, msg_monitor_count
    call uart_puts
    
    mov a2, a11
    call uart_print_hex
    
    ; Enviar nova linha
    movi a2, msg_newline
    call uart_puts
    
    ; Ler contador de interrupções de timer
    movi a2, TIMER_BASE
    l32i a2, a2, 0x3C      ; TIMER_STATUS (aproximado)
    
    ; Enviar informação de timer
    movi a2, msg_timer_info
    call uart_puts
    
    ; Yield para próxima tarefa
    call scheduler_yield
    
    ; Continuar loop
    j task_uart_monitor_loop

; ============================================================================
; Task 2: GPIO Button Monitor - Monitora botão no GPIO0
; ============================================================================

task_gpio_button:
    entry a1, 32
    
    ; Inicializar estado do botão
    movi a10, 0             ; a10 = estado anterior
    movi a11, 0             ; a11 = contador de pressionamentos
    movi a12, 0             ; a12 = debounce counter
    
    ; Configurar GPIO0 como entrada
    movi a2, GPIO_BUTTON_PIN
    movi a3, 0              ; input mode
    call gpio_set_direction
    
task_gpio_button_loop:
    ; Ler estado do botão
    movi a2, GPIO_BUTTON_PIN
    call gpio_get_level
    ; a2 = estado atual (0 ou 1)
    
    ; Verificar mudança de estado (debounce simples)
    bne a2, a10, task_gpio_button_state_changed
    
    ; Estado não mudou
    movi a12, 0             ; Reset debounce counter
    j task_gpio_button_loop
    
task_gpio_button_state_changed:
    ; Incrementar debounce counter
    addi a12, a12, 1
    
    ; Verificar se debounce é válido (após ~100 leituras)
    movi a13, 100
    blt a12, a13, task_gpio_button_loop
    
    ; Mudança confirmada
    mov a10, a2
    movi a12, 0
    
    ; Se estado = LOW (botão pressionado)
    beqi a2, 0, task_gpio_button_pressed
    
    ; Estado = HIGH (botão solto)
    movi a2, msg_button_released
    call uart_puts
    j task_gpio_button_continue
    
task_gpio_button_pressed:
    ; Incrementar contador
    addi a11, a11, 1
    
    ; Log de pressionamento
    movi a2, msg_button_pressed
    call uart_puts
    
    ; Enviar número de pressionamentos
    movi a2, msg_press_count
    call uart_puts
    
    mov a2, a11
    call uart_print_hex
    
    movi a2, msg_newline
    call uart_puts
    
task_gpio_button_continue:
    ; Yield para próxima tarefa
    call scheduler_yield
    
    ; Continuar loop
    j task_gpio_button_loop

; ============================================================================
; Task 3: IDLE - Tarefa ociosa (executada quando nenhuma outra está pronta)
; ============================================================================

task_idle:
    entry a1, 16
    
    ; Simples loop vazio com yield periódico
    movi a10, 0
    
task_idle_loop:
    ; Incrementar contador
    addi a10, a10, 1
    
    ; Yield a cada 1000 iterações
    movi a11, 1000
    modu a12, a10, a11
    beqi a12, 0, task_idle_yield
    
    j task_idle_loop
    
task_idle_yield:
    call scheduler_yield
    j task_idle_loop

; ============================================================================
; Task Templates - Templates para criar novas tarefas
; ============================================================================

; ===== Template básico =====
task_template_basic:
    entry a1, 32
    
    ; Inicialização
    movi a10, 0
    
task_template_loop:
    ; Corpo principal
    ; ...
    
    ; Yield obrigatório (cooperativo)
    call scheduler_yield
    
    ; Loop contínuo
    j task_template_loop

; ===== Template com status LED =====
task_template_with_led:
    entry a1, 32
    
    ; Inicialização
    movi a2, GPIO_LED_PIN
    movi a3, 1
    call gpio_set_direction
    
    ; Configurar LED como offline (OFF)
    movi a2, GPIO_LED_PIN
    movi a3, 0
    call gpio_set_level
    
task_template_with_led_loop:
    ; Ligar LED (indicação de atividade)
    movi a2, GPIO_LED_PIN
    movi a3, 1
    call gpio_set_level
    
    ; Processar (simulado com delay)
    movi a10, 100000
    movi a11, 0
task_template_work:
    addi a11, a11, 1
    blt a11, a10, task_template_work
    
    ; Desligar LED
    movi a2, GPIO_LED_PIN
    movi a3, 0
    call gpio_set_level
    
    ; Yield
    call scheduler_yield
    
    j task_template_with_led_loop

; ============================================================================
; Funções Auxiliares de Suporte (Wrappers)
; ============================================================================

; Implementações locais dos drivers se não estiverem ligadas
; (Para demonstração standalone)

gpio_set_direction:
    ; Stub - implementação no driver
    retw

gpio_toggle:
    ; Stub - implementação no driver
    retw

gpio_get_level:
    ; Stub - implementação no driver
    retw

gpio_set_level:
    ; Stub - implementação no driver
    retw

uart_puts:
    ; Stub - implementação no driver
    retw

uart_print_hex:
    ; Stub - implementação no driver
    retw

scheduler_yield:
    ; Stub - implementação no kernel
    retw

; ============================================================================
; Strings de Mensagens
; ============================================================================

    .section .rodata
    .align 4

msg_led_on:
    .string "[LED] Toggle!\r\n"

msg_led_off:
    .string "[LED] OFF\r\n"

msg_monitor_header:
    .string "[MONITOR] Logs: "

msg_monitor_count:
    .string "0x"

msg_timer_info:
    .string " [TIMER] Running\r\n"

msg_button_pressed:
    .string "[BUTTON] Pressed! Count: "

msg_button_released:
    .string "[BUTTON] Released\r\n"

msg_press_count:
    .string "0x"

msg_newline:
    .string "\r\n"

msg_task_start:
    .string "[TASK] Started\r\n"

msg_task_end:
    .string "[TASK] Ended\r\n"

msg_error:
    .string "[ERROR] Task Error!\r\n"

    .end