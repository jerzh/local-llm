#!/usr/bin/env bash
# Start llama.cpp's OpenAI-compatible server with Qwen3.5-4B-Instruct.
# Run this on the HOST Mac (not inside the Docker container) so Metal GPU
# acceleration is available.
#
# Prerequisite (one-time):
#   brew install llama.cpp      # or: brew upgrade llama.cpp
#   (Qwen3.5 needs a reasonably recent llama.cpp; upgrade if the server
#   fails to load the GGUF with an "unknown architecture" error.)
#
# Usage:
#   ./run.sh
#
# API will be at http://localhost:8080/v1 (OpenAI-compatible).

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="$DIR/models/Qwen3.5-4B-Q4_K_M.gguf"

if [ ! -f "$MODEL" ]; then
    echo "Model not found: $MODEL" >&2
    exit 1
fi

if ! command -v llama-server >/dev/null 2>&1; then
    echo "llama-server not found. Install with: brew install llama.cpp" >&2
    exit 1
fi

# --jinja enables Qwen3.5's embedded chat template, which supports tool calls.
# -ngl 99 offloads all layers to Metal (Apple GPU).
# -c 8192 = 8k context. Bump if you need more (uses more RAM).
# --host 127.0.0.1 keeps it local-only.
exec llama-server \
    --model "$MODEL" \
    --host 127.0.0.1 \
    --port 8080 \
    -c 8192 \
    -ngl 99 \
    --jinja
