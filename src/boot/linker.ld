/* ============================================================================
 * ESP32 RTOS - Linker Script
 * Arquivo: src/boot/linker.ld
 * Descrição: Script de linkagem para ESP32 com layout de memória
 * Arquitetura: Xtensa LX6 (ESP32)
 * ============================================================================ */

MEMORY
{
  /* IROM (Instruction ROM - Flash) - Código executável */
  irom0_0_seg (RX)  : org = 0x40200000, len = 0x300000  /* 3 MB */
  
  /* IRAM (Instruction RAM - SRAM) - Código rápido */
  iram0_0_seg (RWX) : org = 0x40080000, len = 0x20000   /* 128 KB */
  
  /* DRAM (Data RAM - SRAM) - Dados */
  dram0_0_seg (RW)  : org = 0x3FFB0000, len = 0x50000   /* 320 KB */
  
  /* RTC RAM - Memória remanescente em deep sleep */
  rtc_iram_seg (RW) : org = 0x400C0000, len = 0x2000    /* 8 KB */
  rtc_dram_seg (RW) : org = 0x50000000, len = 0x2000    /* 8 KB */
}

/* Configurações de saída */
OUTPUT_FORMAT("elf32-xtensa-le")
OUTPUT_ARCH(xtensa)
ENTRY(boot_entry)

SECTIONS
{
  /* ========================================
   * Seção de Boot
   * ======================================== */
  .text.boot :
  {
    *(.text.boot)
    *(.text.boot.*)  
  } > irom0_0_seg
  
  /* ========================================
   * Seções de Código
   * ======================================== */
  .text :
  {
    KEEP(*(.text.entry))
    *(.text)
    *(.text.*)
    *(.gnu.linkonce.t.*)
    
    /* Funções críticas no IRAM (rápido) */
    *(.iram1 .iram1.*)
    
    /* Handlers de interrupção - devem estar no IRAM */
    *(.isr_vector)
    *(.interrupt_handlers)
    
    /* Scheduler e context switch - crítico */
    *(.scheduler.*)
    *(.context.*)
  } > irom0_0_seg
  
  /* ========================================
   * Seção de Dados Inicializados
   * ======================================== */
  .data :
  {
    _data_start = ABSOLUTE(.);
    
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    
    /* Drivers */
    *(.drivers.*)
    
    /* Tarefas */
    *(.tasks.*)
    
    _data_end = ABSOLUTE(.);
  } > dram0_0_seg AT > irom0_0_seg
  
  /* Mapa de dados em memória de programa (para inicialização) */
  _data_lma = LOADADDR(.data);
  _data_size = _data_end - _data_start;
  
  /* ========================================
   * Seção de Dados Não-inicializados (BSS)
   * ======================================== */
  .bss (NOLOAD) :
  {
    _bss_start = ABSOLUTE(.);
    
    *(.bss)
    *(.bss.*)
    *(.gnu.linkonce.b.*)
    
    /* Buffers de tarefas */
    *(.task_stacks)
    
    /* Buffers de drivers */
    *(.driver_buffers)
    
    /* COMMON symbols */
    *(COMMON)
    
    _bss_end = ABSOLUTE(.);
  } > dram0_0_seg
  
  /* ========================================
   * Seção de Dados Somente-leitura
   * ======================================== */
  .rodata :
  {
    _rodata_start = ABSOLUTE(.);
    
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r.*)
    
    /* Strings de mensagens */
    *(.message_strings)
    
    /* Tabelas de configuração */
    *(.config_tables)
    
    _rodata_end = ABSOLUTE(.);
  } > irom0_0_seg
  
  /* ========================================
   * Seção de Testes (debug)
   * ======================================== */
  .tests :
  {
    *(.tests)
    *(.tests.*)
  } > irom0_0_seg
  
  /* ========================================
   * Seção de Kernel/Scheduler
   * ======================================== */
  .kernel :
  {
    _kernel_start = ABSOLUTE(.);
    
    *(.kernel.*)
    *(.scheduler.*)
    
    _kernel_end = ABSOLUTE(.);
  } > irom0_0_seg
  
  /* ========================================
   * Seção de Drivers
   * ======================================== */
  .drivers :
  {
    _drivers_start = ABSOLUTE(.);
    
    *(.drivers.*)
    *(.gpio.*)
    *(.uart.*)
    *(.timer.*)
    *(.interrupt.*)
    
    _drivers_end = ABSOLUTE(.);
  } > irom0_0_seg
  
  /* ========================================
   * Stack
   * ======================================== */
  .stack (NOLOAD) :
  {
    _stack_start = ABSOLUTE(.);
    . += 0x1000;  /* 4 KB para stack principal */
    _stack_end = ABSOLUTE(.);
  } > dram0_0_seg
  
  /* ========================================
   * Heap
   * ======================================== */
  .heap (NOLOAD) :
  {
    _heap_start = ABSOLUTE(.);
    . = ALIGN(0x10);  /* Alinhar para 16 bytes */
    _heap_end = ABSOLUTE(.);
  } > dram0_0_seg
  
  /* ========================================
   * RTC RAM (para dados que persistem em sleep)
   * ======================================== */
  .rtc.bss (NOLOAD) :
  {
    _rtc_data_start = ABSOLUTE(.);
    *(.rtc.bss)
    *(.rtc.data)
    _rtc_data_end = ABSOLUTE(.);
  } > rtc_dram_seg
  
  /* ========================================
   * Seções especiais
   * ======================================== */
  
  /* Tabela de símbolos GNU */
  .symtab : { *(.symtab) }
  .strtab : { *(.strtab) }
  .shstrtab : { *(.shstrtab) }
  
  /* Informações de debug (se incluído) */
  .debug_info (NOLOAD) : { *(.debug_info) }
  .debug_line (NOLOAD) : { *(.debug_line) }
  .debug_str (NOLOAD) : { *(.debug_str) }
  .debug_ranges (NOLOAD) : { *(.debug_ranges) }
  .debug_loc (NOLOAD) : { *(.debug_loc) }
  
  /* Seções não utilizadas */
  /DISCARD/ :
  {
    *(.note.GNU-stack)
    *(.gnu.lto_*)
    *(.gnu_debuglink)
    *(.gnu_debugdata)
  }
}

