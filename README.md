# LLM Proxy with LiteLLM Gateway

This project sets up an LLM proxy using a LiteLLM gateway container, configured to route requests through GitHub Copilot's backend API. It exposes an OpenAI-compatible endpoint at `http://localhost:4000`.

## Supported Models

### Anthropic
- **Claude Sonnet 4.6** (`claude-sonnet-4.6`)
- **Claude Opus 4.6** (`claude-opus-4.6`)
- **Claude Sonnet 4.5** (`claude-sonnet-4.5`)
- **Claude Opus 4.5** (`claude-opus-4.5`)
- **Claude Haiku 4.5** (`claude-haiku-4.5`)

### OpenAI
- **GPT-5 mini** (`gpt-5-mini`)
- **GPT-5.2** (`gpt-5.2`)
- **GPT-4.1** (`gpt-4.1`)
- **GPT-4o** (`gpt-4o`)
- **GPT-4o mini** (`gpt-4o-mini`)

### Google
- **Gemini 2.5 Pro** (`gemini-2.5-pro`)
- **Gemini 3 Pro Preview** (`gemini-3-pro-preview`)
- **Gemini 3 Flash Preview** (`gemini-3-flash-preview`)

### xAI
- **Grok Code Fast 1** (`grok-code-fast-1`)

### Azure OpenAI (via Entra ID)
- **GPT-5 mini** (`azure-gpt-5-mini`)

> **Note**: GitHub Copilot models use a Copilot for Business account. Azure OpenAI models require separate Azure credentials (see below).

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
    "model": "claude-sonnet-4.6",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### With Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(api_key="sk-1234", base_url="http://localhost:4000/v1")

response = client.chat.completions.create(
    model="claude-sonnet-4.6",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

See [USAGE.md](USAGE.md) for more examples (streaming, function calling, vision, Node.js).

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
