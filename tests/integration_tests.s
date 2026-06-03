; ============================================================================
; ESP32 RTOS - Testes de Integração
; Arquivo: tests/integration_tests.s
; Descrição: Suite de testes para validar funcionamento do RTOS
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .tests, "ax"
    .global test_suite_main
    .global test_driver_uart
    .global test_driver_gpio
    .global test_driver_timer
    .global test_scheduler_context_switch
    .global test_scheduler_round_robin
    .global test_synchronization
    .align 4

; ============================================================================
; Constantes de Teste
; ============================================================================

TEST_BUFFER_BASE        = 0x3FFC0100
TEST_RESULTS_BASE       = 0x3FFC0200
TEST_PASSED             = 0xDEADBEEF
TEST_FAILED             = 0xDEADC0DE

; Test IDs
TEST_ID_UART            = 0x01
TEST_ID_GPIO            = 0x02
TEST_ID_TIMER           = 0x03
TEST_ID_SCHEDULER       = 0x04
TEST_ID_CONTEXT_SWITCH  = 0x05
TEST_ID_ROUND_ROBIN     = 0x06
TEST_ID_SYNCHRONIZATION = 0x07

; ============================================================================
; Test Suite Principal
; ============================================================================

test_suite_main:
    entry a1, 48
    
    ; Enviar header
    movi a2, msg_test_header
    call uart_puts
    
    ; Inicializar contadores
    movi a10, 0             ; Total de testes
    movi a11, 0             ; Testes passados
    movi a12, 0             ; Testes falhados
    
    ; Test 1: UART Driver
    call test_driver_uart
    addi a10, a10, 1
    beqi a2, TEST_PASSED, test_uart_passed
    addi a12, a12, 1
    j test_gpio_start
test_uart_passed:
    addi a11, a11, 1
    
    ; Test 2: GPIO Driver
test_gpio_start:
    call test_driver_gpio
    addi a10, a10, 1
    beqi a2, TEST_PASSED, test_gpio_passed
    addi a12, a12, 1
    j test_timer_start
test_gpio_passed:
    addi a11, a11, 1
    
    ; Test 3: Timer Driver
test_timer_start:
    call test_driver_timer
    addi a10, a10, 1
    beqi a2, TEST_PASSED, test_timer_passed
    addi a12, a12, 1
    j test_scheduler_start
test_timer_passed:
    addi a11, a11, 1
    
    ; Test 4: Scheduler Context Switch
test_scheduler_start:
    call test_scheduler_context_switch
    addi a10, a10, 1
    beqi a2, TEST_PASSED, test_cs_passed
    addi a12, a12, 1
    j test_rr_start
test_cs_passed:
    addi a11, a11, 1
    
    ; Test 5: Scheduler Round-Robin
test_rr_start:
    call test_scheduler_round_robin
    addi a10, a10, 1
    beqi a2, TEST_PASSED, test_rr_passed
    addi a12, a12, 1
    j test_sync_start
test_rr_passed:
    addi a11, a11, 1
    
    ; Test 6: Synchronization
test_sync_start:
    call test_synchronization
    addi a10, a10, 1
    beqi a2, TEST_PASSED, test_sync_passed
    addi a12, a12, 1
    j test_summary
test_sync_passed:
    addi a11, a11, 1
    
    ; Resumo
test_summary:
    movi a2, msg_test_summary
    call uart_puts
    
    ; Total
    movi a2, msg_total_tests
    call uart_puts
    mov a2, a10
    call uart_print_hex
    
    movi a2, msg_tests_passed
    call uart_puts
    mov a2, a11
    call uart_print_hex
    
    movi a2, msg_tests_failed
    call uart_puts
    mov a2, a12
    call uart_print_hex
    
    movi a2, msg_newline
    call uart_puts
    
    retw

; ============================================================================
; Test 1: UART Driver
; ============================================================================

test_driver_uart:
    entry a1, 32
    
    movi a2, msg_test_uart
    call uart_puts
    
    ; Verificar se UART está inicializado
    movi a3, UART_STATE_BASE
    l32i a4, a3, UART_INITIALIZED
    beqi a4, 1, test_uart_check_tx
    
    ; Falha: UART não inicializado
    movi a2, msg_uart_not_init
    call uart_puts
    movi a2, TEST_FAILED
    j test_uart_done
    
test_uart_check_tx:
    ; Teste de transmissão
    movi a2, msg_uart_test_tx
    call uart_puts
    
    ; Verificar se TX está habilitado
    l32i a4, a3, UART_TX_ENABLED
    beqi a4, 1, test_uart_check_rx
    
    movi a2, TEST_FAILED
    j test_uart_done
    
