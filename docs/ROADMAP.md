# Manthan Roadmap

Living plan for what's next. Status reflects `main` at the time of writing.

## Shipped

- [x] Pluggable multi-engine inference (mock · Gemma/LiteRT-LM · llama.cpp/GGUF)
- [x] Streaming chat with markdown, code highlighting, tokens/sec + RAM HUD
- [x] Model manager: resumable downloads, SHA-256 verification, activate/delete
- [x] Multimodal image input (vision models)
- [x] On-device RAG: chunk → embed → ObjectBox HNSW search → grounded answers with citations (mock + EmbeddingGemma)
- [x] Voice input (speech-to-text)
- [x] Text-to-speech (read answers aloud)
- [x] Material 3 + dynamic color, light/dark, adjustable generation params
- [x] Local history (persist, rename, delete, share/export as Markdown)
- [x] Prompt library: save, edit, and apply reusable system prompts
- [x] Per-conversation model pinning & generation presets
- [x] First-run onboarding (explain "100% offline", suggest a starter model)
- [x] Function calling / tools (calculator, date/time, on-device utilities)
- [x] Encrypted-at-rest storage for chats & documents
- [x] Golden tests for core chat bubbles
- [x] CI (analyze + test + Android/desktop builds) and release workflow
- [x] Whisper.cpp STT (live dictation with Tiny/Base/Small/Medium ggml downloads)

## Next sprint (priority order)

### 1. Text-to-speech (read answers aloud) — shipped
- [x] `flutter_tts` behind `SpeechSynthesizer`; speaker toggle on bubbles
- [x] Auto-speak setting; stop on new message

### 2. Real EmbeddingGemma RAG (true semantic search) — shipped
- [x] `GemmaEmbeddingEngine` + `EmbeddingController` with mock fallback
- [x] Embedding model in catalog with tokenizer sidecars (iOS json + sentencepiece)
- [x] Download UI on Models page; semantic vs mock status on Documents
- [x] Auto re-index when EmbeddingGemma becomes available

### 3. PDF / DOCX document import — shipped
- [x] `DocumentTextExtractor` for `.pdf` (Syncfusion) and `.docx` (OOXML)
- [x] File picker accepts pdf/docx; user-facing errors for image-only PDFs
- [x] Extracted text flows into existing chunk → embed → index pipeline

### 4. Prompt library & saved system prompts — shipped
- [x] `SavedPrompt` + ObjectBox-backed `PromptRepository`
- [x] `PromptLibraryController` for add/update/delete
- [x] Prompt Library screen at `/settings/prompts`; apply reloads active model

### 5. Per-conversation model pinning & generation presets — shipped
- [x] `ChatSession.modelId` + `generationOverrides`, persisted as JSON
- [x] `EngineController.activate()` accepts a config override; races guarded
      with an activation token
- [x] `ConversationSettingsSheet` (AppBar action) to pin a model or enable a
      custom temperature/top-k/top-p/system-prompt preset per chat

### 6. First-run onboarding — shipped
- [x] `hasCompletedOnboarding` flag in `AppSettings` / SharedPreferences
- [x] `/onboarding` pager (privacy, how it works, starter model) gated by
      GoRouter redirect; skipped for `MANTHAN_DEMO` builds
- [x] CTAs: start with demo engine or jump to Models for Gemma 3 1B

### 7. Function calling / on-device tools — shipped
- [x] `OnDeviceTool` seam with calculator + date/time builtins
- [x] Prompt-protocol `<tool_call>` parser and ChatController tool loop
- [x] Settings toggle; mock engine exercises the loop for demos/tests

### 8. Encrypted-at-rest storage — shipped
- [x] AES-256-GCM `FieldCipher` with DEK in `FlutterSecureStorage`
- [x] Chat / document / prompt string fields encrypted; dual-read of legacy
      plaintext; one-shot migration via `storage.atRestVersion`
- [x] Hugging Face token moved out of SharedPreferences into secure storage
- [x] Embedding vectors left plaintext (required for ObjectBox HNSW search)

### 9. Golden tests — shipped
- [x] Deterministic golden harness (fixed size, seed theme, no GoogleFonts)
- [x] MessageBubble user + assistant goldens under `test/goldens/`

### 10. Whisper STT seam — shipped
- [x] `SttBackend` setting + `WhisperSpeechRecognizer` behind
      `speechRecognizerProvider`
- [x] Whisper Tiny / Base / Small / Medium in `ModelCatalog` with download UX on Models
- [x] Live `whisper_ggml` transcription (16 kHz PCM via `record`)

## Backlog

_No open items._

## Working notes

- Project root: `Ayushd70/manthan`. Architecture is feature-first
  (`domain` / `data` / `application` / `presentation`); the `LlmEngine` and
  `EmbeddingEngine` interfaces are the extension seams — add backends there.
- Toolchain is pinned to **Flutter 3.47.0** in CI; format with the matching
  `dart format` before pushing. If bumping Flutter, update the CI pins and
  re-run `dart format` once.
- Screenshots/GIF are generated via the `MANTHAN_DEMO` dart-define seed
  (`lib/core/demo/demo_seed.dart`); see `docs/media/README.md`.
