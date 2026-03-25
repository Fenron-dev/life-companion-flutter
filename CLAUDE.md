# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Life Companion is a personal AI-powered life tracker built as a Flutter mobile app. Ported from a React SPA. All user data is stored locally on-device using SQLite (via Drift). Dual AI backend: Ollama server (when reachable) with automatic fallback to on-device Qwen 3.5 0.8B via llamadart.

## Commands

- `flutter run` — Run the app
- `flutter analyze` — Static analysis
- `flutter test` — Run tests
- `flutter build apk` — Build Android APK
- `flutter build ios` — Build iOS
- `dart run build_runner build --delete-conflicting-outputs` — Regenerate Drift database code (required after changing table definitions in `lib/services/database.dart`)

## Architecture

**Stack:** Flutter 3.41+, Dart 3.11+, Riverpod (state management), Drift (SQLite), http (Ollama API), llamadart (local LLM).

**AI Backend (dual, with auto-fallback):**
- `lib/services/ai_service.dart` — Unified AI service. Auto-detects Ollama availability (3s timeout) and falls back to local model. Priority: Ollama → Local → None.
- `lib/services/ollama_service.dart` — Connects to user's Ollama server via REST API. Supports streaming and non-streaming. URL and model configurable in Settings.
- `lib/services/local_llm_service.dart` — On-device inference via llamadart (llama.cpp). Uses Qwen 3.5 0.8B Q4_K_M GGUF (~533MB). Model downloaded on demand from HuggingFace (unsloth). GPU acceleration: Vulkan (Android), Metal (iOS).
- llamadart backend config in `pubspec.yaml` under `hooks.user_defines.llamadart`.

**Database (`lib/services/database.dart`):**
- Drift wrapping SQLite. Database: `life_companion.db`.
- Three tables: `DailyNotes`, `RawLogs` (JSON data as text column), `AppMetadata` (key-value).
- Generated code in `database.g.dart` — regenerate with `build_runner` after schema changes.
- Drift generates data classes `DailyNote`, `RawLog`, `AppMetadataData` — do NOT create separate model files with these names.

**State Management:**
- Riverpod providers in `lib/providers/providers.dart`.
- Database, Ollama config, LocalLLMService, and location consent are initialized in `main.dart` and provided via `ProviderScope.overrides`.
- Stream-based providers for reactive UI updates (`watchAllNotes`, `watchLogsForDate`, etc.).

**Navigation:** Tab-based via `IndexedStack` in `lib/screens/home_screen.dart`. Tabs: Dashboard, Journal, Companion (chat), Settings.

**Key patterns:**
- `lib/services/auto_logger.dart` — Runs on app start; logs location once per day with deduplication. Requires explicit user consent (toggle in Settings).
- `lib/utils/streak_calculator.dart` — Calculates consecutive journaling streak. Only counts truly consecutive days (no gap tolerance).
- `lib/utils/crypto.dart` — AES-256-GCM encryption with PBKDF2 key derivation (600k iterations, random salt). For future backup feature.
- `lib/models/chat_message.dart` — Chat message model with unique IDs (UUID).

## Design System

Editorial/minimalist aesthetic matching the original:
- Background: `#F5F5F0`, accent: `#5A5A40`, muted: `#9E9E9E`
- Cards: `BorderRadius.circular(32)` with `Color(0xFFE5E5E5)` border
- Typography: Google Fonts Lora (serif) for body, Inter (sans) for labels
- Labels: uppercase, letter-spacing 3, font-weight 700, size 10
- Mobile-first with fixed bottom nav bar

## Phased Development

Some features are mocked or stubbed:
- Weather data: currently only logged if location consent given
- Media tracking: planned (Audiobookshelf integration)
- WebDAV backup: stubbed in Settings (Phase 3)
- Activity chart: uses mock data
