# openchat

A native iOS chat app for [OpenRouter](https://openrouter.ai), built with SwiftUI and SwiftData.

## Features

- **Model picker** with the full OpenRouter catalog, fetched dynamically and cached locally. Favorite models for quick access.
- **OpenRouter server tools** — Web Search and Web Fetch toggles (enabled by default) using OpenRouter's native plugin support.
- **Conversation history** persisted with SwiftData. Resume any previous chat from the conversation list.
- **Edit & fork** — edit any earlier message to spawn a new conversation branch from that point.
- **Markdown rendering** for assistant responses.
- **Secure key storage** — your OpenRouter API key is stored in the iOS Keychain.

## Setup

1. Open `openchat.xcodeproj` in Xcode.
2. Build and run on a simulator or device (iOS 17+).
3. Open Settings inside the app and paste your [OpenRouter API key](https://openrouter.ai/keys).

## Project layout

```
openchat/
├── Models/      # SwiftData models (Conversation, ChatMessage) and DTOs
├── Services/    # OpenRouter client, settings, keychain, model cache
└── Views/       # SwiftUI views (chat, model picker, settings, …)
```

## Tech

- SwiftUI + SwiftData
- OpenRouter Chat Completions API with streaming
- Native iOS Keychain for credential storage
