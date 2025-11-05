# Register Game — Analysis and Implementation Plan

This document outlines the UX and technical plan to design and implement the new Register Game screen for the PadelScore app. The plan follows the workspace’s project rules (Flutter 3.35+, Material 3, MVVM with Provider, modular widgets, and Supabase integration), prioritizing clarity and minimal touch interactions.

---

## 1) Overview

- Purpose: Provide a simple, frictionless screen to create, edit, and delete a padel game, add/remove players, and record set scores using touch-only controls (no keyboard for scores).
- Scope:
  - Game lifecycle: create → edit → delete.
  - Player management: add by name, edit name, remove.
  - Score entry: interactive cards (0–7) with visual/tactile feedback; dynamic summary of sets won.
- Constraints & Principles:
  - Material 3, modern Flutter APIs (use `Color.withValues(alpha: ...)` instead of `withOpacity`).
  - Minimalist utility UI (fast, intuitive, responsive) with subtle animations.
  - MVVM + Provider, feature-based folder layout, one public widget per file.

---

## 2) Proposed UI/UX Flow

### Entry points
- New game: from Home or Quick Actions → “Register Game”.
- Edit game: open existing draft or completed game → “Edit”.

### Screen structure (top-to-bottom)
1. AppBar
   - Title: “Register Game” (or “Edit Game”).
   - Actions: Save (primary), Delete (secondary when editing), Close/Back.
2. Players section
   - Visual list/grid of players (cards/chips).
   - Add Player FAB or inline “+ Add Player” button → bottom sheet with a single TextField for name.
   - Edit name: long-press player card → inline rename or bottom sheet.
   - Remove: swipe-to-delete (Dismissible) or trash icon on the card.
3. Scores section (touch-only)
   - Sets container with one row per set (Set 1, Set 2, Set 3...).
   - For each side (Team A / Team B): a grid of score cards [0..7].
   - Tap card = select score; Tap again = deselect/reset.
   - Visual feedback: color change, elevation/scale, ink ripple.
   - Optional: auto-advance to next set after both sides are selected.
4. Summary
   - Chips showing per-set results (e.g., Set 1: 6–4, winner A).
   - Aggregate summary (Matches won per team, completion status).
5. Primary actions
   - Save (enabled only when data is valid). Disabled → show subtle guidance.
   - Delete (in Edit mode): confirmation bottom sheet.

### Interactions & feedback
- Touch animations: `InkWell`, `AnimatedContainer`, `ScaleTransition`, `AnimatedOpacity`.
- Haptics: `HapticFeedback.lightImpact()` on select; `HapticFeedback.selectionClick()` on toggle.
- Accessibility: large tap targets, readable contrast using `Theme.of(context).colorScheme`.
- Consistency: editing uses the same UI as creation with prefilled state.

### Responsiveness
- Mobile: vertical scroll; sticky AppBar; bottom action bar.
- Tablet/Web: two-column layout—left (Players), right (Scores & Summary).
- Adaptive spacing and typography via Material 3; large tap areas across platforms.

---

## 3) Suggested Data Structure (Supabase schema + relationships)

Padel games generally consist of best-of-3 sets (configurable). Players can be 2 or 4 (teams of 1–2). We’ll keep the model flexible and minimal.

### Tables

1. games
   - id: uuid (pk)
   - created_by: uuid (user id) — for RLS ownership
   - status: text check in ('draft', 'completed', 'cancelled') default 'draft'
   - best_of: smallint default 3 CHECK best_of IN (1,3,5)
   - started_at: timestamptz null
   - ended_at: timestamptz null
   - notes: text null
   - created_at: timestamptz default now()

2. players
   - id: uuid (pk)
   - name: text NOT NULL
   - created_by: uuid — for RLS ownership
   - created_at: timestamptz default now()

3. game_players (join table)
   - id: uuid (pk)
   - game_id: uuid REFERENCES games(id) ON DELETE CASCADE
   - player_id: uuid REFERENCES players(id) ON DELETE RESTRICT
   - team: smallint null CHECK team IN (1,2)  // optional; supports singles/doubles by assigning players to teams
   - created_at: timestamptz default now()
   - UNIQUE (game_id, player_id)

