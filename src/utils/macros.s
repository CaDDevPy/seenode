; ============================================================================
; ESP32 RTOS - Macros Utilitárias
; Arquivo: src/utils/macros.s
; Descrição: Macros para uso frequente em Assembly
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

; ============================================================================
; Macros de Stack
; ============================================================================

.macro PUSH_REG reg
    s32i \reg, a1, 0
    addi a1, a1, 4
.endm

.macro POP_REG reg
    addi a1, a1, -4
    l32i \reg, a1, 0
.endm

.macro PUSH_REG_MULTI regs
    ; Push múltiplos registradores (a2, a3, ...)
    ; Uso: PUSH_REG_MULTI a2, a3, a4
    ; (Implementação inline necessária)
.endm

.macro POP_REG_MULTI regs
    ; Pop múltiplos registradores
    ; Uso: POP_REG_MULTI a4, a3, a2 (ordem reversa!)
.endm

; ============================================================================
; Macros de Leitura/Escrita de Registradores Periféricos
; ============================================================================

.macro READ_REG reg, base, offset
    ; Ler registrador de periférico
    ; Uso: READ_REG a2, a3, 0x10
    movi \reg, \base
    l32i \reg, \reg, \offset
.endm

.macro WRITE_REG value, base, offset
    ; Escrever valor em registrador de periférico
    ; Uso: WRITE_REG a2, a3, 0x10
    movi a15, \base
    s32i \value, a15, \offset
.endm

.macro BIT_SET reg, bit
    ; Setar bit em registrador
    ; Uso: BIT_SET a2, 3
    ori \reg, \reg, (1 << \bit)
.endm

.macro BIT_CLEAR reg, bit
    ; Limpar bit em registrador
    ; Uso: BIT_CLEAR a2, 3
    movi a15, ~(1 << \bit)
    and \reg, \reg, a15
.endm

.macro BIT_TOGGLE reg, bit
    ; Alternar bit em registrador
    ; Uso: BIT_TOGGLE a2, 3
    xori \reg, \reg, (1 << \bit)
.endm

.macro BIT_TEST reg, bit
    ; Testar bit (resultado em \reg)
    ; Uso: BIT_TEST a2, 3
    srai \reg, \reg, \bit
    andi \reg, \reg, 1
.endm

; ============================================================================
; Macros de Delays
; ============================================================================

.macro DELAY_LOOP iterations
    ; Delay simples (aproximado)
    ; Uso: DELAY_LOOP 1000
    movi a15, \iterations
    movi a14, 0
delay_loop_\@:
    addi a14, a14, 1
    blt a14, a15, delay_loop_\@
.endm

.macro UDELAY_APPROX microseconds
    ; Delay aproximado em microsegundos (a 80 MHz)
    ; Uso: UDELAY_APPROX 100
    ; ~80 ciclos por microsegundo
    .set iter, (\microseconds * 80) / 3
    DELAY_LOOP iter
.endm

; ============================================================================
; Macros de Controle de Fluxo
; ============================================================================

.macro IF_ZERO reg, label
    ; If \reg == 0, pular para label
    beqi \reg, 0, \label
.endm

.macro IF_NOT_ZERO reg, label
    ; If \reg != 0, pular para label
    bnei \reg, 0, \label
.endm

.macro IF_EQUAL reg1, reg2, label
    ; If \reg1 == \reg2, pular para label
    beq \reg1, \reg2, \label
.endm

.macro IF_NOT_EQUAL reg1, reg2, label
    ; If \reg1 != \reg2, pular para label
    bne \reg1, \reg2, \label
.endm

.macro IF_LESS reg1, reg2, label
    ; If \reg1 < \reg2, pular para label
    blt \reg1, \reg2, \label
.endm

.macro IF_GREATER_EQUAL reg1, reg2, label
    ; If \reg1 >= \reg2, pular para label
    bge \reg1, \reg2, \label
.endm

; ============================================================================
; Macros de Aritmética
; ============================================================================

.macro ADD_IMM dest, src, imm
    ; Adicionar imediato (se maior que 12 bits)
    movi a15, \imm
    add \dest, \src, a15
