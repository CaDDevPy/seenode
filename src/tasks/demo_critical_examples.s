; ============================================================================
; Demo: Critical-section examples
; File: src/tasks/demo_critical_examples.s
; Description: Demonstration tasks for critical-section macros
; ============================================================================

    .section .tasks, "ax"
    .align 4

    .global demo_task_crit_nested
    .global demo_task_crit_isr_sim
    .global demo_task_crit_preserve

; ============================================================================
; Demo 1: nested critical sections (task context)
; ============================================================================

demo_task_crit_nested:
    entry a1, 32

    ; Print SR before (hex)
    rsr a3, sr
    mov a2, a3
    call uart_print_hex

    ; Outer critical
    CRITICAL_SECTION_START
        ; Inner critical
        CRITICAL_SECTION_START
            movi a2, msg_inside_nested
            call uart_puts
        CRITICAL_SECTION_END
    CRITICAL_SECTION_END

    ; Print SR after (hex)
    rsr a3, sr
    mov a2, a3
    call uart_print_hex

    call scheduler_yield
    j demo_task_crit_nested

; ============================================================================
; Demo 2: ISR-style critical section (no stack push)
; ============================================================================

demo_task_crit_isr_sim:
    entry a1, 32

    movi a2, msg_isr_demo
    call uart_puts

    CRITICAL_SECTION_ISR_START
        movi a2, msg_isr_in
        call uart_puts
    CRITICAL_SECTION_ISR_END

    call scheduler_yield
    j demo_task_crit_isr_sim

; ============================================================================
; Demo 3: preserve temporaries variant
; ============================================================================

demo_task_crit_preserve:
    entry a1, 32

    ; prepare known values in temporaries
    movi a14, 0xAAAA
    movi a15, 0x5555

    DISABLE_INTERRUPTS_PRESERVE
        movi a2, msg_preserve_demo
        call uart_puts
    ENABLE_INTERRUPTS_PRESERVE

    ; Verify a14/a15 preserved
    mov a2, a14
    call uart_print_hex
    mov a2, a15
    call uart_print_hex

    call scheduler_yield
    j demo_task_crit_preserve

; ============================================================================
; Data / Strings
; ============================================================================

    .section .rodata
    .align 4

msg_inside_nested:
    .string "[DEMO] inside nested critical\r\n"

msg_isr_demo:
    .string "[DEMO] ISR-style demo start\r\n"

msg_isr_in:
    .string "[DEMO] inside ISR-style critical\r\n"

msg_preserve_demo:
    .string "[DEMO] preserve-temporary demo\r\n"

    .end
