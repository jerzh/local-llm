#!/usr/bin/env bash
# Launch the agent: Open Interpreter driving your local Qwen3.5 server.
# Run this on the HOST Mac, in a second terminal, AFTER ./run.sh is up.
#
# What it can do: run shell commands and read/write files, asking you to
# confirm before each command runs (that's the default — see AUTO below).
#
# Usage:
#   ./agent.sh            # interactive, confirm each command (recommended)
#   ./agent.sh -y         # auto-run commands without confirmation (riskier)

set -euo pipefail

API_BASE="http://localhost:8080/v1"

# 1) Make sure the model server is actually up.
if ! curl -s -m 2 "$API_BASE/models" >/dev/null 2>&1; then
    echo "Can't reach the model server at $API_BASE" >&2
    echo "Start it first in another terminal:  ./run.sh" >&2
    exit 1
fi

# 2) Make sure the harness is installed.
if ! command -v interpreter >/dev/null 2>&1; then
    echo "'interpreter' not found. Install it first:  ./setup-agent.sh" >&2
    echo "(then open a new shell, or run: pipx ensurepath)" >&2
    exit 1
fi

AUTO=()
if [ "${1:-}" = "-y" ]; then
    AUTO=(-y)   # --auto_run: execute commands without asking. Use with care.
fi

# Flags:
#   --api_base / --api_key : point at the local OpenAI-compatible server.
#   --model openai/...     : the "openai/" prefix tells LiteLLM to use the
#                            OpenAI-compatible protocol; the name after it is
#                            cosmetic (llama-server serves whatever run.sh loaded).
#   --context_window 8192  : must match run.sh's -c 8192 so OI trims correctly.
#   --max_tokens 1200      : cap per-reply so a long answer can't blow the window.
exec interpreter \
    --api_base "$API_BASE" \
    --api_key dummy \
    --model openai/qwen3.5-4b-instruct \
    --context_window 8192 \
    --max_tokens 1200 \
    "${AUTO[@]}"