.endm

.macro MUL_IMM dest, src, imm
    ; Multiplicar por imediato
    movi a15, \imm
    muls a15, \src, a15
    mov \dest, a15
.endm

.macro DIV_IMM dest, src, imm
    ; Dividir por imediato
    movi a15, \imm
    quos a15, \src, a15
    mov \dest, a15
.endm

.macro MOD_IMM dest, src, imm
    ; Resto da divisão (módulo)
    movi a15, \imm
    rems a15, \src, a15
    mov \dest, a15
.endm

; ============================================================================
; Macros de Manipulação de Dados
; ============================================================================

.macro CLEAR_REG reg
    ; Zerar registrador
    xor \reg, \reg, \reg
.endm

.macro COPY_REG dest, src
    ; Copiar registrador
    mov \dest, \src
.endm

.macro SWAP_REG reg1, reg2
    ; Trocar valores entre registradores
    mov a15, \reg1
    mov \reg1, \reg2
    mov \reg2, a15
.endm

.macro LOAD_ADDRESS addr, reg
    ; Carregar endereço em registrador
    movi \reg, \addr
.endm

; ============================================================================
; Macros de Debug/Log
; ============================================================================

.macro DEBUG_MSG msg
    ; Enviar mensagem de debug via UART
    movi a2, \msg
    call uart_puts
.endm

.macro DEBUG_HEX value
    ; Enviar valor hexadecimal via UART
    movi a2, \value
    call uart_print_hex
.endm

.macro BREAK_POINT
    ; Ponto de parada (halt em debug)
    waiti 0
.endm

; ============================================================================
; Macros de Sincronização
; ============================================================================

.macro YIELD
    ; Ceder CPU para próxima tarefa
    call scheduler_yield
.endm

.macro DISABLE_INTERRUPTS
    ; Desabilitar interrupções
    rsr a15, sr
    movi a14, ~0x8
    and a15, a15, a14
    wsr a15, sr
.endm

.macro ENABLE_INTERRUPTS
    ; Habilitar interrupções
    rsr a15, sr
    ori a15, a15, 0x8
    wsr a15, sr
.endm

.macro CRITICAL_SECTION_START
    ; Iniciar seção crítica (desabilitar interrupções)
    DISABLE_INTERRUPTS
.endm

.macro CRITICAL_SECTION_END
    ; Finalizar seção crítica (reabilitar interrupções)
    ENABLE_INTERRUPTS
.endm

; ============================================================================
; Macros de Context Switching
; ============================================================================

.macro SAVE_CONTEXT tcb_ptr
    ; Salvar contexto atual em TCB
    ; Uso: SAVE_CONTEXT a2 (onde a2 = ponteiro TCB)
    s32i a1, \tcb_ptr, 0x08   ; SP
    s32i a0, \tcb_ptr, 0x0C   ; PC
    s32i a2, \tcb_ptr, 0x10   ; a2
    s32i a3, \tcb_ptr, 0x14   ; a3
    ; ... (seriam salvos todos a2-a15 em implementação real)
.endm

.macro RESTORE_CONTEXT tcb_ptr
    ; Restaurar contexto de TCB
    ; Uso: RESTORE_CONTEXT a2 (onde a2 = ponteiro TCB)
    l32i a1, \tcb_ptr, 0x08   ; SP
    l32i a0, \tcb_ptr, 0x0C   ; PC
    l32i a2, \tcb_ptr, 0x10   ; a2
    l32i a3, \tcb_ptr, 0x14   ; a3
    ; ... (seriam restaurados todos a2-a15 em implementação real)
.endm

; ============================================================================
; Macros de Teste
; ============================================================================

.macro ASSERT condition, label
    ; Verificar condição e pular se falsa
    ; Uso: ASSERT (a2 != 0), error_label
.endm

.macro COUNT_ITERATIONS counter_addr
    ; Incrementar contador de iterações (para profiling)
    movi a15, \counter_addr
    l32i a14, a15, 0
    addi a14, a14, 1
    s32i a14, a15, 0
.endm

    .end