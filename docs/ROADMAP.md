# Manthan Roadmap

Living plan for what's next. Status reflects `main` at the time of writing.

## Shipped

- [x] Pluggable multi-engine inference (mock · Gemma/LiteRT-LM · llama.cpp/GGUF)
- [x] Streaming chat with markdown, code highlighting, tokens/sec + RAM HUD
- [x] Model manager: resumable downloads, SHA-256 verification, activate/delete
- [x] Multimodal image input (vision models)
- [x] On-device RAG: chunk → embed → ObjectBox HNSW search → grounded answers with citations
- [x] Voice input (speech-to-text)
- [x] Material 3 + dynamic color, light/dark, adjustable generation params
- [x] Local history (persist, rename, delete, share/export as Markdown)
- [x] CI (analyze + test + Android/desktop builds) and release workflow

## Next sprint (priority order)

### 1. Text-to-speech (read answers aloud)
- **Why:** Completes the voice loop (dictate in, hear out); great for the demo.
- **Approach:** `flutter_tts` behind a `SpeechSynthesizer` interface mirroring the
  existing `SpeechRecognizer` seam. Add a speaker toggle on assistant bubbles and
  an "auto-speak replies" setting. Pause/stop on new input.
- **Notes:** Keep it offline-first; document that the OS TTS voice may vary by
  platform. No network during playback.

### 2. Real EmbeddingGemma RAG (true semantic search)
- **Why:** Replace the deterministic mock embedder with genuine semantic
  retrieval — the headline RAG feature.
- **Approach:** Wire `GemmaEmbeddingEngine` end-to-end: add the embedding model to
  the catalog, download/activate it, and switch `RagController` to use it when
  available (fall back to mock when not). Ensure `kEmbeddingDimensions` matches.
- **Notes:** Re-index existing documents on embedder change; show progress.

### 3. PDF / DOCX document import
- **Why:** PDFs are the most-requested document type; today only txt/md/paste.
- **Approach:** Add a PDF text extractor (e.g. `syncfusion_flutter_pdf` or a
  pure-Dart extractor) behind the existing import flow; feed extracted text into
  `TextChunker`. Add `.pdf`/`.docx` to the file picker.
- **Notes:** Handle scanned/image-only PDFs gracefully (warn: no embedded text).

## Backlog

- [ ] Whisper.cpp STT backend (fully offline transcription behind `SpeechRecognizer`)
- [ ] Function calling / tools (calculator, date/time, on-device utilities)
- [ ] Per-conversation model pinning & generation presets
- [ ] Prompt library & saved system prompts
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
