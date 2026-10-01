# Local agentic LLM

Qwen3.5-4B-Instruct (Q4_K_M GGUF) running locally on Apple Silicon via
`llama.cpp`'s server, exposing an OpenAI-compatible API with tool calling.

Qwen3.5 (released 2026) replaces the earlier Qwen2.5-7B setup here: the 4B
variant scores higher on tool-calling and agentic benchmarks than the old 7B
did, while using less RAM (~2.7 GB vs ~4.4 GB) — comfortable headroom on an
8 GB Mac even with the OS and a browser running.

## What you have

- `models/Qwen3.5-4B-Q4_K_M.gguf` — model weights (~2.7 GB, single file)
- `run.sh` — starts the server on `localhost:8080`
- `test_agentic.py` — verifies tool calling works end-to-end
- `setup-agent.sh` — one-time install of the agent harness (Open Interpreter)
- `agent.sh` — launches the agent so the model can run commands + edit files

## One-time host setup

On your Mac (not inside the Docker container):

```bash
brew install llama.cpp   # or: brew upgrade llama.cpp if already installed
pip install openai       # only needed for test_agentic.py
```

Qwen3.5 needs a reasonably recent `llama.cpp` build. If `run.sh` fails to
load the model with an "unknown architecture" error, `brew upgrade
llama.cpp` and try again.

## Run

```bash
cd /workspace/local-llm
./run.sh
```

First start takes ~10s while it mmaps the GGUF. After that:

- API base: `http://localhost:8080/v1`
- API key: anything (server ignores it)
- Model name: anything (server ignores it, it loads what `run.sh` specifies)

## Verify

In a second terminal:

```bash
cd /workspace/local-llm
python test_agentic.py
```

Should print a `get_weather` tool call, then a natural-language summary of the
fake weather result.

## Agent harness (run commands + read/write files)

[Open Interpreter](https://github.com/OpenInterpreter/open-interpreter) turns
the local model into an agent that can execute shell commands and edit files.
It talks to the same `localhost:8080` server, so nothing model-side changes.

Why this over Claude Code: Claude Code speaks Anthropic's API, not OpenAI's, so
it would need a translation proxy, and its large prompt/tool schemas crowd out
an 8k context on a 4B model. Open Interpreter is OpenAI-native, light on RAM,
and drives small local models by parsing code blocks rather than relying on
perfect JSON tool calls.

One-time install (on the host Mac):

```bash
cd /workspace/local-llm
./setup-agent.sh        # installs Open Interpreter via uv (needs uv on PATH)
```

Then, with the server already running (`./run.sh` in another terminal):

```bash
./agent.sh              # confirms each command before running it
./agent.sh -y           # auto-runs commands without confirming (riskier)
```

By default it pauses for your y/n before executing anything — keep it that way
until you trust a given task. The `--context_window` in `agent.sh` is pinned to
8192 to match `run.sh`'s `-c 8192`; if you change one, change both.

Expectation-setting: a 4B at Q4 is capable but not Claude-grade. It handles
single-file edits, scripted shell tasks, and quick automation well; it will
struggle with large multi-step refactors. If it feels sluggish or loops, the
smaller fallback below trades some smarts for speed and headroom; if you have
RAM to spare, the 9B step-up below trades headroom for smarts.

### Alternative: Aider

If your use is specifically *editing a code project* (diffs, git-aware), try
[Aider](https://aider.chat) instead:
`aider --openai-api-base http://localhost:8080/v1 --openai-api-key dummy --model openai/qwen`.
It's more code-focused; Open Interpreter is the better general "run commands +
touch files" agent, which is why it's the default here.

## RAM budget on 8 GB Mac

Comfortable. The model is ~2.7 GB resident, leaving more headroom for macOS
and a browser than the old 7B setup did. If you still see swapping or token
rates below ~5 tok/s, drop to the smaller 2B model:

```bash
# In models/, replace the download with:
curl -L -o Qwen3.5-2B-Q5_K_M.gguf \
  "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q5_K_M.gguf"
# Then edit run.sh: change MODEL= to point at it.
```

If you have 16 GB+ and want more capability instead, step up to the 9B
model (~5.5 GB resident at Q4_K_M):

```bash
curl -L -o Qwen3.5-9B-Q4_K_M.gguf \
  "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-Q4_K_M.gguf"
# Then edit run.sh: change MODEL= to point at it.
```

## Common API usage

From any Python script (or curl, or any OpenAI SDK):

```python
from openai import OpenAI
client = OpenAI(base_url="http://localhost:8080/v1", api_key="x")

resp = client.chat.completions.create(
    model="qwen",  # name doesn't matter, server uses whatever was loaded
    messages=[{"role": "user", "content": "Hello"}],
)
print(resp.choices[0].message.content)
```

For tool calling, define `tools=[...]` per the OpenAI spec — Qwen3.5 was
trained with native tool-calling tokens and llama-server's `--jinja` flag
exposes them through the standard `tool_calls` response field.

## Stopping

`Ctrl+C` in the `run.sh` terminal. No background daemon, no cleanup needed.
