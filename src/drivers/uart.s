; ============================================================================
; ESP32 RTOS - UART Driver
; Arquivo: src/drivers/uart.s
; Descrição: Driver UART para ESP32 com suporte a comunicação serial
; Arquitetura: Xtensa LX6 (ESP32)
; ============================================================================

    .section .kernel, "ax"
    .global uart_init
    .global uart_putchar
    .global uart_puts
    .global uart_getchar
    .global uart_write_byte
    .global uart_read_byte
    .global uart_isr
    .align 4

; ============================================================================
; Constantes - Registradores UART0 (Base: 0x60000000)
; ============================================================================

UART0_BASE              = 0x60000000

; Registradores UART
UART_FIFO               = 0x00          ; FIFO TX/RX
UART_INT_RAW            = 0x04          ; Interrupções raw
UART_INT_ST             = 0x08          ; Status de interrupções
UART_INT_ENA            = 0x0C          ; Enable de interrupções
UART_INT_CLR            = 0x10          ; Clear de interrupções
UART_CLKDIV             = 0x14          ; Clock divisor
UART_AUTOBAUD           = 0x18          ; Autobaud control
UART_STATUS             = 0x1C          ; Status do UART
UART_CONF0              = 0x20          ; Configuração 0
UART_CONF1              = 0x24          ; Configuração 1
UART_LOWPULSE           = 0x28          ; Lowpulse duration
UART_HIGHPULSE          = 0x2C          ; Highpulse duration
UART_RXD_CNT            = 0x30          ; RX count
UART_FLOW_CONF          = 0x34          ; Flow control
UART_SLEEP_CONF         = 0x38          ; Sleep config
UART_SWFC_CONF          = 0x3C          ; Software flow control
UART_IDLE_CONF          = 0x40          ; Idle config
UART_RS485_CONF         = 0x44          ; RS485 config
UART_AT_CMD_PRECNT      = 0x48          ; AT command precnt
UART_AT_CMD_POSTCNT     = 0x4C          ; AT command postcnt
UART_AT_CMD_GAPTOUT     = 0x50          ; AT command gap timeout
UART_AT_CMD_CHAR        = 0x54          ; AT command character
UART_MEM_CONF           = 0x58          ; Memory config
UART_MEM_TX_STATUS      = 0x5C          ; TX memory status
UART_MEM_RX_STATUS      = 0x60          ; RX memory status
UART_MEM_CNT_STATUS     = 0x64          ; Memory count status
UART_POSPULSE           = 0x68          ; Positive pulse config

; Bits de Status
UART_TXFIFO_CNT_MASK    = 0x0F          ; TX FIFO count
UART_RXFIFO_CNT_MASK    = 0x0F00        ; RX FIFO count
UART_TXFIFO_FULL        = 0x80000000    ; TX FIFO cheio
UART_RXFIFO_EMPTY       = 0x00000001    ; RX FIFO vazio

; Constantes UART
UART_BAUD_RATE          = 115200        ; Baud rate padrão
UART_CLK_FREQ           = 80000000      ; 80 MHz
UART_FIFO_SIZE          = 128           ; 128 bytes FIFO

; ============================================================================
; UART State Structure (armazenado em 0x3FFAC300)
; ============================================================================

UART_STATE_BASE         = 0x3FFAC300
UART_INITIALIZED        = 0x00
UART_RX_ENABLED         = 0x04
UART_TX_ENABLED         = 0x08
UART_BAUD_CONF          = 0x0C
UART_TX_COUNT           = 0x10
UART_RX_COUNT           = 0x14
UART_ERROR_COUNT        = 0x18

; ============================================================================
; uart_init - Inicializar UART0
; Parâmetros: nenhum (usa configurações padrão)
; ============================================================================