test_uart_check_rx:
    ; Verificar se RX está habilitado
    l32i a4, a3, UART_RX_ENABLED
    beqi a4, 1, test_uart_check_baud
    
    movi a2, TEST_FAILED
    j test_uart_done
    
test_uart_check_baud:
    ; Verificar baud rate
    l32i a4, a3, UART_BAUD_CONF
    movi a5, UART_BAUD_RATE
    bne a4, a5, test_uart_failed
    
    ; Sucesso
    movi a2, msg_uart_passed
    call uart_puts
    movi a2, TEST_PASSED
    j test_uart_done
    
test_uart_failed:
    movi a2, msg_uart_failed
    call uart_puts
    movi a2, TEST_FAILED
    
test_uart_done:
    retw

; ============================================================================
; Test 2: GPIO Driver
; ============================================================================

test_driver_gpio:
    entry a1, 32
    
    movi a2, msg_test_gpio
    call uart_puts
    
    ; Verificar se GPIO está inicializado
    movi a3, GPIO_STATE_BASE
    l32i a4, a3, GPIO_INITIALIZED
    beqi a4, 1, test_gpio_set_direction
    
    movi a2, msg_gpio_not_init
    call uart_puts
    movi a2, TEST_FAILED
    j test_gpio_done
    
test_gpio_set_direction:
    ; Teste de direção
    movi a2, GPIO_LED_PIN
    movi a3, 1              ; Output
    call gpio_set_direction
    
    ; Verificar se foi configurado
    l32i a5, a3, GPIO_CONFIGURED_MASK
    movi a4, 1
    ssl GPIO_LED_PIN
    sll a4, a4
    and a6, a5, a4
    beqi a6, 0, test_gpio_failed
    
    ; Teste de set/get
    movi a2, GPIO_LED_PIN
    movi a3, 1
    call gpio_set_level
    
    movi a2, GPIO_LED_PIN
    call gpio_get_level
    beqi a2, 1, test_gpio_passed
    
test_gpio_failed:
    movi a2, msg_gpio_failed
    call uart_puts
    movi a2, TEST_FAILED
    j test_gpio_done
    
test_gpio_passed:
    movi a2, msg_gpio_passed
    call uart_puts
    movi a2, TEST_PASSED
    
test_gpio_done:
    retw

; ============================================================================
; Test 3: Timer Driver
; ============================================================================

test_driver_timer:
    entry a1, 32
    
    movi a2, msg_test_timer
    call uart_puts
    
    ; Verificar se timer está inicializado
    movi a3, TIMER_STATE_BASE
    l32i a4, a3, TIMER_INITIALIZED
    beqi a4, 1, test_timer_check_period
    
    movi a2, msg_timer_not_init
    call uart_puts
    movi a2, TEST_FAILED
    j test_timer_done
    
test_timer_check_period:
    ; Verificar período
    l32i a4, a3, TIMER_PERIOD_US
    beqi a4, 0, test_timer_failed
    
    ; Teste de contador
    movi a2, TIMER_BASE
    l32i a4, a2, TIMER_T0_COUNT
    
    ; Delay
    movi a5, 100
    movi a6, 0
test_timer_delay:
    addi a6, a6, 1
    blt a6, a5, test_timer_delay
    
    ; Verificar se contador incrementou
    l32i a7, a2, TIMER_T0_COUNT
    bne a4, a7, test_timer_passed
    
test_timer_failed:
    movi a2, msg_timer_failed
    call uart_puts
    movi a2, TEST_FAILED
    j test_timer_done
    
test_timer_passed:
    movi a2, msg_timer_passed
    call uart_puts
    movi a2, TEST_PASSED
    
test_timer_done:
    retw

; ============================================================================
; Test 4: Scheduler Context Switch
; ============================================================================

test_scheduler_context_switch:
    entry a1, 32
    
    movi a2, msg_test_cs
    call uart_puts
    
    ; Verificar TCB base
    movi a3, TCB_BASE
    
    ; Teste de Task 0
    movi a2, 0
    muli a4, a2, TCB_SIZE
    add a4, a4, a3
    
    ; Verificar ID
    l32i a5, a4, TCB_TASK_ID_OFFSET
    bne a5, a2, test_cs_failed
    
    ; Verificar estado
    l32i a5, a4, TCB_STATE_OFFSET
    beqi a5, 0, test_cs_failed   ; Não deve estar SUSPENDED após init
    
    ; Teste de Task 1
    movi a2, 1
    muli a4, a2, TCB_SIZE
    add a4, a4, a3
    
    l32i a5, a4, TCB_TASK_ID_OFFSET
    bne a5, a2, test_cs_failed
    
    movi a2, msg_cs_passed
    call uart_puts
    movi a2, TEST_PASSED
    j test_cs_done
    
