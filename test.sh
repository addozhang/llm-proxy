#!/bin/bash

# Test script for LiteLLM Proxy with GitHub Copilot models
# Usage: ./test.sh [API_KEY]

set -euo pipefail

# Bypass any system proxy for localhost
export no_proxy="localhost,127.0.0.1"
export NO_PROXY="localhost,127.0.0.1"

PROXY_URL="http://localhost:4000"

# Load API key from argument, environment, or .env file
if [ -n "${1:-}" ]; then
  API_KEY="$1"
elif [ -n "${LITELLM_MASTER_KEY:-}" ]; then
  API_KEY="$LITELLM_MASTER_KEY"
elif [ -f .env ]; then
  API_KEY=$(grep -E '^LITELLM_MASTER_KEY=' .env | cut -d'=' -f2-)
else
  API_KEY="sk-1234"
fi

PASS=0
FAIL=0
SKIP=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
  echo ""
  echo -e "${CYAN}=== $1 ===${NC}"
}

print_pass() {
  echo -e "  ${GREEN}PASS${NC}: $1"
  ((PASS++)) || true
}

print_fail() {
  echo -e "  ${RED}FAIL${NC}: $1"
  ((FAIL++)) || true
}

print_skip() {
  echo -e "  ${YELLOW}SKIP${NC}: $1"
  ((SKIP++)) || true
}

# Helper: make a chat completion request and check the response
test_model() {
  local test_num=$1
  local model=$2
  local prompt=$3
  local max_tokens=${4:-50}

  print_header "Test ${test_num}: ${model}"

  local response
  local http_code
  local tmpfile
  tmpfile=$(mktemp)

  http_code=$(curl -s --max-time 120 -o "$tmpfile" -w "%{http_code}" \
    "${PROXY_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "{
      \"model\": \"${model}\",
      \"messages\": [{\"role\": \"user\", \"content\": \"${prompt}\"}],
      \"max_tokens\": ${max_tokens}
    }" 2>&1)

  response=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [ "$http_code" = "200" ]; then
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
    if [ -n "$content" ]; then
      print_pass "${model} responded (HTTP ${http_code})"
      echo "  Response: ${content:0:120}..."
    else
      print_fail "${model} returned 200 but no content"
      echo "  Raw: ${response:0:200}"
    fi
  elif [ "$http_code" = "000" ]; then
    print_fail "${model} - connection refused (is the proxy running?)"
  else
    local error_msg
    error_msg=$(echo "$response" | jq -r '.error.message // .detail // .message // empty' 2>/dev/null)
    print_fail "${model} (HTTP ${http_code}): ${error_msg:-$response}"
  fi
}

# Helper: make a /v1/responses request and check the response (for Copilot models
# that only expose the Responses API, e.g. gpt-5.6-luna, grok-4.6).
test_responses_model() {
  local test_num=$1
  local model=$2
  local prompt=$3
  local max_tokens=${4:-50}

  print_header "Test ${test_num}: ${model} (/v1/responses)"

  local response
  local http_code
  local tmpfile
  tmpfile=$(mktemp)

  http_code=$(curl -s --max-time 120 -o "$tmpfile" -w "%{http_code}" \
    "${PROXY_URL}/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "{
      \"model\": \"${model}\",
      \"input\": \"${prompt}\",
      \"max_output_tokens\": ${max_tokens}
    }" 2>&1)

  response=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [ "$http_code" = "200" ]; then
    # Responses API returns output as an array of items; extract any text content.
    local content
    content=$(echo "$response" | jq -r '
      .output_text //
      ([.output[]? | select(.type=="message") | .content[]? | select(.type=="output_text") | .text] | join(" ")) //
      empty
    ' 2>/dev/null)
    if [ -n "$content" ] && [ "$content" != "null" ]; then
      print_pass "${model} responded (HTTP ${http_code})"
      echo "  Response: ${content:0:120}..."
    else
      print_fail "${model} returned 200 but no text content"
      echo "  Raw: ${response:0:200}"
    fi
  elif [ "$http_code" = "000" ]; then
    print_fail "${model} - connection refused (is the proxy running?)"
  else
    local error_msg
    error_msg=$(echo "$response" | jq -r '.error.message // .detail // .message // empty' 2>/dev/null)
    print_fail "${model} (HTTP ${http_code}): ${error_msg:-$response}"
  fi
}

echo "============================================"
echo " LiteLLM Proxy - Test Suite"
echo " Proxy: ${PROXY_URL}"
echo " API Key: ${API_KEY:0:8}..."
echo "============================================"

# --------------------------------------------------
# Test 1: Health check
# --------------------------------------------------
print_header "Test 1: Health Check"
health_code=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" "${PROXY_URL}/health/liveliness" 2>&1)
if [ "$health_code" = "200" ]; then
  print_pass "Proxy is healthy (HTTP ${health_code})"
else
  print_fail "Health check failed (HTTP ${health_code})"
  echo -e "${RED}Proxy is not healthy. Remaining tests may fail.${NC}"
fi

# --------------------------------------------------
# Test 2: List models
# --------------------------------------------------
print_header "Test 2: List Models"
models_response=$(curl -s --max-time 15 "${PROXY_URL}/models" \
  -H "Authorization: Bearer ${API_KEY}" 2>&1)
model_count=$(echo "$models_response" | jq -r '.data | length' 2>/dev/null)

if [ -n "$model_count" ] && [ "$model_count" -gt 0 ] 2>/dev/null; then
  print_pass "Found ${model_count} models"
  echo "$models_response" | jq -r '.data[].id' 2>/dev/null | while read -r m; do
    echo "  - ${m}"
  done
else
  print_fail "No models returned"
  echo "  Response: ${models_response:0:200}"
fi

# --------------------------------------------------
# Tests 3-10: One model per provider family
# --------------------------------------------------
test_model           3  "claude-sonnet-5"      "Say hello in one sentence"                       300
test_model           4  "gemini-3.7-flash"     "What is the speed of light? Answer briefly."     300
test_model           5  "kimi-k3"              "What is the capital of Spain? Answer briefly."   200
test_responses_model 6  "gpt-5.6-luna"         "What is the capital of France? Answer briefly."  300
test_responses_model 7  "gpt-5.6-sol"          "What is the capital of Germany? Answer briefly." 300
test_responses_model 8  "gpt-5.6-terra"        "What is the capital of Japan? Answer briefly."   300
test_responses_model 9  "grok-4.6"             "What is the capital of Italy? Answer briefly."   300
test_responses_model 10 "mai-code-1.1-flash"   "What is the capital of Canada? Answer briefly."  300

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo ""
echo "============================================"
echo -e " Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${YELLOW}${SKIP} skipped${NC}"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
