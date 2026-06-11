## Convenção de Pilha e Uso de Registradores Temporários

Este projeto usa convenções específicas que afetam macros e context switching; é importante seguir estas regras para evitar corrupção de pilha e perda de estado.

- Registrador usado como stack pointer: a1
  - As macros `PUSH_REG` / `POP_REG` e variantes assumem que `a1` aponta para a próxima posição livre na pilha.
  - As macros implementadas aqui empilham incrementando `a1` (pilha "cresce para cima").
  - Certifique-se de que o bootloader inicializa `a1` de acordo (topo da RAM).

- Temporários usados pelas macros críticas:
  - `a14` e `a15` são usados internamente por várias macros (por exemplo, para manipular SR).
  - Use as variantes `DISABLE_INTERRUPTS_PRESERVE` / `ENABLE_INTERRUPTS_PRESERVE` se o seu código precisar que `a14`/`a15` sejam preservados automaticamente.

- Exemplo de inicialização (bootloader):
  - No bootloader, antes de criar tarefas, defina `a1` com o valor do topo da região de tarefas (ex.: `movi a1, 0x3FFC0000`).

Observação: se você preferir uma convenção em que a pilha cresce para baixo, adapte `PUSH_REG`/`POP_REG` e todas as macros que dependem de `a1` de forma consistente em todo o projeto.
