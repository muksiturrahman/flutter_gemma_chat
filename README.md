# flutter_gemma_chat

![Flutter](https://img.shields.io/badge/Flutter-%5E3.10.4-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

> Private, on-device AI chat powered by Google's Gemma — no cloud, no API keys.

A Flutter application that runs Google's Gemma language models **entirely on your device**. Once the model is downloaded, every conversation stays local — no data leaves your phone or computer.

---

## Table of Contents

- [Features](#features)
- [Supported Models](#supported-models)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **On-device inference** — fully private, works offline after the one-time model download
- **Streaming responses** — tokens appear in real time as the model generates them
- **Multimodal input** — attach images to your messages (Gemma 4 E2B only)
- **Thinking mode** — see the model's extended reasoning before its final answer (Gemma 4)
- **Persistent chat history** — conversations are saved locally with Hive; pick up where you left off
- **Multiple chat threads** — create, rename, and delete independent conversations
- **Model management** — download and switch between models from inside the app
- **GPU / CPU backend** — choose the inference backend that works best for your hardware
- **Light & dark theme** — follows system preference or can be set manually
- **Cross-platform** — runs on iOS, Android, macOS, Windows, and Linux

---

## Supported Models

| Model | Approx. Size | Multimodal | Thinking | HuggingFace Token Required |
|-------|-------------|:----------:|:--------:|:--------------------------:|
| Gemma 4 E2B | ~2 GB | ✓ | ✓ | Yes |
| Gemma 3 1B | ~1 GB | ✗ | ✗ | Yes |

Both models are gated on HuggingFace. You will need to accept the model license on HuggingFace and provide your access token in the app's Settings screen before downloading.

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter SDK | ≥ 3.10.4 |
| Dart SDK | ≥ 3.0.0 |
| HuggingFace account | — |

- Accept the model license at [huggingface.co/google/gemma](https://huggingface.co/google) for each model you want to use.
- Generate a HuggingFace **read** access token at `Settings → Access Tokens`.

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/muksiturrahman/flutter_gemma_chat.git
cd flutter_gemma_chat
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate Hive adapters

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the app

```bash
flutter run
```

### 5. Download a model

On first launch the app opens the **Model Picker** screen. Enter your HuggingFace token in **Settings**, select a model, and tap **Download**. The model is stored locally and only needs to be downloaded once.

---

## Project Structure

```
lib/
├── main.dart                  # Entry point — Hive init, GemmaService setup
├── app.dart                   # Root MaterialApp, theme, GoRouter wiring
│
├── core/
│   ├── routing/app_router.dart     # GoRouter route definitions
│   ├── theme/app_theme.dart        # Material 3 light & dark themes
│   └── platform/platform_info.dart # Runtime platform detection
│
├── services/
│   └── gemma_service.dart     # Singleton wrapper around flutter_gemma;
│                              #   manages model lifecycle & LRU session cache
│
├── features/
│   ├── chat/
│   │   ├── presentation/      # ChatScreen, ChatDrawer
│   │   ├── providers/         # Riverpod notifiers for message streaming
│   │   └── widgets/           # MessageBubble, StreamingBubble, ChatInputBar
│   │
│   ├── model_management/
│   │   ├── presentation/      # ModelPickerScreen, ModelDownloadScreen
│   │   └── providers/         # Download progress & model load state
│   │
│   └── settings/
│       └── settings_screen.dart   # Backend, token count, theme settings
│
└── data/
    ├── models/                # ChatThread, ChatMessage, GemmaModelInfo
    ├── repositories/          # ChatRepository (Hive), ModelRepository (Hive)
    └── sources/               # Static model registry (URLs, capabilities)
```

---

## Tech Stack

| Package | Purpose |
|---------|---------|
| [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) | On-device Gemma inference engine |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | Reactive state management |
| [`hive_ce`](https://pub.dev/packages/hive_ce) + [`hive_ce_flutter`](https://pub.dev/packages/hive_ce_flutter) | Local key-value persistence |
| [`go_router`](https://pub.dev/packages/go_router) | Declarative navigation & routing |
| [`flutter_markdown`](https://pub.dev/packages/flutter_markdown) | Renders Markdown in assistant replies |
| [`image_picker`](https://pub.dev/packages/image_picker) | Image selection for multimodal input |
| [`path_provider`](https://pub.dev/packages/path_provider) | Filesystem paths for model storage |
| [`uuid`](https://pub.dev/packages/uuid) | Unique ID generation for threads/messages |
| [`intl`](https://pub.dev/packages/intl) | Date/time formatting |

---

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

Please follow the existing code style and keep PRs focused on a single change.

---

## License

This project is licensed under the [MIT License](LICENSE).

> **Note:** The Gemma models themselves are subject to Google's [Gemma Terms of Use](https://ai.google.dev/gemma/terms). This repository contains only the Flutter application code.