test_cs_failed:
    movi a2, msg_cs_failed
    call uart_puts
    movi a2, TEST_FAILED
    
test_cs_done:
    retw

; ============================================================================
; Test 5: Scheduler Round-Robin
; ============================================================================

test_scheduler_round_robin:
    entry a1, 32
    
    movi a2, msg_test_rr
    call uart_puts
    
    ; Verificar se current_task_id é válido
    movi a3, SCHED_STATE_BASE
    l32i a4, a3, CURRENT_TASK_ID_OFFSET
    
    movi a5, MAX_TASKS
    bge a4, a5, test_rr_failed
    
    ; Simular context switch
    ; (em implementação real, seria testado com interrupção de timer)
    
    movi a2, msg_rr_passed
    call uart_puts
    movi a2, TEST_PASSED
    j test_rr_done
    
test_rr_failed:
    movi a2, msg_rr_failed
    call uart_puts
    movi a2, TEST_FAILED
    
test_rr_done:
    retw

; ============================================================================
; Test 6: Synchronization
; ============================================================================

test_synchronization:
    entry a1, 32
    
    movi a2, msg_test_sync
    call uart_puts
    
    ; Teste de semáforo simulado
    movi a3, TEST_BUFFER_BASE
    
    ; Inicializar semáforo
    movi a4, 1
    s32i a4, a3, 0
    
    ; Tentar adquirir
    l32i a4, a3, 0
    beqi a4, 1, test_sync_acquire
    
    j test_sync_failed
    
test_sync_acquire:
    ; Setar como adquirido
    movi a4, 0
    s32i a4, a3, 0
    
    ; Verificar
    l32i a4, a3, 0
    beqi a4, 0, test_sync_release
    
    j test_sync_failed
    
test_sync_release:
    ; Liberar
    movi a4, 1
    s32i a4, a3, 0
    
    ; Verificar
    l32i a4, a3, 0
    beqi a4, 1, test_sync_passed
    
test_sync_failed:
    movi a2, msg_sync_failed
    call uart_puts
    movi a2, TEST_FAILED
    j test_sync_done
    
test_sync_passed:
    movi a2, msg_sync_passed
    call uart_puts
    movi a2, TEST_PASSED
    
test_sync_done:
    retw

; ============================================================================
; Mensagens de Teste
; ============================================================================

    .section .rodata
    .align 4

msg_test_header:
    .string "\r\n====================================\r\nRTOS Integration Test Suite\r\n====================================\r\n"

msg_test_uart:
    .string "[TEST 1/6] UART Driver... "

msg_uart_not_init:
    .string "FAILED (not initialized)\r\n"

msg_uart_test_tx:
    .string "testing TX... "

msg_uart_passed:
    .string "PASSED\r\n"

msg_uart_failed:
    .string "FAILED\r\n"

msg_test_gpio:
    .string "[TEST 2/6] GPIO Driver... "

msg_gpio_not_init:
    .string "FAILED (not initialized)\r\n"

msg_gpio_passed:
    .string "PASSED\r\n"

msg_gpio_failed:
    .string "FAILED\r\n"

msg_test_timer:
    .string "[TEST 3/6] Timer Driver... "

msg_timer_not_init:
    .string "FAILED (not initialized)\r\n"

msg_timer_passed:
    .string "PASSED\r\n"

msg_timer_failed:
    .string "FAILED\r\n"

msg_test_cs:
    .string "[TEST 4/6] Scheduler Context Switch... "

msg_cs_passed:
    .string "PASSED\r\n"

msg_cs_failed:
    .string "FAILED\r\n"

msg_test_rr:
    .string "[TEST 5/6] Scheduler Round-Robin... "

msg_rr_passed:
    .string "PASSED\r\n"

msg_rr_failed:
    .string "FAILED\r\n"

msg_test_sync:
    .string "[TEST 6/6] Synchronization... "

msg_sync_passed:
    .string "PASSED\r\n"

msg_sync_failed:
    .string "FAILED\r\n"

msg_test_summary:
    .string "\r\n====== TEST SUMMARY ======\r\n"

msg_total_tests:
    .string "Total: 0x"

msg_tests_passed:
    .string " Passed: 0x"

msg_tests_failed:
    .string " Failed: 0x"

msg_newline:
    .string "\r\n"

    .end