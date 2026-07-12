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
- [x] CI (analyze + test + Android/desktop builds) and release workflow

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

## Backlog

- [ ] Whisper.cpp STT backend (fully offline transcription behind `SpeechRecognizer`)
- [ ] Function calling / tools (calculator, date/time, on-device utilities)
- [ ] Per-conversation model pinning & generation presets
- [ ] Encrypted-at-rest storage for chats & documents
- [ ] First-run onboarding (explain "100% offline", suggest a starter model)
- [ ] Golden tests + automated screenshot capture in CI

## Working notes

- Project root: `Ayushd70/manthan`. Architecture is feature-first
  (`domain` / `data` / `application` / `presentation`); the `LlmEngine` and
  `EmbeddingEngine` interfaces are the extension seams — add backends there.
- Toolchain is pinned to **Flutter 3.41.6** in CI; format with the matching
  `dart format` before pushing. If bumping Flutter, update the CI pins and
  re-run `dart format` once.
- Screenshots/GIF are generated via the `MANTHAN_DEMO` dart-define seed
  (`lib/core/demo/demo_seed.dart`); see `docs/media/README.md`.
