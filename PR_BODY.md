# Pull Request Body — Add critical-section variants, demo tasks and tests

## Resumo

Este PR adiciona e melhora mecanismos de proteção de seções críticas e inclui demonstrações e testes para validar o comportamento:

- Macros de seção crítica aprimoradas (src/utils/macros.s):
  - `CRITICAL_SECTION_START` / `CRITICAL_SECTION_END` — salva/restaura SR (suporta aninhamento)
  - `CRITICAL_SECTION_ISR_START` / `CRITICAL_SECTION_ISR_END` — variante ISR-safe (não empilha SR)
  - `DISABLE_INTERRUPTS_PRESERVE` / `ENABLE_INTERRUPTS_PRESERVE` — preservam temporários `a14`/`a15`

- Exemplos e demos:
  - `src/tasks/demo_critical_examples.s` — três tarefas de demonstração: nested, ISR-style, preserve-temporaries
  - `src/tasks/task_template.s` — template atualizado demonstrando o uso das macros

- Testes e utilitários:
  - `src/tests/test_critical_section.s` — tarefa embarcada que imprime SR antes/depois e demonstra aninhamento
  - `tests/serial_validate.py` — validador host-side (usa pyserial) que lê a serial e valida padrões esperados
  - `build/verify_critical_section.sh` — script simples para compilar (não faz flash)

## Como testar (passos rápidos)

1. Compilar (ou usar o script de verificação):

```bash
cd build
make all
# ou, na raiz do repositório:
./build/verify_critical_section.sh
```

2. (Opcional) Flash para o ESP32:

```bash
make flash
```

3. Abrir monitor serial:

```bash
make monitor
# ou usar picocom/minicom/whatever na porta /dev/ttyUSB0 @ 115200
```

4. Teste automático no host (requer pyserial):

```bash
pip3 install pyserial
python3 tests/serial_validate.py --port /dev/ttyUSB0 --baud 115200 --timeout 15
```

O validador procura pelas seguintes saídas no serial (exemplos esperados):
- `[TEST] SR before:` seguido por um valor hex
- `[DEMO] inside nested critical`
- `[DEMO] ISR-style demo start`
- `[DEMO] preserve-temporary demo`
- `[TEST] done`

Se todos os padrões forem encontrados dentro do timeout, o validador retorna sucesso.

## Checklist para revisão do PR

- [ ] Código compila (`make all`)
- [ ] As demos aparecem no serial
- [ ] Aninhamento de `CRITICAL_SECTION` restaura SR corretamente (verificação manual ou via `tests/serial_validate.py`)
- [ ] Variantes ISR/PRESERVE não corrompem pilha ou temporários
- [ ] Documentação (README/docs) atualizada

## Notas técnicas e restrições

- As macros "task-safe" dependem de `a1` apontando para a pilha atual da tarefa. Não usar essas macros em contextos sem pilha de tarefa válida (ex.: alguns contextos de bootloader) sem adaptação.
- `CRITICAL_SECTION_ISR` é uma variante simples que manipula o bit IE no SR; para políticas mais finas (por nível de interrupção) adapte conforme necessidade.
- As variantes `*_PRESERVE` empilham automaticamente `a14`/`a15` para reduzir a necessidade de salvamento no caller; balanceie corretamente entradas/saídas de seção crítica.

## Alterações principais (arquivos)

- src/utils/macros.s (modificado)
- src/tasks/task_template.s (modificado)
- src/tasks/demo_critical_examples.s (novo)
- src/tests/test_critical_section.s (novo)
- build/verify_critical_section.sh (novo)
- tests/serial_validate.py (novo)
- docs/EXAMPLES.md, README.md (atualizados)

---

Se desejar que eu ajuste o corpo do PR (título, texto, checklist, exemplos) antes de você criar o PR pela UI, diga quais mudanças quer e eu atualizo este arquivo nesta branch.