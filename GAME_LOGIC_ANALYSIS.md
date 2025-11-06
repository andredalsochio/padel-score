# Análise da Lógica de Registro de Jogos — PadelScore

Este documento descreve de forma abrangente a implementação atual do fluxo de registro de jogos no app, cobrindo estrutura de código, modelos, fluxo lógico, problemas e oportunidades de melhoria. A análise segue o padrão arquitetural MVVM + Provider definido em AGENTS.md.

---

## 1) Visão Geral da Estrutura de Código

Raiz relevante: `lib/features/games/register/`

- helpers/
  - `register_animations.dart`: constantes de animação (durations/curves) padronizadas.
  - `register_styles.dart`: helpers de estilo para superfícies, sombras, radius e paddings.
  - `validators.dart`: regras de validação de set e utilitários (min players, winner de set).
- models/
  - `game_models.dart`: modelos imutáveis de Game, Player (local), GamePlayer e ScoreSet com `fromMap` e `toInsert`.
- services/
  - `games_service.dart`: CRUD de `games` no Supabase (create draft, update status, delete).
  - `players_service.dart`: listagem/criação de `players` do usuário atual.
  - `game_players_service.dart`: upsert/list/delete de `game_players` (relação jogo ↔ jogador e time).
  - `scores_service.dart`: upsert/list/delete de `score_sets`.
- view/
  - `register_game_screen.dart`: tela principal que orquestra a experiência de registro.
- viewmodels/
  - `register_game_view_model.dart`: estado e ações do fluxo de registro (ChangeNotifier, usa os services).
- widgets/
  - `actions_bar.dart`: barra com ações Salvar/Excluir rascunho.
  - `add_player_sheet.dart`: bottom sheet para buscar/criar e selecionar jogador.
  - `game_summary_card.dart`: resumo final do placar e botão “Salvar Jogo”.
  - `player_card.dart`: cartão de jogador com seleção de time (ChoiceChip).
  - `players_section.dart`: seção que lista jogadores adicionados e ação para adicionar.
  - `score_button.dart`: botão grande que cicla pontuação 0→7 com animação.
  - `score_card.dart`: cartão compacto de placar para grid de opções pré-definidas.
  - `score_grid.dart`: grid com resultados comuns (não utilizado na tela principal atual).
  - `set_card.dart`: UI para seleção/confirmar um set (dois `ScoreButton` + “Salvar Set”).
  - `sets_summary.dart`: chips resumo dos sets salvos localmente.

Módulos relacionados:
- `lib/features/players/`
  - data: `player_model.dart`, `player_repository.dart`
  - service: `player_service.dart`
  - presentation/viewmodel: telas de lista/formulário e `PlayerViewModel`
- `lib/core/`
  - router: `app_router.dart` (rota `/games/register` → `RegisterGameScreen`)
  - config: `app_config.dart` (carregamento de Supabase URL/anon key)

Arquitetura e estado:
- MVVM com Provider: `RegisterGameViewModel` é injetado via `ChangeNotifierProvider` na `RegisterGameScreen`. UI consome o estado via `Consumer`.
- Persistência e dados remotos: todos os services usam `SupabaseClient` via `supabase_flutter`.

---

## 2) Modelos de Dados Atuais

Definidos em `lib/features/games/register/models/game_models.dart`:

- GameModel
  - Campos: `id`, `createdBy`, `status` ('draft' | 'completed' | 'cancelled'), `bestOf` (1|3|5), `startedAt?`, `endedAt?`, `notes?`.
  - Métodos: `fromMap`, `toInsert()` (sem `createdBy` e `id`; `created_by` é setado no service).

- PlayerModel (duplicado neste módulo; há outro em `features/players/data/player_model.dart`)
  - Campos: `id`, `name`, `createdBy`.
  - Métodos: `fromMap`, `toInsert({name})` — aqui não inclui `created_by` (o service inclui).

- GamePlayerModel (representa tabela `game_players`)
  - Campos: `id`, `gameId`, `playerId`, `team?` (1|2).
  - Métodos: `fromMap`, `toInsert({gameId, playerId, team?})`.

- ScoreSetModel (representa tabela `score_sets`)
  - Campos: `id`, `gameId`, `setIndex`, `team1Games`, `team2Games`, `winnerTeam?`.
  - Métodos: `fromMap`, `toInsert({gameId, setIndex, team1, team2, winnerTeam?})`.

Observações:
- Há duplicidade de `PlayerModel` entre `games/register/models` e `players/data`. Nomes idênticos e responsabilidades parecidas, porém APIs ligeiramente diferentes. Risco de divergência e confusão.

---

## 3) Fluxo Lógico — de “Registrar Jogo” a “Salvar Jogo”

Passo a passo (principalmente em `register_game_screen.dart` + `register_game_view_model.dart`):

1. Acesso à tela
   - Navegação via rota `/games/register` definida no `app_router.dart`.
   - A tela cria `RegisterGameViewModel(Supabase.instance.client)` e chama `startDraft()` ao construir.