4. score_sets
   - id: uuid (pk)
   - game_id: uuid REFERENCES games(id) ON DELETE CASCADE
   - set_index: smallint NOT NULL  // 1..N, unique within a game
   - team1_games: smallint NOT NULL CHECK team1_games BETWEEN 0 AND 7
   - team2_games: smallint NOT NULL CHECK team2_games BETWEEN 0 AND 7
   - winner_team: smallint null CHECK winner_team IN (1,2)
   - created_at: timestamptz default now()
   - UNIQUE (game_id, set_index)

### Indexes & constraints
- FK indexes: game_players(game_id), game_players(player_id), score_sets(game_id).
- Uniqueness: prevent duplicate players in a game and duplicate set indexes.
- Data validity: CHECK constraints on enums and score ranges (0–7).

### RLS (Row Level Security) — initial approach
- Enable RLS on all tables.
- Policy: allow CRUD where `created_by = auth.uid()`.
- Note: refine policies later for club/team contexts.

---

## 4) Integration Layer

### Sync model
- UI maintains local state (draft) via ViewModel.
- On Save:
  1) Upsert game (insert or update)
  2) Upsert players: create new ones by name if missing; link via game_players; assign teams if used
  3) Upsert score_sets: per set index
- On Delete:
  - Delete game → cascades to game_players and score_sets.
- Editing:
  - Load existing data; reflect in UI; edits sync back using upsert.

### Optimistic UI & caching
- Optimistic updates: reflect interactions immediately; execute Supabase writes in background.
- Error handling: show non-intrusive snackbar; revert local state if necessary.
- Optional caching: local in-memory ViewModel state; consider hydrating from Supabase on screen open.

### Supabase service methods (pseudo)
- GamesService
  - createGame(draft)
  - updateGame(id, patch)
  - deleteGame(id)
  - getGame(id)
- PlayersService
  - createPlayer(name)
  - updatePlayer(id, name)
  - deletePlayer(id)
  - searchPlayersByName(prefix)
- GamePlayersService
  - linkPlayerToGame(gameId, playerId, team?)
  - unlinkPlayerFromGame(gameId, playerId)
- ScoresService
  - upsertSet(gameId, setIndex, team1, team2)
  - deleteSet(gameId, setIndex)
  - getSets(gameId)

Note: We’ll use Supabase Dart client with typed models (generate via MCP Supabase types generator).

---

## 5) Recommended Widget Tree & Folder Organization

Feature root: `lib/features/games/register/`

- view/
  - register_game_screen.dart  // Public screen widget
- viewmodels/
  - register_game_view_model.dart  // Provider-backed state and commands
- widgets/
  - players_section.dart        // Container for list, add button
  - player_card.dart            // Individual player UI + gestures
  - add_player_sheet.dart       // Name input via bottom sheet
  - scores_section.dart         // Sets list + per-set grids
  - score_card.dart             // Touchable card for a single score (0–7)
  - score_grid.dart             // Grid of score_card for one team in one set
  - sets_summary.dart           // Visual chips for results
  - actions_bar.dart            // Save, Delete, Close
- services/
  - games_service.dart          // Supabase queries for games
  - players_service.dart        // Supabase queries for players
  - game_players_service.dart   // Supabase queries for linking
  - scores_service.dart         // Supabase queries for set scores
- helpers/
  - register_styles.dart        // Color, elevation, spacing
  - register_animations.dart    // Shared animations for touch feedback
  - validators.dart             // Basic validation (players count, scores completeness)

Guidelines:
- One public widget per file; relative imports only.
- Separate state (ViewModel) from UI widgets; commands called via Provider.
- Keep helpers stateless and reusable across features when possible.

---

## 6) Animations, Color Feedback, and Usability Notes

- Color scheme:
  - Use `Theme.of(context).colorScheme`.
  - Replace any `surfaceVariant` usage with `surfaceContainer*` levels (e.g., `surfaceContainerHighest`) per Material 3 guidance.
  - No `Color.withOpacity(...)`; prefer `withValues(alpha: ...)`.
