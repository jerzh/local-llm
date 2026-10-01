"""Verify the local Qwen3.5 server can do OpenAI-style tool calling.

Run after `./run.sh` is up:
    pip install openai
    python test_agentic.py
"""
import json
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8080/v1", api_key="not-needed")

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get the current weather for a city.",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "City name"},
                },
                "required": ["city"],
            },
        },
    }
]

messages = [
    {"role": "user", "content": "What's the weather in San Francisco right now?"}
]

print(">>> Asking model to call get_weather('San Francisco')")
resp = client.chat.completions.create(
    model="qwen3.5-4b-instruct",
    messages=messages,
    tools=tools,
    tool_choice="auto",
)
msg = resp.choices[0].message
print("model response:")
print("  content:", msg.content)
print("  tool_calls:", msg.tool_calls)

if not msg.tool_calls:
    print("\nFAIL: model did not call the tool. Check llama-server logs for --jinja support.")
    raise SystemExit(1)

# Simulate executing the tool, then ask model to summarize.
tool_call = msg.tool_calls[0]
fake_result = {"city": "San Francisco", "temp_f": 62, "conditions": "foggy"}
messages.append(msg.model_dump(exclude_none=True))
messages.append({
    "role": "tool",
    "tool_call_id": tool_call.id,
    "content": json.dumps(fake_result),
})

print("\n>>> Sending tool result back, asking for final answer")
resp2 = client.chat.completions.create(
    model="qwen3.5-4b-instruct",
    messages=messages,
)
print("final:", resp2.choices[0].message.content)
print("\nPASS: tool-calling roundtrip works.")
