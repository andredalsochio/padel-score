# padel_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Banco de Dados: Composição por Set e RPC de Salvamento

Este projeto utiliza Supabase para persistir a composição de jogadores por set e os placares do jogo.

### Visão geral
- Tabela: `public.score_set_players` — armazena, por jogo e por set, quais jogadores jogaram e em qual time.
- RPC: `public.save_game_with_sets` — função PL/pgSQL para salvar um jogo e seus sets de forma transacional.

### Pré‑requisitos
- Supabase configurado e acessível via MCP (pg/supabase) ou CLI.
- Flutter 3.35+ e Dart 3.6+ (idealmente via FVM).

### Como verificar se a migração está aplicada
- Via MCP (preferido): listar tabelas e checar a função
  - Tabela: `score_set_players` deve existir com PK composta `(game_id, set_index, player_id)` e FKs para `games` e `players`.
  - Função: `save_game_with_sets` deve aparecer em `public`.
- Via CLI Supabase:
  ```bash
  supabase db dump --local | grep score_set_players
  # ou inspecione no Studio > Database
  ```

### SQL (resumo) da tabela `score_set_players`
```sql
create table if not exists public.score_set_players (
  game_id uuid not null references public.games(id),
  set_index integer not null check (set_index >= 0),
  player_id uuid not null references public.players(id),
  team integer check (team = any (array[1,2])),
  primary key (game_id, set_index, player_id)
);
```

Observação: RLS pode permanecer desabilitado se o acesso for apenas via funções RPC autenticadas pelo backend; habilite conforme necessidade de segurança.

### Habilitar o fluxo no app
- O `RegisterGameViewModel` já integra os modelos tipados (`AssignedPlayer`, `SetAssignment`, `SetScore`) e carrega as composições por set (`ensureAssignmentLoaded`).
- A UI (`SetCard`, `SetsSummary`, `GameSummaryCard`) já utiliza os tipos e validações atualizados.
- Nenhuma ação adicional é necessária além de configurar corretamente as credenciais do Supabase.

### Rollback seguro
Caso precise reverter a migração:
```sql
-- Remover RPC se necessário
drop function if exists public.save_game_with_sets cascade;

-- Remover a tabela de composição por set
drop table if exists public.score_set_players cascade;
```

Execute o rollback apenas em ambientes de desenvolvimento ou em produção com janela de manutenção e backups prévios.

### Próximos passos opcionais
- Adicionar controle de `bestOf` (1/3/5) com `SegmentedButton` e feedback visual.
- Melhorar o feedback de composição válida/ inválida por set com estados e ícones.
- Considerar transações em lote no app quando offline, com sincronização posterior.
