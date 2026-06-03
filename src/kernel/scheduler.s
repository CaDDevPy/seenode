; ============================================================================
; ESP32 RTOS - Scheduler (Escalonador)
; Arquivo: src/kernel/scheduler.s
; Descrição: Implementação de escalonador Round-Robin
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .kernel, "ax"
    .global scheduler_yield
    .global scheduler_init
    .global scheduler_get_next_task
    .align 4

; Constantes
TCB_SIZE                = 128
TCB_BASE                = 0x3FFAC000
MAX_TASKS               = 4

; Task States
STATE_SUSPENDED         = 0
STATE_READY             = 1
STATE_RUNNING           = 2
STATE_BLOCKED           = 3

; TCB Offsets
TCB_TASK_ID_OFFSET      = 0x00
TCB_STATE_OFFSET        = 0x04
TCB_SP_OFFSET           = 0x08
TCB_PC_OFFSET           = 0x0C
TCB_REG_A2_OFFSET       = 0x10
TCB_PRIORITY_OFFSET     = 0x50
TCB_TIME_SLICE_OFFSET   = 0x54

; ============================================================================
; Scheduler State (armazenado em 0x3FFAC200)
; ============================================================================
SCHED_STATE_BASE        = 0x3FFAC200
CURRENT_TASK_ID_OFFSET  = 0x00
NEXT_TASK_ID_OFFSET     = 0x04
TASK_QUEUE_HEAD_OFFSET  = 0x08
TASK_QUEUE_TAIL_OFFSET  = 0x0C
TIMER_TICKS_OFFSET      = 0x10
INTERRUPT_MASK_OFFSET   = 0x14

; ============================================================================
; Inicialização do Scheduler
; ============================================================================

scheduler_init:
    entry a1, 32
    
    ; Inicializar estado do scheduler
    movi a2, SCHED_STATE_BASE
    
    ; current_task_id = 0
    movi a3, 0
    s32i a3, a2, CURRENT_TASK_ID_OFFSET
    
    ; next_task_id = 0
    s32i a3, a2, NEXT_TASK_ID_OFFSET
    
    ; task_queue_head = 0
    s32i a3, a2, TASK_QUEUE_HEAD_OFFSET
    
    ; task_queue_tail = 0
    s32i a3, a2, TASK_QUEUE_TAIL_OFFSET
    
    ; timer_ticks = 0
    s32i a3, a2, TIMER_TICKS_OFFSET
    
    ; interrupt_mask = 0
    s32i a3, a2, INTERRUPT_MASK_OFFSET
    
    ; Marcar Task 0 como READY
    movi a2, TCB_BASE
    movi a3, STATE_READY
    s32i a3, a2, TCB_STATE_OFFSET
    
    retw

; ============================================================================
; Yield - Cede controle para próxima tarefa
; ============================================================================

scheduler_yield:
    entry a1, 48
    
    ; Salvar contexto da tarefa atual
    ; a2 = current_task_id
    movi a2, SCHED_STATE_BASE
    l32i a2, a2, CURRENT_TASK_ID_OFFSET
    
    ; Calcular endereço TCB: TCB_BASE + (task_id * TCB_SIZE)
    muli a3, a2, TCB_SIZE
    add a3, a3, TCB_BASE
    
    ; Salvar Stack Pointer (a1)
    s32i a1, a3, TCB_SP_OFFSET
    
    ; Salvar Program Counter (a0)
    s32i a0, a3, TCB_PC_OFFSET
    
    ; Salvar registradores gerais (a2-a15)
    s32i a2, a3, TCB_REG_A2_OFFSET
    l32i a4, a3, TCB_REG_A2_OFFSET + 0x04
    s32i a4, a3, TCB_REG_A2_OFFSET + 0x04
    ; ... (simplificado - em real, todos a2-a15 seriam salvos)
    
    ; Obter próxima tarefa
    call scheduler_get_next_task
    ; a2 agora contém o ID da próxima tarefa
    
    ; Atualizar current_task_id
    movi a4, SCHED_STATE_BASE
    s32i a2, a4, CURRENT_TASK_ID_OFFSET
    
    ; Restaurar contexto da próxima tarefa
    muli a3, a2, TCB_SIZE
    add a3, a3, TCB_BASE
    
    ; Restaurar Stack Pointer (a1)
    l32i a1, a3, TCB_SP_OFFSET
    
    ; Restaurar Program Counter (a0)
    l32i a0, a3, TCB_PC_OFFSET
    
    ; Restaurar registradores (a2-a15)
    l32i a2, a3, TCB_REG_A2_OFFSET
    l32i a4, a3, TCB_REG_A2_OFFSET + 0x04
    ; ... (simplificado)
    
    retw

; ============================================================================
; Get Next Task - Encontra próxima tarefa READY
; ============================================================================

scheduler_get_next_task:
    entry a1, 24
    
    ; Usar Round-Robin simples
    ; a2 = current_task_id
    movi a3, SCHED_STATE_BASE
    l32i a2, a3, CURRENT_TASK_ID_OFFSET
    
    ; Incrementar: next_id = (current_id + 1) % MAX_TASKS
    addi a2, a2, 1
    movi a4, MAX_TASKS
    blt a2, a4, get_next_task_done
    
    ; Wraparound se necessário
    movi a2, 0
    
get_next_task_done:
    ; a2 contém o ID da próxima tarefa
    retw

; ============================================================================
; Marcar tarefa como READY
; ============================================================================

scheduler_mark_ready:
    ; a2 = task_id
    entry a1, 16
    
    ; Calcular endereço TCB
    muli a3, a2, TCB_SIZE
    add a3, a3, TCB_BASE
    
    ; Setar state = STATE_READY
    movi a4, STATE_READY
    s32i a4, a3, TCB_STATE_OFFSET
    
    retw

; ============================================================================
; Marcar tarefa como BLOCKED
; ============================================================================

scheduler_mark_blocked:
    ; a2 = task_id
    entry a1, 16
    
    ; Calcular endereço TCB
    muli a3, a2, TCB_SIZE
    add a3, a3, TCB_BASE
    
    ; Setar state = STATE_BLOCKED
    movi a4, STATE_BLOCKED
    s32i a4, a3, TCB_STATE_OFFSET
    
    retw

; ============================================================================
; Incrementar tick do timer
; ============================================================================

scheduler_tick:
    entry a1, 16
    
    ; Incrementar timer_ticks
    movi a2, SCHED_STATE_BASE
    l32i a3, a2, TIMER_TICKS_OFFSET
    addi a3, a3, 1
    s32i a3, a2, TIMER_TICKS_OFFSET
    
    ; Se time slice expirou, fazer yield
    movi a4, 10             ; Time slice padrão
    modu a5, a3, a4
    bnei a5, 0, scheduler_tick_done
    
    ; Chamar yield se time slice expirou
    call scheduler_yield
    
scheduler_tick_done:
    retw

    .end