uart_init:
    entry a1, 32
    
    ; Salvar a0 (return address)
    mov a10, a0
    
    ; Base do UART
    movi a2, UART0_BASE
    
    ; ========== Configurar divisor de clock ==========
    ; baud_div = (UART_CLK_FREQ / BAUD_RATE) / 16
    ; baud_div = (80000000 / 115200) / 16 = 43 (aproximado)
    
    movi a3, 43             ; Divisor para 115200 baud
    s32i a3, a2, UART_CLKDIV
    
    ; ========== Configurar UART_CONF0 ==========
    ; Bits de configuração:
    ;  - 8 bits de dados
    ;  - 1 stop bit
    ;  - Sem paridade
    
    movi a3, 0x00000000     ; Configuração padrão
    ori a3, a3, 0x0         ; 8 bits (padrão)
    ori a3, a3, 0x0         ; 1 stop bit (padrão)
    s32i a3, a2, UART_CONF0
    
    ; ========== Configurar UART_CONF1 ==========
    ; RX FIFO full threshold
    movi a3, 0x00000000
    ori a3, a3, (100 & 0xFF)  ; Full threshold = 100 bytes
    s32i a3, a2, UART_CONF1
    
    ; ========== Limpar FIFO ==========
    ; Reset RX FIFO
    movi a3, 0x00000000
    ori a3, a3, (1 << 17)   ; UART_RXFIFO_RST
    s32i a3, a2, UART_CONF0
    
    ; Reset TX FIFO
    movi a3, (1 << 18)      ; UART_TXFIFO_RST
    s32i a3, a2, UART_CONF0
    
    ; ========== Limpar interrupções ==========
    movi a3, 0xFFFFFFFF     ; Limpar todas as interrupções
    s32i a3, a2, UART_INT_CLR
    
    ; ========== Habilitar interrupções ==========
    ; RX FIFO full interrupt
    movi a3, 0x00000000
    ori a3, a3, (1 << 0)    ; UART_RXFIFO_FULL_INT_ENA
    s32i a3, a2, UART_INT_ENA
    
    ; ========== Inicializar estado UART ==========
    movi a3, UART_STATE_BASE
    
    ; UART_INITIALIZED = 1
    movi a4, 1
    s32i a4, a3, UART_INITIALIZED
    
    ; UART_RX_ENABLED = 1
    s32i a4, a3, UART_RX_ENABLED
    
    ; UART_TX_ENABLED = 1
    s32i a4, a3, UART_TX_ENABLED
    
    ; UART_BAUD_CONF = UART_BAUD_RATE
    movi a4, UART_BAUD_RATE
    s32i a4, a3, UART_BAUD_CONF
    
    ; Contadores = 0
    movi a4, 0
    s32i a4, a3, UART_TX_COUNT
    s32i a4, a3, UART_RX_COUNT
    s32i a4, a3, UART_ERROR_COUNT
    
    retw

; ============================================================================
; uart_putchar - Enviar um caractere
; Parâmetro: a2 = caractere a enviar
; ============================================================================

uart_putchar:
    entry a1, 16
    
    ; a2 = caractere
    ; a3 = base UART
    movi a3, UART0_BASE
    
uart_putchar_wait:
    ; Verificar se TX FIFO está cheio
    l32i a4, a3, UART_STATUS
    
    ; Extrair TX FIFO count (bits 15:8)
    srai a5, a4, 8
    andi a5, a5, 0x0F
    
    ; Se TX FIFO count < 128, pode enviar
    movi a6, 128
    bge a5, a6, uart_putchar_wait    ; Aguardar se cheio
    
    ; Enviar caractere para FIFO
    s32i a2, a3, UART_FIFO
    
    ; Incrementar TX count
    movi a4, UART_STATE_BASE
    l32i a5, a4, UART_TX_COUNT
    addi a5, a5, 1
    s32i a5, a4, UART_TX_COUNT
    
    retw

; ============================================================================
; uart_puts - Enviar string (terminada em \0)
; Parâmetro: a2 = ponteiro para string
; ============================================================================

uart_puts:
    entry a1, 24
    
    ; a2 = ponteiro para string
    ; a3 = caractere atual
    
uart_puts_loop:
    ; Ler caractere
    l8ui a3, a2, 0
    
    ; Verificar se é fim de string
    beqi a3, 0, uart_puts_done
    
    ; Enviar caractere
    mov a2, a3
    call uart_putchar
    
    ; Recuperar ponteiro e incrementar
    addi a2, a2, 1
    j uart_puts_loop
    
uart_puts_done:
    retw

; ============================================================================
; uart_getchar - Receber um caractere
; Retorna: a2 = caractere recebido (ou -1 se nenhum disponível)
; ============================================================================

uart_getchar:
    entry a1, 16
    
    movi a3, UART0_BASE
    
    ; Verificar se há dados no RX FIFO
    l32i a4, a3, UART_STATUS
    
    ; Extrair RX FIFO count (bits 11:8)
    srai a5, a4, 8
    andi a5, a5, 0x0F
    
    ; Se RX FIFO count == 0, sem dados
    beqi a5, 0, uart_getchar_empty
    
    ; Ler caractere do FIFO
    l32i a2, a3, UART_FIFO
    andi a2, a2, 0xFF       ; Mascarar para 8 bits
    
    ; Incrementar RX count
    movi a4, UART_STATE_BASE
    l32i a5, a4, UART_RX_COUNT
    addi a5, a5, 1
    s32i a5, a4, UART_RX_COUNT
    
    j uart_getchar_done
    
