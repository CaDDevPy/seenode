; ============================================================================
; ESP32 RTOS - Testes de Drivers
; Arquivo: tests/driver_tests.s
; Descrição: Testes específicos para cada driver
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .tests, "ax"
    .global test_uart_detailed
    .global test_gpio_detailed
    .global test_timer_detailed
    .align 4

; ============================================================================
; UART Detailed Tests
; ============================================================================

test_uart_detailed:
    entry a1, 48
    
    movi a2, msg_uart_detailed_start
    call uart_puts
    
    movi a10, 0             ; Contador de sub-testes
    movi a11, 0             ; Sucessos
    
    ; Sub-teste 1: Inicialização
    movi a2, msg_uart_test_init
    call uart_puts
    
    call uart_init
    
    movi a3, UART_STATE_BASE
    l32i a4, a3, UART_INITIALIZED
    beqi a4, 1, uart_dt_init_ok
    
    movi a2, msg_failed
    call uart_puts
    j uart_dt_putchar_test
    
uart_dt_init_ok:
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 2: Putchar
uart_dt_putchar_test:
    movi a2, msg_uart_test_putchar
    call uart_puts
    
    movi a2, 'T'            ; Enviar 'T'
    call uart_putchar
    
    movi a2, 'E'            ; Enviar 'E'
    call uart_putchar
    
    movi a2, 'S'            ; Enviar 'S'
    call uart_putchar
    
    movi a2, 'T'            ; Enviar 'T'
    call uart_putchar
    
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 3: Puts
    movi a2, msg_uart_test_puts
    call uart_puts
    
    movi a2, msg_test_string
    call uart_puts
    
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 4: Status
    movi a2, msg_uart_test_status
    call uart_puts
    
    movi a3, UART_STATE_BASE
    l32i a2, a3, UART_TX_COUNT
    call uart_print_hex
    
    movi a2, msg_sent
    call uart_puts
    addi a11, a11, 1
    
    retw

; ============================================================================
; GPIO Detailed Tests
; ============================================================================

test_gpio_detailed:
    entry a1, 48
    
    movi a2, msg_gpio_detailed_start
    call uart_puts
    
    movi a10, 0             ; Contador
    movi a11, 0             ; Sucessos
    
    ; Sub-teste 1: Inicialização
    movi a2, msg_gpio_test_init
    call uart_puts
    
    call gpio_init
    
    movi a3, GPIO_STATE_BASE
    l32i a4, a3, GPIO_INITIALIZED
    beqi a4, 1, gpio_dt_init_ok
    
    movi a2, msg_failed
    call uart_puts
    j gpio_dt_direction_test
    
gpio_dt_init_ok:
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 2: Direção
gpio_dt_direction_test:
    movi a2, msg_gpio_test_direction
    call uart_puts
    
    movi a2, 2
    movi a3, 1
    call gpio_set_direction
    
    movi a2, 2
    movi a3, 0
    call gpio_set_direction
    
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 3: Set/Get
    movi a2, msg_gpio_test_setget
    call uart_puts
    
    ; Set HIGH
    movi a2, 2
    movi a3, 1
    call gpio_set_level
    
    ; Get
    movi a2, 2
    call gpio_get_level
    beqi a2, 1, gpio_dt_get_ok
    
    movi a2, msg_failed
    call uart_puts
    j gpio_dt_toggle_test
    
gpio_dt_get_ok:
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 4: Toggle
gpio_dt_toggle_test:
    movi a2, msg_gpio_test_toggle
    call uart_puts
    
    movi a2, 2
    call gpio_toggle
    
    movi a2, 2
    call gpio_get_level
    beqi a2, 0, gpio_dt_toggle_ok
    
    movi a2, msg_failed
    call uart_puts
    j gpio_dt_done
    
gpio_dt_toggle_ok:
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
gpio_dt_done:
    retw

; ============================================================================
; Timer Detailed Tests
; ============================================================================

test_timer_detailed:
    entry a1, 48
    
    movi a2, msg_timer_detailed_start
    call uart_puts
    
    movi a10, 0             ; Contador
    movi a11, 0             ; Sucessos
    
    ; Sub-teste 1: Inicialização
    movi a2, msg_timer_test_init
    call uart_puts
    
    movi a2, 1000           ; 1ms
    call timer_init
    
    movi a3, TIMER_STATE_BASE
    l32i a4, a3, TIMER_INITIALIZED
    beqi a4, 1, timer_dt_init_ok
    
    movi a2, msg_failed
    call uart_puts
    j timer_dt_start_test
    
timer_dt_init_ok:
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 2: Start/Stop
timer_dt_start_test:
    movi a2, msg_timer_test_start
    call uart_puts
    
    call timer_start
    
    l32i a4, a3, TIMER_RUNNING
    beqi a4, 1, timer_dt_start_ok
    
    movi a2, msg_failed
    call uart_puts
    j timer_dt_stop_test
    
timer_dt_start_ok:
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 3: Stop
timer_dt_stop_test:
    movi a2, msg_timer_test_stop
    call uart_puts
    
    call timer_stop
    
    l32i a4, a3, TIMER_RUNNING
    beqi a4, 0, timer_dt_stop_ok
    
    movi a2, msg_failed
    call uart_puts
    j timer_dt_period_test
    
timer_dt_stop_ok:
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    
    ; Sub-teste 4: Get Period
timer_dt_period_test:
    movi a2, msg_timer_test_period
    call uart_puts
    
    l32i a2, a3, TIMER_PERIOD_US
    movi a4, 1000
    bne a2, a4, timer_dt_period_failed
    
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    j timer_dt_done
    
timer_dt_period_failed:
    movi a2, msg_failed
    call uart_puts
    
timer_dt_done:
    retw

; ============================================================================
; Mensagens
; ============================================================================

    .section .rodata
    .align 4

msg_uart_detailed_start:
    .string "\r\n=== UART Detailed Tests ===\r\n"

msg_uart_test_init:
    .string "  Init: "

msg_uart_test_putchar:
    .string "  Putchar: "

msg_uart_test_puts:
    .string "  Puts: "

msg_uart_test_status:
    .string "  TX Count: 0x"

msg_sent:
    .string " bytes sent\r\n  Status: PASSED\r\n"

msg_gpio_detailed_start:
    .string "\r\n=== GPIO Detailed Tests ===\r\n"

msg_gpio_test_init:
    .string "  Init: "

msg_gpio_test_direction:
    .string "  Set Direction: "

msg_gpio_test_setget:
    .string "  Set/Get: "

msg_gpio_test_toggle:
    .string "  Toggle: "

msg_timer_detailed_start:
    .string "\r\n=== Timer Detailed Tests ===\r\n"

msg_timer_test_init:
    .string "  Init: "

msg_timer_test_start:
    .string "  Start: "

msg_timer_test_stop:
    .string "  Stop: "

msg_timer_test_period:
    .string "  Get Period: "

msg_passed:
    .string "PASSED\r\n"

msg_failed:
    .string "FAILED\r\n"

msg_test_string:
    .string "Hello from UART!\r\n"

    .end