/* ============================================================================
 * Símbolos globais de memória
 * ============================================================================ */

/* Fim do IRAM */
_iram_end = ORIGIN(iram0_0_seg) + LENGTH(iram0_0_seg);

/* Fim do DRAM */
_dram_end = ORIGIN(dram0_0_seg) + LENGTH(dram0_0_seg);

/* Tamanho total de código */
_code_size = _data_lma + _data_size;

/* ============================================================================
 * Seções de Memória Dinâmica para RTOS
 * ============================================================================ */

/* Espaço para pilhas de tarefas (4 tarefas x 16KB cada = 64KB) */
TASK_STACK_SIZE = 0x4000;  /* 16 KB por tarefa */
MAX_TASKS_COUNT = 4;

/* Endereços de TCB (Task Control Block) */
TCB_ARRAY = 0x3FFAC000;
TCB_SIZE = 128;

/* Buffers de drivers */
UART_BUFFER = 0x3FFAD000;
UART_BUFFER_SIZE = 0x1000;  /* 4 KB */

GPIO_STATE = 0x3FFAD400;
GPIO_STATE_SIZE = 0x100;    /* 256 bytes */

TIMER_STATE = 0x3FFAD500;
TIMER_STATE_SIZE = 0x100;   /* 256 bytes */

/* Áreas de heap para alocação dinâmica */
HEAP_START = 0x3FFAE000;
HEAP_SIZE = 0x12000;         /* 72 KB para heap */

/* ============================================================================
 * Validações e verificações
 * ============================================================================ */

/* Verificar se o código cabe em IROM */
ASSERT(_data_lma + _data_size <= ORIGIN(irom0_0_seg) + LENGTH(irom0_0_seg),
       "Código é maior que IROM disponível")

/* Verificar se dados cabem em DRAM */
ASSERT(_bss_end <= ORIGIN(dram0_0_seg) + LENGTH(dram0_0_seg),
       "Dados são maiores que DRAM disponível")

/* Verificar se stack não sobrescreve dados */
ASSERT(_stack_end <= ORIGIN(dram0_0_seg) + LENGTH(dram0_0_seg),
       "Stack ultrapassa fim da DRAM")
