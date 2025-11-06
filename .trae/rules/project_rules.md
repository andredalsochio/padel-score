# Project Rules — Padel App

> This document complements `AGENTS.md` and `~/.trae/rules/user_rules.md`.  
> It defines project-specific standards, UI philosophy, and MCP usage for the Padel App workspace.

---

## Project Context
This project is a Flutter application targeting Android, iOS, and Web.
It integrates with Supabase for authentication and cloud storage, and uses `pg-mcp-server` for database management (PostgreSQL). 
Context7 MCP handles intelligent context synchronization and configuration management.

> **Environment:**  
> Use the latest stable Flutter SDK (3.35.x or newer) with Dart 3.6+ on macOS Apple Silicon (M2).  
> Manage versions via FVM for consistency across the workspace.

---

## Primary Objective
Assist in building and maintaining a modular, scalable app for managing padel tournaments, player rankings, and game scheduling.

---

## Coding Standards
- Follow the **AI Rules for Flutter** as the primary technical guideline.
- Use **MVVM** architecture with **Provider** for state management.
- Apply **SOLID** principles and feature-based folder organization.
- Ensure code clarity and maintainability — avoid unnecessary abstractions.
- Use clear, descriptive naming conventions (`camelCase`, `PascalCase`, `snake_case` for files).

---

## MCP & Toolchain Integration
- **MCPs available in this workspace:**
  - `pg`: PostgreSQL schema management.
  - `supabase`: backend API and authentication.
  - `context7`: context enrichment and AI memory.
- These three MCPs form a unified backend ecosystem for the app and must remain enabled.
- Prefer `pg` for schema changes and `supabase` for data-layer validation.
- The IDE and Codex must leverage the configured MCP servers automatically when generating or validating code.

---

## Rules of Interaction
- When asked to create code, generate **complete Flutter widgets**.
- When describing a process, output the steps as **clear bullet points**.
- If the request involves database schema or API design, use the **`pg`** and **`supabase`** MCP servers for live validation.

---

## Output Preferences
- Use **Markdown** for all responses.
- Include **explanations for non-trivial decisions** (e.g., database indexes, async calls).
- Keep responses structured, concise, and actionable.

---

## UI Design Philosophy

The app should balance simplicity and visual appeal across different screens, adapting automatically to the purpose of each interface.

- The **AI assistant must infer** when a screen requires simplicity or visual richness based on its role:
- **Utility screens** (e.g., login, player registration, match input) → prioritize **clarity, speed, and intuitiveness**.
- **Highlight experiences** (e.g., ranking, statistics, results summary) → prioritize **visual impact, motion, and delight**.
- Flutter’s animation and compositional capabilities should be used creatively, but always purposefully — motion should enhance usability, not distract.
- Every UI element must communicate intent: the more important or emotional the user action, the more expressive the design can be.

**Responsiveness & Cross-Platform Design:**
- The app must be **fully responsive**, adapting gracefully to different screen sizes, orientations, and interaction modes.
- Layouts, typography, and gestures should scale intuitively between **mobile**, **tablet**, and **web** environments.
- The AI assistant is free to choose the most effective responsive or adaptive approach available in the current Flutter version.
- Readability, spacing, and ergonomics must always take precedence over visual complexity.
- When generating UI, the AI must always consider **readability, spacing, and input ergonomics** across platforms.


**Design Principle:**  
Each screen should express its own *energy level* — calm and functional when the user acts, vibrant and inspiring when the user observes results.

---

### Authentication UX

- The login experience must be **minimalist and friendly**.
- Display only essential actions: “Continue with Google”, “Continue with Apple”, and “Continue with Facebook”.
- Use subtle motion: fade-in logo, hover feedback, and smooth transition to the home screen.
- Keep the flow **single-tap and frictionless** — one tap = one login.

---

### Design Guidelines Summary
Simplicity for everyday actions, brilliance for highlight moments.  
Animations should serve usability first and delight second — leveraging the full power of Flutter’s motion system.

---

## Architecture & Code Generation Enforcement

To ensure maintainability and consistency across the app, the following rules are enforced for all future implementations and refactors:

### Modular Widget Architecture
- Split large screens (e.g., `HomeView`/`HomeScreen`) into smaller, reusable sub-widgets.
- Place sub-widgets under `lib/features/<feature>/widgets/` or `components/`.
- Move logic, constants, and style helpers into `lib/features/<feature>/helpers/` or `utils/`.
- Keep one public widget per file; prefer small private widgets only when clearly local.
- Use relative imports (e.g., `import '../widgets/quick_actions.dart';`).
- Naming conventions: files `snake_case.dart`, classes `PascalCase`, members/functions `camelCase`.

### Modern Flutter API Usage (3.35+)
- Stop using `Color.withOpacity(...)`. Prefer `Color.withValues(alpha: <0.0–1.0>)` for alpha changes.
- Favor Material 3 motion APIs (`AnimatedOpacity`, `FadeTransition`, shared axis transitions) over manual color math.
- Use `Theme.of(context).colorScheme` for colors; avoid hardcoded ARGB unless necessary.

### Material 3: Deprecations

- `colorScheme.surfaceVariant` is deprecated since `v3.18.0-0.1.pre`. Replace with `colorScheme.surfaceContainerHighest` (or another appropriate `surfaceContainer*` level based on screen hierarchy and context).
- Rationale: the `surfaceContainerLowest` → `surfaceContainerHighest` levels provide clearer semantics for surfaces and elevation in Material 3, superseding `surfaceVariant`.
- Migration: when replacing `surfaceVariant`, validate contrast and accessibility in light/dark themes and align with `elevation`, `shadow`, and `outline` to preserve readability.

### Clean Code Generation
- One widget per file; avoid dumping multiple public widgets together.
- Use relative imports throughout the project; avoid absolute `package:` imports to self.
- Keep changes surgical; do not modify unrelated code during refactors.
- Maintain feature-based MVVM organization with Provider for state.

---

## Module Organization (PadelScore)

- `features/auth` — Supabase auth (Google/Apple/Facebook), session and login.
- `features/players` — player data/models and presentation widgets.
- `features/patotas` — groups/clubs management (services, viewmodels, views).
- `features/games` — game registration, set composition and scoring summary.
- `features/home` — overview, quick actions and entry experience.
- `core/router/app_router.dart` — `go_router` setup with auth redirects.
- `core/config/app_config.dart` — centralized environment/config management.

## Environment & Profiles

- Use FVM with Flutter 3.35.x and Dart 3.6+.
- Trae profiles in `.trae/config.json`:
  - `dev`, `dev_ios`, `beta`, `prod` with `dart_defines.*` files.
- When adding new environment variables, prefer `dart_defines.<env>.json`.

## MCP Usage Order

1. `pg` — Prefer for schema changes, migrations and DB validations.
2. `supabase` — Validate APIs, RPCs and storage integration.
3. `context7` — Context enrichment and AI memory alignment.

## Routing & Auth

- Use `go_router` with redirects for authentication (`/login` ↔ intended route).
- Keep login UX minimalist (single-tap sign-ins) with subtle motion.

## Deployment Notes

- Web dev: `flutter run -d chrome` using the dev profile and defines.
- iOS dev: use `dev_ios` profile; prefer simulator.
- Document RPCs and migrations in README, include rollback steps.