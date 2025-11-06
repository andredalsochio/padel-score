Each entry must include:
- Task or feature name  
- Status of each step (✅ Done / 🔄 In Progress / ⏳ Pending)  
- File paths or modules modified  
- Timestamp of the last update  

### Workflow Model

We track work in three phases for each feature/task:
- Investigation — audit code, dependencies, MCP config, and constraints.
- Plan — define steps, risks, and acceptance criteria.
- Execution — implement changes, run quality gates, and record adjustments.

### Tags and Conventions
- ✅ Done — fully completed step; passes quality gate.
- 🔄 In Progress — currently being implemented.
- ⏳ Pending — planned but not started.
- 🧩 Adjustment Notes — deviations or optimizations introduced.

### Tools & Collaboration
- Codex/Trae MCPs:
  - `pg` for DB schema and migrations.
  - `supabase` for API/auth/storage validation.
  - `context7` for context enrichment.
- Collaboration Flow:
  - AI proposes Investigation → Plan → Execution updates.
  - Human can comment or request changes; AI integrates feedback in Plan and
    Execution, then updates this file.
  - For UI changes, AI opens preview before marking as ✅.

#### 4. Session Recovery
When a session restarts or reconnects, the AI must automatically read from  
`.trae/workflow_progress.md` and continue from the last recorded step.

#### 5. Adjustment Notes
If any deviation or optimization is introduced during execution, it must be logged under  
a “🧩 Adjustment Notes” section in the same document, describing what changed and why.

#### 6. Verificação pós‑tarefa (Quality Gate)
Ao finalizar qualquer tarefa:
- Execute `flutter analyze`.
- Corrija todos os erros e warnings reportados pelo analyzer antes de marcar a tarefa como concluída.
- Registre no “🧩 Adjustment Notes” quaisquer alterações aplicadas para resolver problemas do analyzer.

---

## Feature: Login Screen (Supabase Auth)

- Status geral: 🔄 In Progress
- Última atualização: 2025-11-04T00:00:00Z

### Passos e Status
- ✅ Adicionar dependências: `supabase_flutter`, `provider`, `go_router`
- 🔄 Configurar Supabase e Provider em `main.dart`
- 🔄 Configurar `go_router` com rotas `/login` e `/home` e redirect
- 🔄 Implementar `LoginScreen` com animação e feedback de erro/carregamento
- ⏳ Criar integração completa de sessão e testes de redirecionamento em web/mobile
- ⏳ Rodar app na web e abrir preview para validar UI

### Arquivos modificados/criados
- M `lib/main.dart`
- A `lib/core/router/app_router.dart`
- A `lib/features/auth/service/auth_service.dart`
- A `lib/features/auth/viewmodel/auth_view_model.dart`
- A `lib/features/auth/view/login_screen.dart`
- A `lib/features/home/view/home_screen.dart`
- M `pubspec.lock` (via `flutter pub add`)

### 🧩 Adjustment Notes
- Optamos por `go_router` para redirects declarativos de autenticação, garantindo fluxo simples e consistente com web.
- Mobile: usamos o esquema padrão `io.supabase.flutter://login-callback/` suportado por `supabase_flutter` para PKCE; ajustes no AndroidManifest/Info.plist serão feitos quando integrarmos deep links explicitamente.
- Mantivemos o tema básico Material 3 aqui; fontes e personalizações avançadas ficam para uma etapa posterior, mantendo foco na autenticação e UX minimalista.

---

## Feature: Registro de Jogo — Composição por Set e Pontuação

- Status geral: 🔄 In Progress
- Última atualização: 2025-11-06T00:00:00Z

### Passos e Status
- ✅ Modelos tipados: `AssignedPlayer`, `SetAssignment`, `SetScore`
- ✅ ViewModel: exposição de `setAssignments`, preload por set (`ensureAssignmentLoaded`) e mapeamento de placar inicial
- ✅ UI: `SetCard` recebe `players`, `assignment` e `onSetPlayerTeam`; gating por mínimo de 4 jogadores
- ✅ Resumo: `SetsSummary` e `GameSummaryCard` atualizados para trabalhar com `SetScore` e validação de composição
- ✅ Persistência: tabela `score_set_players` criada e RPC `save_game_with_sets` disponível no Supabase
- ✅ Execução: app rodando em web (`flutter run -d chrome`) com preview aberto
- 🔄 Documentação: adicionar snippet no README com instruções de migração e rollback
- ⏳ Quality Gate: executar `flutter analyze` e corrigir eventuais avisos/erros

### Arquivos modificados/criados
- M `lib/features/games/register/view/register_game_screen.dart`
- M `lib/features/games/register/widgets/players_section.dart`
- M `lib/features/games/register/widgets/set_card.dart` (se aplicável no workspace)
- M `lib/features/games/register/widgets/sets_summary.dart`
- M `lib/features/games/register/widgets/game_summary_card.dart`
- M `lib/features/games/register/viewmodels/register_game_view_model.dart`
- A (Supabase) `public.score_set_players` (PK composta, FKs para `games` e `players`)
- A (Supabase) RPC `public.save_game_with_sets` (plpgsql)

### 🧩 Adjustment Notes
- Unificação de `PlayerModel`: removida duplicação em `game_models.dart` e uso consolidado do modelo em `features/players/data`.
- Regra de mínimo de jogadores atualizada para 4 para refletir duplas de padel; `PlayersSection` exibe mensagem correspondente.
- Evitamos dependência de `surfaceVariant` (deprecado) e utilizamos `colorScheme.surfaceContainer*` quando apropriado.
- Mantivemos responsividade e ergonomia nas seções utilitárias (registro rápido), priorizando clareza.

---

## Documentation Updates — November 2025

- ✅ Investigation: audit de estrutura (`lib/features`, `core/router`, `pubspec.yaml`), perfis Trae e MCPs.
- ✅ Plan: ajustes incrementais nos três arquivos com foco em alinhamento e não reescrita total.
- ✅ Execution:
  - Atualizado `AGENTS.md` com addendum de alinhamento (módulos, Provider, Supabase/go_router, Material 3, ordem MCP, FVM/perfis Trae).
  - Atualizado `.trae/rules/project_rules.md` com módulos, ambiente, ordem MCP, roteamento e notas de deploy.
  - Atualizado `.trae/rules/workflow_progress.md` com modelo de workflow, tags e colaboração AI/humano.
- 🧩 Adjustment Notes:
  - Optamos por adicionar addendum no `AGENTS.md` ao invés de reescrever seções longas para reduzir risco de divergência e manter compatibilidade com regras globais.
  - Mantivemos entradas de features existentes e adicionamos uma seção de workflow e documentação ao final para preservar histórico.