2. Criação do rascunho de jogo (draft)
   - `startDraft()`:
     - Chama `games.createDraft(bestOf: bestOf)`; por padrão `bestOf = 3`.
     - O service insere na tabela `games` com `status = 'draft'`, `best_of`, `created_by = currentUser.id`.
     - Guarda `gameId` localmente e limpa estado local (`_assignedPlayers`, `_sets`).

3. Seleção/gestão de jogadores
   - UI apresenta `PlayersSection` com lista local `vm.assignedPlayers` (List<Map>).
   - “Adicionar jogador” abre `AddPlayerSheet`:
     - Busca: `vm.searchPlayers(query)` via `PlayersService.listMine()` (filtra por `created_by` e `ilike(name)`; ordena por `created_at`).
     - Criar: `vm.createPlayer(name)` via `PlayersService.create()` insere em `players`.
     - Selecionar: `vm.addPlayerToGame(p)`: chama `gamePlayers.upsert(gameId, playerId, team?)` e adiciona ao estado local `{id, name, team?}`.
   - Remover: `vm.removePlayerFromGame(playerId)` apaga da tabela `game_players` e remove do estado local.
   - Definir time: `vm.setTeam(playerId, team)` atualiza APENAS estado local (`_assignedPlayers[idx]['team'] = team`) — não persiste no backend neste momento (ver “Problemas”).

4. Input de placar e salvamento de sets
   - `SetCard` controla pontuações locais de um set (`team1`, `team2`) ciclando 0→7.
   - `Salvar Set` chama `vm.selectScore(setIndex, t1, t2)` guardando em `_sets[setIndex] = {team1, team2}`.
   - Há validação de set: `Validators.isValidSetScore(t1, t2)` (mínimo 6 games, diferença de 2, ou tiebreak 7–6 etc.).
   - UI desabilita a interação com `SetCard` enquanto `vm.assignedPlayers.length < 4` com `IgnorePointer/Opacity`. Também exibe `MaterialBanner` para orientar.
   - `SetsSummary` lista chips dos sets salvos; `GameSummaryCard` aparece quando `vm.sets.length >= vm.bestOf` com cálculo do vencedor por maioria de sets (via `Validators.winnerFromSet`).

5. Validações antes de salvar
   - `vm.canSaveGame` retorna `Validators.hasMinPlayers(_assignedPlayers.length) && _sets.isNotEmpty`.
   - Importante: `hasMinPlayers(count) => count >= 2`. Isso entra em conflito com a UI que exige `>= 4` jogadores para habilitar o input de set.

6. Persistência de dados de placar
   - `vm.persistScores()` itera `vm.sets` e executa `scores.upsert(gameId, setIndex, team1, team2, winnerTeam?)`.
   - `winnerTeam` é computado por `Validators.winnerFromSet(t1, t2)`, retornando `1`, `2` ou `null` (se inválido).

7. Salvar jogo
   - `vm.saveGame()`:
     - Marca `saving = true` e notifica.
     - Chama `persistScores()`.
     - Atualiza `games.updateStatus(gameId, 'completed')`.
     - Marca `saving = false` e notifica.
     - A UI chama `Navigator.pop()` após salvar.

8. Excluir rascunho
   - `vm.deleteGame()`:
     - Marca `deleting = true` e notifica.
     - Chama `games.deleteGame(gameId)`.
     - Reseta estado local e `gameId`, `deleting = false`, `notifyListeners()`.

Persistência (Supabase):
- Todos os services usam `PostgrestQueryBuilder` com `from(<tabela>)`.
- `upsert` é usado para `game_players` e `score_sets`, assumindo chaves únicas (ex.: `(game_id, player_id)` e `(game_id, set_index)`).

---

## 4) Problemas Conhecidos ou Potenciais

1. Persistência da seleção de times
   - `setTeam(playerId, team)` só atualiza o estado local. Não há chamada para `gamePlayers.upsert` após alterar o time. Resultado: banco pode ficar com `team = null` (ou valor antigo) enquanto a UI mostra um time novo.

2. Validação inconsistente de número de jogadores
   - UI exige 4 jogadores para input de placar (padrão de padel). Porém `canSaveGame` permite salvar com apenas 2 jogadores se houver ao menos 1 set. Isso pode permitir jogos “incompletos” por caminhos alternativos (ActionsBar sempre visível).

3. Falta de validação de composição de equipes
   - Não há checagem se existem exatamente 2 times e cada um com 2 jogadores antes de salvar (composição típica de padel). Também não se valida que todos os jogadores têm time definido.

4. Tipagem fraca no estado local
   - `assignedPlayers` e `sets` usam `Map<String, dynamic>` em vez de modelos tipados. Isso reduz segurança de tipos, legibilidade e aumenta risco de erros (ex.: keys incorretas).

5. Duplicação de modelos/serviços de Player
   - `PlayerModel` existe em dois locais (`games/register/models` e `features/players/data`). Há também `PlayersService` em `games/register/services` e `PlayerService` em `features/players/service`. Essa duplicidade favorece divergências, viola DRY e dificulta manutenção.

