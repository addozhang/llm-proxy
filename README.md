# LLM Proxy with LiteLLM Gateway

This project sets up an LLM proxy using LiteLLM gateway container, configured with GitHub Copilot models.

## Supported Models

- **Anthropic Claude Sonnet 4.5** (`claude-sonnet-4.5`)
- **Anthropic Claude Sonnet 4** (`claude-sonnet-4`)
- **Anthropic Claude Haiku 4.5** (`claude-haiku-4.5`)
- **Gemini 2.5 Pro** (`gemini-2.5-pro`)
- **Gemini 3 Pro** (`gemini-3-pro`)
- **xAI Grok Code Fast 1** (`grok-code-fast-1`)
- **OpenAI GPT-4.1** (`gpt-4.1`)
- **OpenAI GPT-4o** (`gpt-4o`)

## Prerequisites

- Docker and Docker Compose installed
- GitHub Copilot API key

## Quick Start

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit [`.env`](.env) and add your GitHub Copilot API key:
   ```
   GITHUB_COPILOT_API_KEY=your_github_copilot_key
   ```

3. Start the LiteLLM gateway:
   ```bash
   docker-compose up -d
   ```

4. The proxy will be available at `http://localhost:4000`

## Usage

### Making API Requests

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-master-key" \
  -d '{
    "model": "claude-sonnet-4.5",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Available Model Names

Use these model names in your API requests:
- `claude-sonnet-4.5`
- `claude-sonnet-4`
- `claude-haiku-4.5`
- `gemini-2.5-pro`
- `gemini-3-pro`
- `grok-code-fast-1`
- `gpt-4.1`
- `gpt-4o`

## Configuration

The proxy configuration is in [`litellm_config.yaml`](litellm_config.yaml). You can customize:
- Model mappings
- Rate limits
- Fallback models
- Logging levels
- Authentication settings

## Monitoring

View logs:
```bash
docker-compose logs -f litellm
```

Stop the proxy:
```bash
docker-compose down
```

## Health Check

```bash
curl http://localhost:4000/health
```

## Architecture

This setup uses:
- **LiteLLM Gateway**: Proxy server running in Docker container
- **OpenAI-compatible API**: All requests follow OpenAI API format
- **Multi-provider support**: Route requests to different LLM providers

## License

MIT
