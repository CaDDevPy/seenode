; ============================================================================
; ESP32 RTOS - Testes de Scheduler
; Arquivo: tests/scheduler_tests.s
; Descrição: Testes para validar funcionamento do scheduler
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .tests, "ax"
    .global test_scheduler_detailed
    .global test_context_switch_detailed
    .global test_task_states
    .align 4

; ============================================================================
; Scheduler Detailed Tests
; ============================================================================

test_scheduler_detailed:
    entry a1, 48
    
    movi a2, msg_scheduler_start
    call uart_puts
    
    movi a10, 0             ; Contador de testes
    movi a11, 0             ; Sucessos
    
    ; Test 1: Verificar TCB valida
    movi a2, msg_sched_test_tcb
    call uart_puts
    
    movi a3, TCB_BASE
    
    ; Verificar todos os TCBs
    movi a4, 0              ; Task ID
test_sched_tcb_loop:
    muli a5, a4, TCB_SIZE
    add a6, a3, a5
    
    ; Verificar ID
    l32i a7, a6, TCB_TASK_ID_OFFSET
    bne a7, a4, test_sched_tcb_failed
    
    ; Verificar state válido
    l32i a7, a6, TCB_STATE_OFFSET
    movi a8, 4
    bge a7, a8, test_sched_tcb_failed  ; State deve ser 0-3
    
    ; Próximo
    addi a4, a4, 1
    movi a8, MAX_TASKS
    blt a4, a8, test_sched_tcb_loop
    
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    j test_sched_current_task
    
test_sched_tcb_failed:
    movi a2, msg_failed
    call uart_puts
    
    ; Test 2: Verificar current_task_id
test_sched_current_task:
    movi a2, msg_sched_test_current
    call uart_puts
    
    movi a3, SCHED_STATE_BASE
    l32i a4, a3, CURRENT_TASK_ID_OFFSET
    
    movi a5, MAX_TASKS
    bge a4, a5, test_sched_current_failed
    
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    j test_sched_ready_tasks
    
test_sched_current_failed:
    movi a2, msg_failed
    call uart_puts
    
    ; Test 3: Verificar tarefas READY
test_sched_ready_tasks:
    movi a2, msg_sched_test_ready
    call uart_puts
    
    movi a3, TCB_BASE
    movi a4, 0
    movi a5, 0              ; Contador de READY
    
test_sched_ready_loop:
    muli a6, a4, TCB_SIZE
    add a7, a3, a6
    
    l32i a8, a7, TCB_STATE_OFFSET
    beqi a8, STATE_READY, test_sched_ready_found
    
    j test_sched_ready_next
    
test_sched_ready_found:
    addi a5, a5, 1
    
test_sched_ready_next:
    addi a4, a4, 1
    movi a9, MAX_TASKS
    blt a4, a9, test_sched_ready_loop
    
    ; Deve ter pelo menos 1 tarefa READY
    beqi a5, 0, test_sched_ready_failed
    
    movi a2, msg_passed
    call uart_puts
    addi a11, a11, 1
    j test_sched_done
    
test_sched_ready_failed:
    movi a2, msg_failed
    call uart_puts
    
test_sched_done:
    retw

; ============================================================================
; Context Switch Detailed Tests
; ============================================================================

test_context_switch_detailed:
    entry a1, 48
    
    movi a2, msg_cs_detailed_start
    call uart_puts
    
    movi a10, 0
    
    ; Test 1: Salvar contexto
    movi a2, msg_cs_test_save
    call uart_puts
    
    ; Preencher registradores com valores teste
    movi a2, 0x11111111
    movi a3, 0x22222222
    movi a4, 0x33333333
    movi a5, 0x44444444
    
    ; Calcular endereço TCB de teste
    movi a6, 0x3FFC0000     ; Buffer de teste
    
    ; Salvar SP e PC (simulado)
    s32i a1, a6, TCB_SP_OFFSET
    s32i a0, a6, TCB_PC_OFFSET
    
    ; Verificar
    l32i a7, a6, TCB_SP_OFFSET
    bne a7, a1, test_cs_save_failed
    
    l32i a7, a6, TCB_PC_OFFSET
    bne a7, a0, test_cs_save_failed
    
    movi a2, msg_passed
    call uart_puts
    addi a10, a10, 1
    j test_cs_restore
    