- Touch feedback:
  - ScoreCard: `InkWell` + subtle `ScaleTransition` on tap; `AnimatedContainer` for elevation/color.
  - Selection states: elevated container with tonal shift and icon check overlay.
- Motion:
  - Entry: fade + shared axis transition between Create and Edit.
  - Summary chips animate in/out on set changes.
- Ergonomics:
  - Large tap targets (min 44×44), generous spacing.
  - Clear labels: team names or A/B placeholders derived from player assignment.
- Accessibility:
  - Contrast checked against light/dark themes.
  - Semantic labels for buttons/cards.

---

## 7) Validation Rules

- Players:
  - Minimum 2 players required; max 4 (for doubles).
  - Unique player names within a game (soft validation in UI).
- Scores:
  - Each set requires both teams to have a score.
  - Winner computed where `team1 != team2`; tie not allowed.
  - Number of sets must not exceed `best_of`.
- Game lifecycle:
  - Save disabled until validation passes.
  - Delete requires confirmation.

---

## 8) Implementation Notes & Sequence

1. Data layer (Supabase, PG MCP)
   - Create migrations for tables: `games`, `players`, `game_players`, `score_sets`.
   - Enable RLS and add basic owner policies.
   - Generate TypeScript/Dart types via MCP Supabase tooling.
2. ViewModel
   - State: game draft, players list, set scores.
   - Commands: add/remove/edit player, select/deselect scores, save, delete.
   - Validation: enable/disable actions.
3. UI
   - Build modular widgets (players_section, scores_section, summary, actions_bar).
   - Wire gestures and animations.
4. Integration
   - Implement services with Supabase queries.
   - Connect ViewModel commands to services.
5. QA
   - Test flows: create, edit, delete; edge cases (0–7); responsiveness.
   - Verify haptics availability on platform; fail gracefully when unavailable.

---

## 9) Risks & Mitigations

- Team assignment ambiguity (singles vs doubles): keep `team` optional; UI can default to A/B and allow manual assignment.
- Score rules variability (tie-breaks, walkovers): start with basic 0–7; design extensible models to add special cases later.
- RLS correctness: start with owner-based policies; iterate as multi-user/team features emerge.

---

## 10) Next Steps

- Approve schema and UI flows.
- Implement PG migrations and RLS with MCP.
- Scaffold feature folders and Provider wiring.
- Build UI components and ViewModel logic.
- Connect Supabase services; run end-to-end.
- Add analytics for interaction funnels and error logging.

---

## Appendix: Example DDL (sketch)

```sql
-- games
CREATE TABLE IF NOT EXISTS public.games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by uuid NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','completed','cancelled')),
  best_of smallint NOT NULL DEFAULT 3 CHECK (best_of IN (1,3,5)),
  started_at timestamptz NULL,
  ended_at timestamptz NULL,
  notes text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- players
CREATE TABLE IF NOT EXISTS public.players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- game_players
CREATE TABLE IF NOT EXISTS public.game_players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  player_id uuid NOT NULL REFERENCES public.players(id) ON DELETE RESTRICT,
  team smallint NULL CHECK (team IN (1,2)),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (game_id, player_id)
);
CREATE INDEX IF NOT EXISTS idx_game_players_game ON public.game_players(game_id);
CREATE INDEX IF NOT EXISTS idx_game_players_player ON public.game_players(player_id);

-- score_sets
CREATE TABLE IF NOT EXISTS public.score_sets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  set_index smallint NOT NULL,
  team1_games smallint NOT NULL CHECK (team1_games BETWEEN 0 AND 7),
  team2_games smallint NOT NULL CHECK (team2_games BETWEEN 0 AND 7),
  winner_team smallint NULL CHECK (winner_team IN (1,2)),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (game_id, set_index)
);
CREATE INDEX IF NOT EXISTS idx_score_sets_game ON public.score_sets(game_id);
```

Notes:
- RLS: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` then policies using `auth.uid() = created_by`.
- Future: add clubs/teams tables and policies to support shared ownership.