# Langfuse

Langfuse is an observability platform for apps built on language models. Every call your app makes to a model (the prompt, the answer, the tokens, the cost, how long it took) is recorded as a trace you can open, search and compare. Prompts can be kept and versioned in Langfuse instead of in your code, and answers can be scored, by people or by another model.

### What people use it for

- Debugging an agent or a chatbot: seeing exactly which steps it took and where it went wrong.
- Keeping an eye on cost and latency per feature, user or model.
- Changing a prompt without a deploy, and comparing how versions do on the same inputs.

### Good to know

- This is the whole self-hosted stack: the web app, its worker, ClickHouse for the traces, S3-style storage, Postgres and Redis. Your traces never leave your servers.
- It needs real memory: at least 4 GB free, and 8 GB or more once it's busy.
- Its SDKs for Python and JavaScript, and integrations for OpenAI, LangChain, LlamaIndex and others, send to the address it gets here.
