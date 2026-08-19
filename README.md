# LLM Proxy with LiteLLM Gateway

This project sets up an LLM proxy using a LiteLLM gateway container, configured to route requests through GitHub Copilot's backend API. It exposes an OpenAI-compatible endpoint at `http://localhost:4000`.

## Supported Models

Only the latest release per vendor line is kept configured; older, superseded
models (e.g. `claude-sonnet-4.6`, `gpt-5.4`, `gemini-3-pro-preview`) are pruned
from `litellm_config.yaml` to keep the model list current. Re-add any of them
by copying a block from git history if you need to pin an older version.

### Anthropic
- **Claude Opus 5** (`claude-opus-5`)
- **Claude Sonnet 5** (`claude-sonnet-5`)
- **Claude Haiku 4.5** (`claude-haiku-4.5`)
- **Claude Fable 5** (`claude-fable-5`)

### OpenAI
- **GPT-5.6 Luna** (`gpt-5.6-luna`) — Responses API only
- **GPT-5.6 Sol** (`gpt-5.6-sol`) — Responses API only
- **GPT-5.6 Terra** (`gpt-5.6-terra`) — Responses API only

### Google
- **Gemini 3.7 Flash** (`gemini-3.7-flash`)

### xAI
- **Grok 4.6** (`grok-4.6`) — Responses API only

### Moonshot AI
- **Kimi K3** (`kimi-k3`)

### Microsoft
- **MAI Code 1.1 Flash** (`mai-code-1.1-flash`) — Responses API only

### Azure OpenAI (via Entra ID)
- Disabled by default — uncomment the `azure-gpt-5-mini` block in `litellm_config.yaml` to enable.

> **Note**: GitHub Copilot models use a Copilot for Business account. The `gpt-5.6` trio, `grok-4.6`, and `mai-code-1.1-flash` are only exposed by Copilot via the `/v1/responses` endpoint (not `/v1/chat/completions`); LiteLLM routes them correctly when `model_info.mode: responses` is set. Reasoning-capable models (`claude-opus-5`, `gemini-3.7-flash`, the `gpt-5.6` trio) spend part of their `max_tokens`/`max_output_tokens` budget on internal thinking before the visible answer — set that budget generously (a few hundred tokens minimum) or you'll get an empty response. Azure OpenAI models require separate Azure credentials (see below).

## Prerequisites

- Docker and Docker Compose
- A GitHub account with Copilot for Business
- (Optional) An Azure subscription with an Azure OpenAI resource for `azure-gpt-5-mini`

## Quick Start

### 1. Clone and configure

```bash
cp .env.example .env
# Edit .env to set a strong LITELLM_MASTER_KEY (default: sk-1234)
```

### 2. Start the proxy

```bash
docker compose up -d
```

### 3. Authenticate with GitHub Copilot

On first start, the container will automatically initiate a GitHub device code flow. Check the container logs:

```bash
docker compose logs -f litellm
```

You will see output like:

```
Please visit: https://github.com/login/device
Enter code: XXXX-XXXX
```

Open the URL in your browser, enter the code, and authorize the app. The container will detect the successful authorization and proceed. If the token expires, simply restart the container and repeat this step.

### 4. Verify

```bash
# Health check
curl http://localhost:4000/health/liveliness

# List models
curl http://localhost:4000/models -H "Authorization: Bearer sk-1234"

# Run the test suite
chmod +x test.sh && ./test.sh
```

## Usage

### Chat Completion

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-sonnet-5",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 300
  }'
```

### With Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(api_key="sk-1234", base_url="http://localhost:4000/v1")

response = client.chat.completions.create(
    model="claude-sonnet-5",
    messages=[{"role": "user", "content": "Hello!"}],
    max_tokens=300
)
print(response.choices[0].message.content)
```

See [USAGE.md](USAGE.md) for more examples (streaming, function calling, vision, Node.js).

### With [OpenCode](https://opencode.ai)

OpenCode treats this proxy as a custom OpenAI-compatible provider. Add the block below to your `opencode.json` (project-local at `./opencode.json` or global at `~/.config/opencode/opencode.json`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "llm-proxy": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LiteLLM Proxy (Copilot)",
      "options": {
        "baseURL": "http://localhost:4000/v1",
        "apiKey": "sk-1234"
      },
      "models": {
        "claude-opus-5":        { "name": "Claude Opus 5" },
        "claude-sonnet-5":      { "name": "Claude Sonnet 5" },
        "claude-haiku-4.5":     { "name": "Claude Haiku 4.5" },
        "claude-fable-5":       { "name": "Claude Fable 5" },
        "gpt-5.6-luna":         { "name": "GPT-5.6 Luna" },
        "gpt-5.6-sol":          { "name": "GPT-5.6 Sol" },
        "gpt-5.6-terra":        { "name": "GPT-5.6 Terra" },
        "gemini-3.7-flash":     { "name": "Gemini 3.7 Flash" },
        "grok-4.6":             { "name": "Grok 4.6" },
        "kimi-k3":              { "name": "Kimi K3" },
        "mai-code-1.1-flash":   { "name": "MAI Code 1.1 Flash" }
      }
    }
  }
}
```

Notes:

- Replace `apiKey` with the value of `LITELLM_MASTER_KEY` from your `.env` (default `sk-1234`).
- `baseURL` must include the `/v1` suffix; LiteLLM exposes OpenAI-compatible routes under that prefix.
- Restart OpenCode (or run `/connect` again) after editing, then pick a model with `/models`.
- `gpt-5.6-luna/sol/terra`, `grok-4.6`, and `mai-code-1.1-flash` are Responses-API-only on Copilot; the AI SDK must dispatch them via `/v1/responses`, which this proxy's `model_info.mode: responses` setting handles server-side.
- Reasoning models (`claude-opus-5`, `gemini-3.7-flash`, the `gpt-5.6` trio) burn part of their token budget on internal thinking before the visible answer — configure a generous `max_tokens`/`max_output_tokens` (a few hundred at minimum) or you'll get an empty reply.
- If you hit `Invalid 'tools': array too long. Expected maximum length 128` from MCP-heavy setups, use one of the Responses-API models above — the `/responses` endpoint accepts far more tools than the 128-tool cap on `/chat/completions`.

## Configuration

Edit [`litellm_config.yaml`](litellm_config.yaml) to customize:
- Model mappings and capabilities
- Rate limits (`rpm_limit`)
- Request timeout
- Logging level

### Azure OpenAI (Entra ID)

To use `azure-gpt-5-mini`, populate these values in `.env`:

```
AZURE_OPENAI_ENDPOINT=https://<your-resource>.openai.azure.com/
AZURE_TENANT_ID=<tenant-id>
AZURE_CLIENT_ID=<service-principal-client-id>
AZURE_CLIENT_SECRET=<service-principal-client-secret>
```

The service principal must have the **Cognitive Services OpenAI User** role on the Azure OpenAI resource.

## Monitoring

```bash
# View logs
docker compose logs -f litellm

# Stop
docker compose down
```

## Architecture

- **LiteLLM Gateway** running in Docker, exposing an OpenAI-compatible API
- **PostgreSQL** for virtual key management and logging
- **GitHub Copilot** as the upstream LLM provider (via `github_copilot/` model prefix)
- OAuth token obtained via device code flow on container startup

## License

MIT
