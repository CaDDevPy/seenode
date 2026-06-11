; ============================================================================
; Test: critical section verification task
; File: src/tests/test_critical_section.s
; ============================================================================

    .section .tasks, "ax"
    .global test_critical_section
    .align 4

test_critical_section:
    entry a1, 32

    ; print SR initial (as hex)
    movi a2, msg_test_start
    call uart_puts
    rsr a3, sr
    mov a2, a3
    call uart_print_hex

    ; nested critical sections (two levels)
    CRITICAL_SECTION_START
        CRITICAL_SECTION_START
            movi a2, msg_test_inside
            call uart_puts
        CRITICAL_SECTION_END
    CRITICAL_SECTION_END

    ; print SR final
    rsr a3, sr
    mov a2, a3
    call uart_print_hex

    ; done
    movi a2, msg_test_done
    call uart_puts

    j test_critical_section

; Data
    .section .rodata
    .align 4
msg_test_start:
    .string "[TEST] SR before: "
msg_test_inside:
    .string "[TEST] inside nested\r\n"
msg_test_done:
    .string "[TEST] done\r\n"

    .end
