# PadelScore — App de Padel (Flutter + Supabase)

Aplicativo para gerenciar torneios de padel: cadastro de jogadores, grupos (patotas), registro de jogos por set e ranking.

Stack principal:
- Flutter 3.35.x (Material 3) e Dart 3.6+
- Supabase (auth, storage e Postgres)
- MVVM com Provider + GoRouter
- MCPs: pg (Postgres), supabase (API), context7 (contexto)

## Requisitos
- macOS Apple Silicon (M2) com Flutter 3.35.x via FVM (recomendado)
- Dart 3.6+
- Projeto Supabase configurado e credenciais válidas

## Setup rápido
1) Validar versão
   ```bash
   fvm flutter --version
   # ou
   flutter --version
   ```
2) Instalar dependências
   ```bash
   flutter pub get
   ```
3) Configurar ambiente
   - Editar `assets/config/app_config.json` conforme endpoints/keys locais.
   - Perfis Trae: `dev`, `dev_ios`, `beta`, `prod` em `.trae/config.json` usam `dart_defines.*.json`.
4) Executar (web)
   ```bash
   flutter run -d chrome
   ```
5) Executar (iOS — simulador)
   ```bash
   flutter run -d ios
   ```

## Perfis e Configurações de Ambiente
- Perfis definidos em `.trae/config.json`:
  - `dev`, `dev_ios`, `beta`, `prod` com `dart_defines.<env>.json`.
- Centralização de config: `core/config/app_config.dart` lê `assets/config/app_config.json`.
- Ao adicionar variáveis, prefira os arquivos `dart_defines.<env>.json` para consistência.

## Arquitetura
- Feature-based (MVVM com Provider):
  - `features/auth` — autenticação Supabase e login minimalista.
  - `features/players` — modelos tipados e UI de jogadores.
  - `features/patotas` — grupos/clubes (serviços, viewmodels, views).
  - `features/games` — registro de jogo, composição por set e resumo.
  - `features/home` — visão geral e ações rápidas.
- Core:
  - `core/router/app_router.dart` — GoRouter com redirects de autenticação.
  - `core/config/app_config.dart` — gestão central de ambiente.
- Padrões:
  - Modularização de widgets, um widget público por arquivo.
  - Imports relativos, nomes em `snake_case` para arquivos.

## Autenticação
- Fluxo de login minimalista com botões: Google, Apple, Facebook.
- Redirecionamento via GoRouter: `/login` ↔ rota pretendida.
- Supabase Flutter para PKCE e sessão; deep links ajustados quando necessário.

## Qualidade
- Análise:
  ```bash
  flutter analyze
  ```
- Formatação:
  ```bash
  dart format .
  ```
- Build Runner (se aplicável):
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

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

---

## Comandos úteis
- Rodar web: `flutter run -d chrome`
- Rodar iOS (simulador): `flutter run -d ios`
- Atualizar dependências: `flutter pub get`
- Build Runner: `dart run build_runner build --delete-conflicting-outputs`
- Analyzer: `flutter analyze`

## Contribuição
- Mensagens de commit no padrão Conventional Commits (ex.: `feat:`, `fix:`, `docs:`).
- Branches: `develop` para trabalho contínuo; `main` para releases.
- Pull Requests com descrição objetiva e checklist de qualidade.

## Troubleshooting
- Sem remoto Git:
  ```bash
  git remote add origin <URL>
  git push -u origin develop
  ```
- Erros de versão do Flutter/Dart: verifique FVM e `flutter --version`.
- Credenciais Supabase: revisitar `assets/config/app_config.json` e defines.
