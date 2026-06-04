; ============================================================================
; ESP32 RTOS - Task Template
; Arquivo: src/tasks/task_template.s
; Descrição: Template reutilizável para criar novas tarefas
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .tasks, "ax"
    .global task_custom_template
    .align 4

; ============================================================================
; TEMPLATE: Tarefa Customizável
; ============================================================================

; PASSO 1: Copiar esta seção e renomear 'task_custom_template' para seu nome
; PASSO 2: Implementar a lógica no loop principal
; PASSO 3: Registrar a tarefa no boot sequence

task_custom_template:
    entry a1, 32
    
    ; ========== INICIALIZAÇÃO ==========
    ; Configure aqui qualquer estado inicial da tarefa
    movi a10, 0             ; Contador local
    movi a11, 0             ; Estado local
    movi a12, 0             ; Temporário
    
    ; Exemplo: Configurar GPIO
    ; movi a2, GPIO_PIN_NUMBER
    ; movi a3, 1              ; Output mode
    ; call gpio_set_direction
    
    ; Exemplo: Log de início
    ; movi a2, msg_task_start
    ; call uart_puts
    
task_custom_loop:
    ; ========== CORPO PRINCIPAL ==========
    ; Implemente aqui a lógica da sua tarefa
    
    ; Exemplo: Incrementar contador
    addi a10, a10, 1
    
    ; Exemplo: Verificar condição
    movi a12, 10000
    bge a10, a12, task_custom_action
    
    ; Continuar loop
    j task_custom_check_yield
    
task_custom_action:
    ; ========== AÇÃO PERIÓDICA ==========
    ; Executar a cada N iterações
    
    ; Reset contador
    movi a10, 0
    
    ; Exemplo: Toggle LED
    ; movi a2, GPIO_PIN_NUMBER
    ; call gpio_toggle
    
    ; Exemplo: Log de status
    ; movi a2, msg_task_status
    ; call uart_puts
    
task_custom_check_yield:
    ; ========== YIELD COOPERATIVO ==========
    ; IMPORTANTE: Sempre chamar yield para permitir
    ; que outras tarefas executem
    
    call scheduler_yield
    
    ; ========== RETRY LOOP ==========
    ; Voltamos ao topo do loop
    j task_custom_loop

; ============================================================================
; VARIAÇÕES: Templates Especializados (ATUALIZADOS PARA USAR SEÇÕES CRÍTICAS)
; ============================================================================

; ===== Tarefa com Timeout =====
task_template_with_timeout:
    entry a1, 32
    
    movi a10, 0             ; Contador geral
    movi a11, 0             ; Timeout counter
    movi a12, 5000          ; Timeout limit
    
task_timeout_loop:
    addi a10, a10, 1
    addi a11, a11, 1
    
    ; Verificar timeout
    bge a11, a12, task_timeout_expired
    
    ; Continuar
    j task_timeout_yield
    
task_timeout_expired:
    ; Tratamento de timeout
    movi a11, 0             ; Reset timeout
    ; TODO: Implementar ação de timeout
    
task_timeout_yield:
    call scheduler_yield
    j task_timeout_loop

; ===== Tarefa com Máquina de Estados =====
task_template_state_machine:
    entry a1, 32
    
    movi a10, 0             ; Estado (0=IDLE, 1=ACTIVE, 2=WAIT)
    movi a11, 0             ; Contador
    
task_sm_loop:
    ; Switch por estado
    beqi a10, 0, task_sm_state_idle
    beqi a10, 1, task_sm_state_active
    beqi a10, 2, task_sm_state_wait
    
    ; Default: volta para IDLE
    movi a10, 0
    j task_sm_loop
    
task_sm_state_idle:
    ; Estado IDLE
    addi a11, a11, 1
    
    ; Transição
    movi a12, 1000
    bge a11, a12, task_sm_to_active
    
    j task_sm_yield
    
task_sm_to_active:
    movi a10, 1             ; Ir para ACTIVE
    movi a11, 0             ; Reset contador
    j task_sm_yield
    
task_sm_state_active:
    ; Estado ACTIVE
    addi a11, a11, 1
    
    ; Processar...
    
    ; Transição
    movi a12, 500
    bge a11, a12, task_sm_to_wait
    
    j task_sm_yield
    
task_sm_to_wait:
    movi a10, 2             ; Ir para WAIT
    movi a11, 0             ; Reset contador
    j task_sm_yield
    
task_sm_state_wait:
    ; Estado WAIT
    addi a11, a11, 1
    
    ; Aguardar...
    
    ; Transição
    movi a12, 2000
    bge a11, a12, task_sm_to_idle
    
    j task_sm_yield
    
task_sm_to_idle:
    movi a10, 0             ; Ir para IDLE
    movi a11, 0             ; Reset contador
    j task_sm_yield
    
task_sm_yield:
    call scheduler_yield
    j task_sm_loop

; ===== Tarefa com Buffer Circular =====
task_template_circular_buffer:
    entry a1, 32
    
    movi a10, 0             ; Read pointer
    movi a11, 0             ; Write pointer
    movi a12, 0             ; Buffer size
    
    ; Buffer base address (exemplo)
    movi a13, 0x3FFC0000    ; Heap base
    
task_cb_loop:
    ; Verificar se há dados
    bne a10, a11, task_cb_process
    
    ; Buffer vazio
    j task_cb_yield
    
task_cb_process:
    ; Ler e processar dado
    l8ui a2, a13, a10
    
    ; Incrementar read pointer (com wraparound)
    addi a10, a10, 1
    movi a12, 256           ; Buffer size
    modu a10, a10, a12
    
    ; TODO: Processar dado em a2
    
task_cb_yield:
    call scheduler_yield
    j task_cb_loop

; ===== Tarefa com Sincronização (semáforo simulado) =====
; Atualizado para usar CRITICAL_SECTION_START/END ao acessar recurso compartilhado
task_template_synchronized:
    entry a1, 32
    
    movi a10, 0             ; Estado
    movi a11, 0             ; Semáforo (0=locked, 1=free)
    
task_sync_loop:
    ; Tentar adquirir semáforo
    beqi a11, 1, task_sync_acquire
    
    ; Semáforo não disponível, yield
    call scheduler_yield
    j task_sync_loop
    
task_sync_acquire:
    ; Semáforo adquirido
    movi a11, 0             ; Lock
    
    ; Seção crítica: protegida por CRITICAL_SECTION macros
    CRITICAL_SECTION_START
        movi a2, msg_critical_section
        call uart_puts
        ; Simular trabalho (não bloqueante)
        movi a10, 0
        movi a12, 10000
    task_sync_work:
        addi a10, a10, 1
        blt a10, a12, task_sync_work
    CRITICAL_SECTION_END
    
    ; Liberar semáforo
    movi a11, 1             ; Unlock
    
    call scheduler_yield
    j task_sync_loop

; ============================================================================
; Mensagens de Debug
; ============================================================================

    .section .rodata
    .align 4

msg_critical_section:
    .string "[CRITICAL] Section entered\r\n"

    .end
