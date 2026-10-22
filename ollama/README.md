# Ollama + Open WebUI

Ollama runs open language models (Llama, Qwen, Gemma, Mistral, DeepSeek and many more) on your own server, and answers over an API that also speaks OpenAI's format. Open WebUI is a chat page in front of it, much like ChatGPT: conversations, several users, documents to ask questions about, and a model picker.

### What people use it for

- A private assistant for a team, where nothing typed in leaves your servers.
- An API for your own apps: summaries, classification, extracting fields from text, embeddings for search.
- Trying open models side by side before building on one.

### Good to know

- smartalfred's servers have no GPUs, so models run on the CPU. Small models (up to about 8 billion parameters, like `llama3.2:3b` or `gemma3:4b`) answer at reading speed; larger ones are slow.
- A model needs memory to match its size: Ollama gets 8 GB here. Raise its size before pulling a bigger model.
- Ollama has no login of its own, so it stays private to the project; Open WebUI is the address people open. The first account made there is the admin.
