# AGENTS.md

This project is a simple iOS mobile app for an AI chat interface using OpenRouter as the LLM provider. It should utilize native OpenRouter functionality.

## Functionality:

- Model selector with dynamically fetched model list from OpenRouter, with ability to favorite models. The list should also be cached.
- Toggles for OpenRouter Web Search and Web Fetch server tools. Default enabled. Check the docs for details.
- A conversation list with the previous conversations, that can be opened/resumed.
- Ability to edit previous messages in a conversation, creating a new chat (fork) on submit.
- AI answers should be rendered as markdown.

OpenRouter documentation is available at https://openrouter.ai/docs/llms.txt

The OpenRouter OpenAPI specification is available at https://openrouter.ai/openapi.yaml and https://openrouter.ai/openapi.json
