# Contributing to Manthan

Thanks for your interest in improving Manthan! This document covers the basics.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The app runs immediately with a built-in demo engine — no model download is
required to develop UI and flows.

## Project layout

Manthan uses a feature-first clean architecture:

```
lib/
  app/                 App wiring: theming, routing, shell
  core/                Cross-cutting utilities, theme, DI providers
  data/local/          ObjectBox entities + store
  features/
    <feature>/
      domain/          Entities + interfaces (no Flutter / vendor imports)
      data/            Implementations (repositories, engine adapters)
      application/     Riverpod controllers (state + orchestration)
      presentation/    Widgets and pages
```

The inference layer is the heart of the app: every runtime implements the
`LlmEngine` interface in `features/inference/domain/llm_engine.dart`.

## Before opening a PR

Please make sure the following pass locally — CI runs all of them:

```bash
dart format lib test
flutter analyze
flutter test
```

- Lints follow `very_good_analysis`.
- Prefer adding tests for pure logic (engines, chunking, formatters, vectors).
- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit
  messages (e.g. `feat: add voice input`, `fix: resume interrupted download`).

## Adding a model

Add an entry to `ModelCatalog` in
`lib/features/models/domain/model_catalog.dart`. Map any new architecture in
`EngineFactory`.

## Adding an engine

Implement `LlmEngine`, register it in `EngineFactory`, and add an `EngineKind`.
That's the only surface the rest of the app depends on.