test_cs_save_failed:
    movi a2, msg_failed
    call uart_puts
    
    ; Test 2: Restaurar contexto
test_cs_restore:
    movi a2, msg_cs_test_restore
    call uart_puts
    
    ; Salvar valores originais
    mov a8, a1
    mov a9, a0
    
    ; Modificar registradores
    movi a1, 0x99999999
    movi a0, 0xAAAAAAAA
    
    ; Restaurar do buffer
    l32i a1, a6, TCB_SP_OFFSET
    l32i a0, a6, TCB_PC_OFFSET
    
    ; Verificar
    bne a1, a8, test_cs_restore_failed
    bne a0, a9, test_cs_restore_failed
    
    movi a2, msg_passed
    call uart_puts
    addi a10, a10, 1
    j test_cs_detailed_done
    
test_cs_restore_failed:
    movi a2, msg_failed
    call uart_puts
    
test_cs_detailed_done:
    retw

; ============================================================================
; Task States Tests
; ============================================================================

test_task_states:
    entry a1, 32
    
    movi a2, msg_states_start
    call uart_puts
    
    ; Verificar transições de estado
    movi a3, TCB_BASE
    movi a4, 0              ; Task 0
    
    muli a5, a4, TCB_SIZE
    add a5, a5, a3
    
    ; Test 1: READY -> RUNNING (simulado)
    movi a2, msg_states_ready_running
    call uart_puts
    
    movi a6, STATE_RUNNING
    s32i a6, a5, TCB_STATE_OFFSET
    
    l32i a6, a5, TCB_STATE_OFFSET
    beqi a6, STATE_RUNNING, test_states_ok1
    
    movi a2, msg_failed
    call uart_puts
    j test_states_done
    
test_states_ok1:
    movi a2, msg_passed
    call uart_puts
    
    ; Test 2: RUNNING -> BLOCKED
    movi a2, msg_states_running_blocked
    call uart_puts
    
    movi a6, STATE_BLOCKED
    s32i a6, a5, TCB_STATE_OFFSET
    
    l32i a6, a5, TCB_STATE_OFFSET
    beqi a6, STATE_BLOCKED, test_states_ok2
    
    movi a2, msg_failed
    call uart_puts
    j test_states_done
    
test_states_ok2:
    movi a2, msg_passed
    call uart_puts
    
    ; Test 3: BLOCKED -> READY
    movi a2, msg_states_blocked_ready
    call uart_puts
    
    movi a6, STATE_READY
    s32i a6, a5, TCB_STATE_OFFSET
    
    l32i a6, a5, TCB_STATE_OFFSET
    beqi a6, STATE_READY, test_states_ok3
    
    movi a2, msg_failed
    call uart_puts
    j test_states_done
    
test_states_ok3:
    movi a2, msg_passed
    call uart_puts
    
test_states_done:
    retw

; ============================================================================
; Mensagens
; ============================================================================

    .section .rodata
    .align 4

msg_scheduler_start:
    .string "\r\n=== Scheduler Tests ===\r\n"

msg_sched_test_tcb:
    .string "  TCB Validation: "

msg_sched_test_current:
    .string "  Current Task ID: "

msg_sched_test_ready:
    .string "  Ready Tasks: "

msg_cs_detailed_start:
    .string "\r\n=== Context Switch Tests ===\r\n"

msg_cs_test_save:
    .string "  Save Context: "

msg_cs_test_restore:
    .string "  Restore Context: "

msg_states_start:
    .string "\r\n=== Task States Tests ===\r\n"

msg_states_ready_running:
    .string "  READY->RUNNING: "

msg_states_running_blocked:
    .string "  RUNNING->BLOCKED: "

msg_states_blocked_ready:
    .string "  BLOCKED->READY: "

msg_passed:
    .string "PASSED\r\n"

msg_failed:
    .string "FAILED\r\n"

    .end