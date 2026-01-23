# Usage Guide

## Getting Started

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env and add your API keys
nano .env
```

### 2. Start the Proxy

```bash
# Start in detached mode
docker-compose up -d

# View logs
docker-compose logs -f litellm

# Check health
curl http://localhost:4000/health
```

### 3. Stop the Proxy

```bash
docker-compose down
```

## API Examples

### Basic Chat Completion

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-sonnet-4.5",
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
    "model": "claude-sonnet-4.5",
    "messages": [{"role": "user", "content": "Tell me a story"}],
    "stream": true
  }'
```

### Using Different Models

```bash
# Claude Sonnet 4
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{"model": "claude-sonnet-4", "messages": [{"role": "user", "content": "Hello"}]}'

# Gemini 2.5 Pro
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{"model": "gemini-2.5-pro", "messages": [{"role": "user", "content": "Hello"}]}'

# Grok Code Fast
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{"model": "grok-code-fast-1", "messages": [{"role": "user", "content": "Write a Python function"}]}'
```

### Function Calling

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-sonnet-4.5",
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

### Vision (with Claude Sonnet 4.5 or Gemini)

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "claude-sonnet-4.5",
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

# Initialize client
client = OpenAI(
    api_key="sk-1234",
    base_url="http://localhost:4000/v1"
)

# Make request
response = client.chat.completions.create(
    model="claude-sonnet-4.5",
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
    model: 'claude-sonnet-4.5',
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
- `GET /health` - Health check
- `GET /models` - List available models
- `GET /model/info` - Get model information

## Troubleshooting

### Check Logs
```bash
docker-compose logs -f litellm
```

### Restart Container
```bash
docker-compose restart litellm
```

### Validate Configuration
```bash
docker-compose config
```

### Test Connection
```bash
# Health check
curl http://localhost:4000/health

# List models
curl http://localhost:4000/models \
  -H "Authorization: Bearer sk-1234"
```

## Configuration Options

Edit [`litellm_config.yaml`](litellm_config.yaml) to customize:

- **Rate limits**: Adjust `rpm_limit` in router settings
- **Timeouts**: Change `request_timeout` in general settings
- **Logging**: Modify `log_level` (DEBUG, INFO, WARNING, ERROR)
- **Fallbacks**: Enable/disable with `enable_fallbacks`
- **Model aliases**: Add custom aliases in `model_group_alias`

## Security Notes

- Always use a strong `LITELLM_MASTER_KEY` in production
- Keep your [`.env`](.env) file secure and never commit it to version control
- Consider using Docker secrets or environment variable management tools for production
- The default master key `sk-1234` is for development only

## Performance Tips

- Use streaming for long responses to reduce latency
- Enable caching in config if making repeated similar requests
- Adjust rate limits based on your API quotas
- Use faster models (like Haiku or Grok Fast) for simple tasks
