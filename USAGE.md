# Usage Guide

## Getting Started

### 1. Setup Environment

```bash
cp .env.example .env
# Edit .env to set LITELLM_MASTER_KEY (default: sk-1234)
```

### 2. Start the Proxy

```bash
docker compose up -d

# Watch logs — the container will print the GitHub device code on first start
docker compose logs -f litellm

# Check health (after auth is complete)
curl http://localhost:4000/health/liveliness
```

> **First start**: Look for output like:
> ```
> Please visit: https://github.com/login/device
> Enter code: XXXX-XXXX
> ```
> Open the URL, enter the code, and authorize. The proxy starts automatically once authorized.
> If the token expires, restart the container (`docker compose restart litellm`) and repeat.

### 3. Stop the Proxy

```bash
docker compose down
```

## Available Models

| Model Name | Provider | Function Calling | Vision |
|---|---|---|---|
| `claude-sonnet-4.6` | Anthropic | Yes | Yes |
| `claude-opus-4.6` | Anthropic | Yes | Yes |
| `claude-sonnet-4.5` | Anthropic | Yes | Yes |
| `claude-opus-4.5` | Anthropic | Yes | Yes |
| `claude-haiku-4.5` | Anthropic | Yes | No |
| `gpt-5-mini` | OpenAI | Yes | Yes |
| `gpt-5.2` | OpenAI | Yes | Yes |
| `gpt-4.1` | OpenAI | Yes | Yes |
| `gpt-4o` | OpenAI | Yes | Yes |
| `gpt-4o-mini` | OpenAI | Yes | No |
| `grok-code-fast-1` | xAI | Yes | No |
| `gemini-2.5-pro` | Google | Yes | Yes |
| `gemini-3-pro-preview` | Google | Yes | Yes |
| `gemini-3-flash-preview` | Google | Yes | Yes |

## API Examples

### Basic Chat Completion

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-sonnet-4.6",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is the capital of France?"}
    ]
  }'
```

### Streaming Response

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-sonnet-4.6",
    "messages": [{"role": "user", "content": "Tell me a story"}],
    "stream": true
  }'
```

### Using Different Models

```bash
# GPT-4o
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{"model": "gpt-4o", "messages": [{"role": "user", "content": "Hello"}]}'

# Gemini 2.5 Pro
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{"model": "gemini-2.5-pro", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 200}'

# Grok Code Fast
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{"model": "grok-code-fast-1", "messages": [{"role": "user", "content": "Write a Python function"}]}'
```

> **Tip**: Gemini models use thinking/reasoning tokens internally. Use `max_tokens: 200` or higher to ensure the response includes visible content.

### Function Calling

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-sonnet-4.6",
    "messages": [{"role": "user", "content": "What is the weather in Paris?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get weather information",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {"type": "string", "description": "City name"}
          },
          "required": ["location"]
        }
      }
    }]
  }'
```

### Vision (with GPT-5, GPT-4o, or Gemini models)

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "gpt-4o",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "What is in this image?"},
        {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
      ]
    }]
  }'
```

## Python SDK Example

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-1234",
    base_url="http://localhost:4000/v1"
)

response = client.chat.completions.create(
    model="claude-sonnet-4.6",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello!"}
    ]
)

print(response.choices[0].message.content)
```

## Node.js Example

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: 'sk-1234',
  baseURL: 'http://localhost:4000/v1'
});

async function main() {
  const response = await client.chat.completions.create({
    model: 'claude-sonnet-4.6',
    messages: [
      { role: 'system', content: 'You are a helpful assistant.' },
      { role: 'user', content: 'Hello!' }
    ]
  });
  
  console.log(response.choices[0].message.content);
}

main();
```

## Available Endpoints

- `POST /v1/chat/completions` - Chat completions (OpenAI compatible)
- `GET /health/liveliness` - Health check
- `GET /models` - List available models
- `GET /model/info` - Get model information

## Troubleshooting

### Check Logs
```bash
docker compose logs -f litellm
```

### Restart Container
```bash
docker compose restart litellm
```

### Validate Configuration
```bash
docker compose config
```

### Test Connection
```bash
# Health check
curl http://localhost:4000/health/liveliness

# List models
curl http://localhost:4000/models \
  -H "Authorization: Bearer sk-1234"

# Run full test suite
./test.sh
```

### Common Issues

- **Empty responses from Gemini models**: Increase `max_tokens` to 200+ — Gemini uses internal thinking tokens that consume the budget.
- **Auth failures (403/401)**: The OAuth token may have expired. Restart the container (`docker compose restart litellm`) and follow the device code flow in the logs.
- **Connection refused**: Ensure `docker compose up -d` is running and the container is healthy (`docker compose ps`).
- **Proxy interference**: If you have `http_proxy` set, add `no_proxy=localhost,127.0.0.1` to bypass it for local requests.

## Configuration Options

Edit [`litellm_config.yaml`](litellm_config.yaml) to customize:

- **Rate limits**: Adjust `rpm_limit` in router settings
- **Timeouts**: Change `request_timeout` in general settings
- **Logging**: Modify `log_level` (DEBUG, INFO, WARNING, ERROR)
- **Fallbacks**: Enable/disable with `enable_fallbacks`

## Security Notes

- Always use a strong `LITELLM_MASTER_KEY` in production
- Keep your `.env` file secure and never commit it to version control
- The default master key `sk-1234` is for development only