uart_getchar_empty:
    ; Retornar -1
    movi a2, -1
    
uart_getchar_done:
    retw

; ============================================================================
; uart_write_byte - Versão de uart_putchar (alias)
; Parâmetro: a2 = byte
; ============================================================================

uart_write_byte:
    entry a1, 16
    
    call uart_putchar
    
    retw

; ============================================================================
; uart_read_byte - Versão de uart_getchar com espera
; Retorna: a2 = byte recebido
; ============================================================================

uart_read_byte:
    entry a1, 16
    
uart_read_byte_loop:
    call uart_getchar
    
    ; Se a2 == -1, aguardar
    beqi a2, -1, uart_read_byte_loop
    
    retw

; ============================================================================
; uart_isr - Interrupt Service Routine para UART
; ============================================================================

uart_isr:
    entry a1, 32
    
    movi a2, UART0_BASE
    
    ; Ler status de interrupção
    l32i a3, a2, UART_INT_ST
    
    ; Verificar RX FIFO full interrupt (bit 0)
    andi a4, a3, 0x01
    beqi a4, 0, uart_isr_tx_check
    
    ; Handler RX FIFO
    ; TODO: Procesar dados recebidos
    
uart_isr_tx_check:
    ; Verificar TX FIFO empty interrupt (bit 1)
    andi a4, a3, 0x02
    beqi a4, 0, uart_isr_done
    
    ; Handler TX FIFO
    ; TODO: Continuar transmissão se necessário
    
uart_isr_done:
    ; Limpar interrupções processadas
    s32i a3, a2, UART_INT_CLR
    
    retw

; ============================================================================
; uart_wait_tx_done - Aguardar transmissão completar
; ============================================================================

uart_wait_tx_done:
    entry a1, 16
    
    movi a2, UART0_BASE
    
uart_wait_tx_loop:
    ; Ler status
    l32i a3, a2, UART_STATUS
    
    ; Verificar se TX FIFO está vazio (bit 0)
    andi a4, a3, 0x01
    beqi a4, 0, uart_wait_tx_loop
    
    retw

; ============================================================================
; uart_flush_rx - Limpar buffer RX
; ============================================================================

uart_flush_rx:
    entry a1, 16
    
    movi a2, UART0_BASE
    
uart_flush_rx_loop:
    ; Ler caractere
    call uart_getchar
    
    ; Se -1, buffer vazio
    beqi a2, -1, uart_flush_rx_done
    
    j uart_flush_rx_loop
    
uart_flush_rx_done:
    retw

; ============================================================================
; uart_set_baud - Configurar baud rate
; Parâmetro: a2 = baud rate desejado
; ============================================================================

uart_set_baud:
    entry a1, 16
    
    ; a2 = baud rate
    ; Calcular divisor: div = (UART_CLK_FREQ / baud) / 16
    
    ; Simplificado: usar lookup table ou cálculo
    ; Para agora, assumir 115200
    
    movi a3, UART0_BASE
    movi a4, 43             ; Divisor para 115200
    s32i a4, a3, UART_CLKDIV
    
    retw

; ============================================================================
; Debug Functions
; ============================================================================

; Enviar número em hex
uart_print_hex:
    ; a2 = número
    entry a1, 24
    
    ; Salvar número
    mov a3, a2
    
    ; Prefixo "0x"
    movi a2, '0'
    call uart_putchar
    movi a2, 'x'
    call uart_putchar
    
    ; Processar 8 dígitos hex (4 bits cada)
    movi a4, 28             ; Deslocamento inicial (28 bits)
    movi a5, 8              ; 8 dígitos
    
uart_print_hex_loop:
    ; Extrair 4 bits
    l32i a6, a3, 0
    sra a6, a6, a4
    andi a6, a6, 0x0F
    
    ; Converter para ASCII
    addi a6, a6, '0'
    blt a6, '9' + 1, uart_print_hex_digit
    addi a6, a6, 7          ; A-F offset
    
uart_print_hex_digit:
    mov a2, a6
    call uart_putchar
    
    addi a4, a4, -4
    addi a5, a5, -1
    bgez a4, uart_print_hex_loop
    
    retw

    .end