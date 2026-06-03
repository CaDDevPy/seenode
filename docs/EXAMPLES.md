# Exemplos de Uso - ESP32 RTOS em Assembly

Este documento fornece exemplos práticos de como usar o ESP32 RTOS, desde tarefas simples até padrões avançados.

---

## 📚 Índice

1. [Tarefas Básicas](#tarefas-básicas)
2. [Uso de GPIO](#uso-de-gpio)
3. [Comunicação UART](#comunicação-uart)
4. [Timer e Preempção](#timer-e-preempção)
5. [Padrões Avançados](#padrões-avançados)
6. [Tratamento de Erros](#tratamento-de-erros)
7. [Debugging](#debugging)

---

## Tarefas Básicas

### Exemplo 1: Tarefa Simples com Contador

```assembly
; Arquivo: src/tasks/example_simple_counter.s

task_counter:
    entry a1, 16
    
    ; Inicializar contador
    movi a10, 0             ; a10 = contador
    
task_counter_loop:
    ; Incrementar
    addi a10, a10, 1
    
    ; Verificar limite
    movi a11, 1000
    blt a10, a11, task_counter_continue
    
    ; Reset
    movi a10, 0
    
    ; Log
    movi a2, msg_counter_reached
    call uart_puts
    
task_counter_continue:
    ; Yield obrigatório
    call scheduler_yield
    
    j task_counter_loop
```

---

### Exemplo 2: Tarefa com Múltiplos Estados

```assembly
task_multi_state:
    entry a1, 32
    
    ; Estados: 0=INIT, 1=WAIT, 2=PROCESS, 3=SLEEP
    movi a10, 0             ; Estado atual
    movi a11, 0             ; Timer para cada estado
    
task_ms_loop:
    ; Switch de estado
    beqi a10, 0, task_ms_init
    beqi a10, 1, task_ms_wait
    beqi a10, 2, task_ms_process
    beqi a10, 3, task_ms_sleep
    
    ; Default: volta INIT
    movi a10, 0
    j task_ms_loop
    
task_ms_init:
    ; Estado de inicialização
    movi a2, GPIO_LED_PIN
    movi a3, 1
    call gpio_set_direction
    
    movi a10, 1             ; Ir para WAIT
    j task_ms_yield
    
task_ms_wait:
    ; Aguardar sinal
    addi a11, a11, 1
    
    movi a12, 100
    bge a11, a12, task_ms_wait_done
    j task_ms_yield
    
task_ms_wait_done:
    movi a11, 0
    movi a10, 2             ; Ir para PROCESS
    j task_ms_yield
    
task_ms_process:
    ; Processar dados
    movi a2, GPIO_LED_PIN
    call gpio_toggle
    
    movi a10, 3             ; Ir para SLEEP
    j task_ms_yield
    
task_ms_sleep:
    ; Dormir
    addi a11, a11, 1
    
    movi a12, 500
    bge a11, a12, task_ms_sleep_done
    j task_ms_yield
    
task_ms_sleep_done:
    movi a11, 0
    movi a10, 1             ; Voltar para WAIT
    
task_ms_yield:
    call scheduler_yield
    j task_ms_loop
```

---

## Uso de GPIO

### Exemplo 3: Controle de Múltiplos LEDs

```assembly
task_led_controller:
    entry a1, 32
    
    ; LEDs em GPIO 2, 4, 5
    movi a10, 0             ; LED atual
    movi a11, 0             ; Contador
    
    ; Configurar como saída
    movi a2, 2
    movi a3, 1
    call gpio_set_direction
    
    movi a2, 4
    call gpio_set_direction
    
    movi a2, 5
    call gpio_set_direction
    
task_led_loop:
    ; Incrementar contador
    addi a11, a11, 1
    
    ; A cada 50000 iterações, trocar LED
    movi a12, 50000
    modu a13, a11, a12
    bnei a13, 0, task_led_continue
    
    ; Apagar LED anterior
    addi a12, a10, 2        ; GPIO pin = a10 + 2
    movi a2, a12
    movi a3, 0
    call gpio_set_level
    
    ; Selecionar próximo LED
    addi a10, a10, 1
    movi a12, 3
    modu a10, a10, a12      ; Wrap around (0,1,2)
    
    ; Acender novo LED
    addi a12, a10, 2        ; GPIO pin
    movi a2, a12
    movi a3, 1
    call gpio_set_level
    
    ; Log
    movi a2, msg_led_switched
    call uart_puts
    
task_led_continue:
    call scheduler_yield
    j task_led_loop
```

### Exemplo 4: Monitorar Múltiplos Botões

```assembly
task_button_matrix:
    entry a1, 32
    
    ; Botões em GPIO 0, 12, 14
    movi a10, 0             ; Estado anterior dos botões
    movi a11, 0             ; Contador de presses
    
    ; Configurar como entrada
    movi a2, 0              ; GPIO0
    movi a3, 0
    call gpio_set_direction
    
    movi a2, 12             ; GPIO12
    call gpio_set_direction
    
    movi a2, 14             ; GPIO14
    call gpio_set_direction
    
task_button_loop:
    ; Ler botões
    movi a2, 0
    call gpio_get_level
    mov a12, a2
    
    movi a2, 12
    call gpio_get_level
    sll a2, a2, 1           ; Deslocar para bit 1
    or a12, a12, a2
    
    movi a2, 14
    call gpio_get_level
    sll a2, a2, 2           ; Deslocar para bit 2
    or a12, a12, a2
    
    ; Comparar com estado anterior
    bne a12, a10, task_button_changed
    j task_button_continue
    
task_button_changed:
    ; Atualizar estado
    mov a10, a12
    addi a11, a11, 1
    
    movi a2, msg_button_change
    call uart_puts
    
    mov a2, a11
    call uart_print_hex
    
    movi a2, msg_newline
    call uart_puts
    
task_button_continue:
    call scheduler_yield
    j task_button_loop
```

---

## Comunicação UART

### Exemplo 5: Enviar Dados Formatados

```assembly
task_uart_formatter:
    entry a1, 32
    
    movi a10, 0             ; Contador
    
task_uart_loop:
    ; Enviar cabeçalho
    movi a2, msg_uart_header
    call uart_puts
    
    ; Enviar número em hex
    mov a2, a10
    call uart_print_hex
    
    ; Enviar separador
    movi a2, msg_uart_sep
    call uart_puts
    
    ; Incrementar
    addi a10, a10, 1
    
    ; Limitar a 255 (8 bits)
    movi a11, 256
    modu a10, a10, a11
    
    call scheduler_yield
    j task_uart_loop
```

### Exemplo 6: Receber Comandos UART

```assembly
task_uart_receiver:
    entry a1, 32
    
task_uart_recv_loop:
    ; Tentar receber caractere
    call uart_getchar
    
    ; Se -1, nenhum dado disponível
    beqi a2, -1, task_uart_recv_yield
    
    ; Processar comando
    beqi a2, 'L', task_uart_cmd_led      ; 'L' = toggle LED
    beqi a2, 'R', task_uart_cmd_reset    ; 'R' = reset
    beqi a2, 'S', task_uart_cmd_status   ; 'S' = status
    
    ; Comando desconhecido
    movi a2, msg_unknown_cmd
    call uart_puts
    j task_uart_recv_yield
    
task_uart_cmd_led:
    ; Toggle LED
    movi a2, GPIO_LED_PIN
    call gpio_toggle
    
    movi a2, msg_cmd_led
    call uart_puts
    j task_uart_recv_yield
    
task_uart_cmd_reset:
    ; Reset (soft)
    movi a2, msg_cmd_reset
    call uart_puts
    
    ; Aqui implementar reset lógico
    j task_uart_recv_yield
    
task_uart_cmd_status:
    ; Enviar status
    movi a2, msg_cmd_status
    call uart_puts
    
    ; Ler contadores do sistema
    movi a10, SCHED_STATE_BASE
    l32i a2, a10, CURRENT_TASK_ID_OFFSET
    call uart_print_hex
    
    j task_uart_recv_yield
    
task_uart_recv_yield:
    call scheduler_yield
    j task_uart_recv_loop
```

---

## Timer e Preempção

### Exemplo 7: Medir Tempo com Timer

```assembly
task_timer_measurement:
    entry a1, 32
    
    ; Inicializar timer em 1ms
    movi a2, 1000           ; 1000 us = 1 ms
    call timer_init
    call timer_start
    
    movi a10, 0             ; Contador de ticks
    
task_timer_loop:
    ; Incrementar contador a cada tick
    addi a10, a10, 1
    
    ; A cada 1000 ticks (1 segundo aprox)
    movi a11, 1000
    bne a10, a11, task_timer_continue
    
    ; Reset
    movi a10, 0
    
    ; Log
    movi a2, msg_timer_tick
    call uart_puts
    
task_timer_continue:
    call scheduler_yield
    j task_timer_loop
```

---

## Padrões Avançados

### Exemplo 8: Produtor-Consumidor com Buffer Circular

```assembly
task_producer:
    entry a1, 32
    
    movi a10, 0             ; Buffer write pointer
    movi a11, 0             ; Dados a produzir
    movi a12, 0x3FFC0000    ; Buffer base
    
task_producer_loop:
    ; Gerar dado
    addi a11, a11, 1
    andi a11, a11, 0xFF     ; Manter em 8 bits
    
    ; Escrever no buffer
    s8i a11, a12, a10
    
    ; Incrementar pointer
    addi a10, a10, 1
    movi a13, 256           ; Buffer size
    modu a10, a10, a13
    
    call scheduler_yield
    j task_producer_loop

task_consumer:
    entry a1, 32
    
    movi a10, 0             ; Buffer read pointer
    movi a12, 0x3FFC0000    ; Buffer base (mesmo do produtor)
    
task_consumer_loop:
    ; Ler do buffer
    l8ui a2, a12, a10
    
    ; Processar
    call uart_putchar
    
    ; Incrementar pointer
    addi a10, a10, 1
    movi a13, 256           ; Buffer size
    modu a10, a10, a13
    
    call scheduler_yield
    j task_consumer_loop
```

### Exemplo 9: Tarefa com Sincronização

```assembly
task_synchronized_a:
    entry a1, 32
    
task_sync_a_loop:
    ; Esperar semáforo
    movi a2, SEMA_FLAG_BASE
    l32i a3, a2, 0
    beqi a3, 0, task_sync_a_loop   ; Busy wait (simplificado)
    
    ; Adquirir semáforo
    movi a3, 0
    s32i a3, a2, 0
    
    ; Seção crítica
    movi a2, msg_critical_a
    call uart_puts
    
    ; Simular trabalho
    movi a10, 50000
    movi a11, 0
    movi a12, 0
task_sync_a_work:
    addi a11, a11, 1
    blt a11, a10, task_sync_a_work
    
    ; Liberar semáforo
    movi a3, 1
    movi a2, SEMA_FLAG_BASE
    s32i a3, a2, 0
    
    call scheduler_yield
    j task_sync_a_loop
```

---

## Tratamento de Erros

### Exemplo 10: Stack Overflow Detection

```assembly
task_stack_monitor:
    entry a1, 32
    
task_stack_monitor_loop:
    ; Verificar SP está em range válido
    ; Para Task 0: 0x3FFB0000 - 0x3FFB4000
    
    movi a2, 0x3FFB0000
    movi a3, 0x3FFB4000
    
    ; SP em a1
    blt a1, a2, task_stack_overflow
    bge a1, a3, task_stack_overflow
    
    j task_stack_monitor_continue
    
task_stack_overflow:
    movi a2, msg_stack_overflow
    call uart_puts
    
    ; Halt
    j task_stack_overflow
    
task_stack_monitor_continue:
    call scheduler_yield
    j task_stack_monitor_loop
```

### Exemplo 11: Watchdog Simples

```assembly
task_watchdog:
    entry a1, 32
    
    movi a10, 0             ; Contador
    movi a11, 10000         ; Timeout
    
task_watchdog_loop:
    ; Incrementar
    addi a10, a10, 1
    
    ; Verificar timeout
    blt a10, a11, task_watchdog_continue
    
    ; Timeout! Sistema travou
    movi a2, msg_watchdog_triggered
    call uart_puts
    
    ; Reset:
    movi a10, 0
    
task_watchdog_continue:
    call scheduler_yield
    j task_watchdog_loop
```

---

## Debugging

### Exemplo 12: Task Tracer

```assembly
task_tracer:
    entry a1, 32
    
    movi a10, 0             ; Última task ID
    
task_tracer_loop:
    ; Ler task ID atual
    movi a2, SCHED_STATE_BASE
    l32i a2, a2, CURRENT_TASK_ID_OFFSET
    
    ; Se mudou, log
    bne a2, a10, task_tracer_changed
    j task_tracer_continue
    
task_tracer_changed:
    mov a10, a2
    
    movi a2, msg_task_switch
    call uart_puts
    
    mov a2, a10
    call uart_print_hex
    
    movi a2, msg_newline
    call uart_puts
    
task_tracer_continue:
    call scheduler_yield
    j task_tracer_loop
```

### Exemplo 13: Performance Counter

```assembly
task_performance:
    entry a1, 32
    
    movi a10, 0             ; Total iterations
    movi a11, 0             ; Report counter
    
task_perf_loop:
    addi a10, a10, 1
    addi a11, a11, 1
    
    ; A cada 1M iterações, reportar
    movi a12, 1000000
    bne a11, a12, task_perf_continue
    
    ; Reset counter
    movi a11, 0
    
    ; Enviar IPS (iterations per second)
    movi a2, msg_perf_iters
    call uart_puts
    
    mov a2, a10
    call uart_print_hex
    
    movi a2, msg_newline
    call uart_puts
    
task_perf_continue:
    call scheduler_yield
    j task_perf_loop
```

---

## Strings de Mensagens

```assembly
.section .rodata

msg_counter_reached:
    .string "[COUNTER] Reached 1000\r\n"

msg_led_switched:
    .string "[LED] Switched\r\n"

msg_button_change:
    .string "[BUTTON] Change count: "

msg_uart_header:
    .string "[DATA] 0x"

msg_uart_sep:
    .string " | "

msg_unknown_cmd:
    .string "[ERROR] Unknown command\r\n"

msg_cmd_led:
    .string "[CMD] LED toggled\r\n"

msg_cmd_reset:
    .string "[CMD] Resetting...\r\n"

msg_cmd_status:
    .string "[STATUS] Task ID: "

msg_timer_tick:
    .string "[TIMER] 1 second elapsed\r\n"

msg_critical_a:
    .string "[CRITICAL] Task A\r\n"

msg_stack_overflow:
    .string "[ERROR] Stack Overflow!\r\n"

msg_watchdog_triggered:
    .string "[WATCHDOG] Triggered - Reset\r\n"

msg_task_switch:
    .string "[TRACE] Task: "

msg_perf_iters:
    .string "[PERF] Iterations: "

msg_newline:
    .string "\r\n"
```

---

## Como Usar Estes Exemplos

1. **Copiar código** do exemplo desejado
2. **Criar novo arquivo** em `src/tasks/example_*.s`
3. **Adicionar ao Makefile** para compilar
4. **Registrar no bootloader** para executar
5. **Testar no ESP32** com `make flash && make monitor`

---

## Checklist de Implementação

- [ ] Compilar cada exemplo individualmente
- [ ] Testar integração com drivers
- [ ] Verificar consumo de stack
- [ ] Medir performance (IPS)
- [ ] Validar sincronização entre tarefas
- [ ] Testar tratamento de erros

---

**Última atualização:** 2026-06-03
**Status:** Pronto para produção ✅
