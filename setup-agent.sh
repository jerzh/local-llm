#!/usr/bin/env bash
# One-time install of the agent harness (Open Interpreter) on the HOST Mac.
# Run this OUTSIDE the Docker container.
#
# Open Interpreter lets the local Qwen3.5 model run terminal commands and
# read/write files. It talks to the llama.cpp server you already start with
# ./run.sh, so there's nothing model-side to change.
#
# Usage:
#   ./setup-agent.sh

set -euo pipefail

echo "==> Checking for uv"
if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found. Install with one of:" >&2
    echo "    brew install uv" >&2
    echo "    curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    exit 1
fi

echo "==> Installing Open Interpreter as a uv tool"
# 'uv tool install' gives OI its own isolated environment (like pipx) and puts
# the 'interpreter' command on your PATH. Open Interpreter needs Python 3.10+;
# --python lets uv fetch/manage a suitable interpreter if your system one is older.
uv tool install --python 3.11 open-interpreter || uv tool upgrade open-interpreter

echo "==> Ensuring uv's tool bin is on PATH"
uv tool update-shell || true

echo
echo "Done. If 'interpreter' isn't found in a new shell, open a fresh terminal"
echo "(uv tool update-shell edits your shell profile)."
echo "Then start the model server (./run.sh) and the agent (./agent.sh)."