6. Fluxo de persistência não transacional
   - `saveGame()` realiza múltiplos `upsert` em `score_sets` e depois altera status do jogo. Em caso de falha parcial, não há rollback. O jogo pode permanecer em `draft` com sets parcialmente gravados, ou status `completed` sem todos os sets, dependendo de onde falhar.

7. Remoção/edição de sets
   - `ScoresService.removeSet()` existe, mas não há UI para remover ou editar sets salvos no backend. A remoção atual só atua no estado local (`vm.removeSet`) e não persiste.

8. Duplicidade de adicionamento de jogador
   - `addPlayerToGame` não previne adicionar o mesmo `playerId` mais de uma vez no estado local. Embora o `upsert` no backend evite duplicatas, a UI pode exibir entradas repetidas.

9. Configuração de Best-of
   - `bestOf` é fixo em 3 no ViewModel. Não há UI para ajustar entre 1/3/5 (conforme comentário). Isso limita cenários de torneio.

10. Ausência de timestamps de início/fim
   - `GameModel` prevê `startedAt/endedAt`, mas o fluxo não seta esses valores.

11. Acesso e consistência de dados
   - Após adicionar/remover jogadores, o estado deriva do local sem revalidação via consulta ao backend (ex.: `listByGame`). Isso pode mascarar diferenças caso haja falha no upsert/delete.

---

## 5) Oportunidades de Melhoria

1. Persistir seleção de time imediatamente
   - Em `setTeam(playerId, team)`, chamar `gamePlayers.upsert(gameId, playerId, team: team)` para manter consistência banco/UI.

2. Validação de equipes e número de jogadores
   - Substituir `Validators.hasMinPlayers` por regras alinhadas ao padel:
     - `hasValidTeamComposition(players)`: exatamente 4 jogadores, dois por time, todos com `team` definido, time ∈ {1,2}.
     - Impedir `saveGame()` quando a composição não for válida.
   - Ajustar `canSaveGame` e gating da UI de placar para usar a mesma regra.

3. Tipagem forte no estado
   - Trocar `List<Map<String, dynamic>>` por `List<GamePlayerModel>` ou um view model tipado (ex.: `AssignedPlayer { id, name, team }`).
   - Trocar `Map<int, Map<String, int>>` por `List<ScoreSetModel>` ou `Map<int, ScoreSet>` com classe definida.

4. Unificação de modelos/serviços de Player
   - Consolidar `PlayerModel` e serviços em `features/players/`, removendo duplicatas em `games/register`. Usar repositório (`player_repository.dart`) para validação de criação (duplicidade) e expor APIs consistentes ao módulo de jogos.

5. Fluxo transacional de salvamento
   - Implementar salvamento atômico via:
     - Edge Function ou RPC (Postgres) que recebe `game_id`, `score_sets[]` e realiza `upsert` + `update status` como uma transação.
     - Em caso de erro, garantir rollback e retornar mensagem clara.

6. Edição/remoção de sets persistidos
   - Introduzir UI para editar/remover um set já salvo; acoplar a `ScoresService.removeSet()` e `upsert()` conforme necessário.

7. Proteções contra duplicação de jogadores
   - Antes de inserir no estado local, verificar se `playerId` já está presente. Evitar duplicidade visual.

8. Configuração de Best-of na UI
   - Adicionar controle (ex.: `SegmentedButton` ou `Dropdown`) para escolher 1/3/5 sets antes de iniciar o draft. Persistir `best_of` corretamente.

9. Timestamps e metadados
   - Setar `started_at` ao criar rascunho e `ended_at` ao salvar jogo. Opcionalmente, permitir `notes`.

10. Carregamento e sincronização com backend
   - Após operações `upsert`/`delete`, recarregar a lista oficial via `gamePlayers.listByGame(gameId)` para garantir consistência.

11. UI/UX de placar
   - Decidir entre `ScoreButton` (incremental) e `ScoreGrid` (opções comuns). Atualmente, `ScoreGrid` não é usado. Padronizar uma abordagem consistente com validações.

12. Tratamento de erros e feedback
   - Adicionar `try/catch`, snackbars/baners para falhas de rede ou validação, e estados de loading por operação.

13. Aderência às diretrizes Material 3 e regras do projeto
   - A base já utiliza `colorScheme.surfaceContainerHighest` e `withValues(alpha: ...)`. Manter essa linha e revisar legibilidade/contraste em dark/light.

---

## Conclusão

O fluxo atual cobre o essencial: criar rascunho, associar jogadores, registrar sets e salvar o jogo. Contudo, há lacunas de validação (composição de equipes), inconsistências de persistência (times não atualizados após alteração), duplicidade de modelos/serviços e ausência de transação no salvamento. Corrigir esses pontos trará maior confiabilidade, legibilidade e manutenção mais simples, além de alinhar a experiência ao padrão competitivo de padel.

Este relatório deve servir de base para o planejamento das próximas melhorias, mantendo a arquitetura MVVM + Provider e integrando corretamente os services/repositories existentes.