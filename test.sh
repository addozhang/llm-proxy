#!/bin/bash

# Test script for LiteLLM Proxy with GitHub Copilot models

PROXY_URL="http://localhost:4000"
API_KEY="sk-1234"  # Default master key from .env

echo "Testing LiteLLM Proxy with GitHub Copilot models..."
echo "=================================================="
echo ""

# Test 1: Health check
echo "1. Health Check:"
curl -s "${PROXY_URL}/health/liveliness"
echo -e "\n"

# Test 2: List models
echo "2. List Available Models:"
curl -s "${PROXY_URL}/models" \
  -H "Authorization: Bearer ${API_KEY}"
echo -e "\n"

# Test 3: Claude Sonnet 4.5
echo "3. Testing Claude Sonnet 4.5:"
curl -s "${PROXY_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "editor-version: vscode/1.85.1" \
  -H "Copilot-Integration-Id: vscode-chat" \
  -d '{
    "model": "claude-sonnet-4.5",
    "messages": [{"role": "user", "content": "Say hello in one sentence"}],
    "max_tokens": 50
  }' | jq -r '.choices[0].message.content // .'
echo -e "\n"

# Test 4: Gemini 2.5 Pro
echo "4. Testing Gemini 2.5 Pro:"
curl -s "${PROXY_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "editor-version: vscode/1.85.1" \
  -H "Copilot-Integration-Id: vscode-chat" \
  -d '{
    "model": "gemini-2.5-pro",
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "max_tokens": 50
  }' | jq -r '.choices[0].message.content // .'
echo -e "\n"

# Test 5: Grok Code Fast 1
echo "5. Testing Grok Code Fast 1:"
curl -s "${PROXY_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "editor-version: vscode/1.85.1" \
  -H "Copilot-Integration-Id: vscode-chat" \
  -d '{
    "model": "grok-code-fast-1",
    "messages": [{"role": "user", "content": "Write a hello world in Python"}],
    "max_tokens": 100
  }' | jq -r '.choices[0].message.content // .'
echo -e "\n"

echo "=================================================="
echo "Test completed!"
