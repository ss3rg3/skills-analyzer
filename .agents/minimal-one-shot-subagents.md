# Minimal One-Shot Subagents in OpenCode

Goal: use an OpenCode subagent like a direct LLM API call.
No agentic work, no tools, fixed model, minimal system prompt.
Useful for fan-out / aggregate patterns: send N simple prompts, collect text answers.

> Status: works as approximation. You cannot get zero-bloat in OpenCode.
> Custom `prompt` replaces only the provider base prompt, not the whole wrapper.

## 1. How OpenCode assembles the system prompt

Understanding this is required before tuning.

- Base prompt is provider-specific, selected by model ID from `packages/opencode/src/session/prompt/*.txt`: `default.txt`, `anthropic.txt`, `gpt.txt`, `beast.txt`, `gemini.txt`, `kimi.txt`, `meta.txt`, `codex.txt`, `trinity.txt`.
- `default.txt` starts with: `You are opencode, an interactive CLI tool...` plus tone/style (`<4 lines`, concise), proactiveness, conventions, `DO NOT ADD COMMENTS`, task loop, tool policy.
- Wrapper always added in `src/session/prompt.ts` `loop()` + `src/session/system.ts`:
  - `SystemPrompt.environment()`: `model.api.id`, `providerID`, `Working directory`, `Workspace root folder`, `Is directory a git repo: yes/no`, `Platform: process.platform`, `Today's date: toDateString()`, wrapped in `<env>`, plus `<available_references>` if configured.
  - `InstructionPrompt.system()`: `AGENTS.md` / `CLAUDE.md` / `instructions` from `opencode.json`.
  - `skills()`, `references`, `mcp_instructions`.
  - Tool schemas resolved via `resolveTools(agent.permission + session.permission)`.
- Final order in `src/session/llm.ts` `stream()`:
  ```ts
  ...(input.agent.prompt ? [input.agent.prompt] : SystemPrompt.provider(input.model)),
  ...input.system,
  ...(input.user.system ? [input.user.system] : [])
  ```
- Result: custom `prompt` / `system` **replaces** provider base, **does not remove** `environment()`, instructions, skills, references, MCP text, `user.system`, or enabled tools.

## 2. Minimal subagent recipe

### Todo list

- [ ] Pick a cheap, fast model for one-shots, e.g. `openai/gpt-5.6-luna`.
- [ ] Create agent file: `.opencode/agents/llm-direct.md` (project) or `~/.config/opencode/agents/llm-direct.md` (global).
- [ ] Set frontmatter: `mode: subagent`, `model: <provider/model>`, `description: <when to use>`.
- [ ] Set minimal `prompt` / `system`: e.g. `You are a helpful assistant. Answer directly, no tools.`.
- [ ] Deny all tools via `permission`: `edit: deny`, `bash: deny`, `webfetch: deny`, `websearch: deny`, `task: deny`, plus `read/glob/grep/list/lsp/skill` as needed, or `tools: { "*": false }` legacy.
- [ ] Limit iterations: `steps: 1`.
- [ ] Set determinism: `temperature: 0.0-0.2`, optional `top_p`.
- [ ] Remove instruction bloat for test runs: empty `AGENTS.md` chain, no `instructions` in config, no skills/MCP.
- [ ] Invoke via `@llm-direct <question>` or Task tool from primary agent, aggregate results in primary.
- [ ] Verify with `opencode run` / TUI that no tool calls happen and answer is text-only.

### Example: markdown agent

`.opencode/agents/llm-direct.md`:

```md
---
description: One-shot direct LLM, no tools. Use for simple classification, extraction, summarization.
mode: subagent
model: anthropic/claude-haiku-4-5
temperature: 0.1
steps: 1
permission:
  read: deny
  edit: deny
  glob: deny
  grep: deny
  list: deny
  bash: deny
  task: deny
  webfetch: deny
  websearch: deny
  skill: deny
---
You are a helpful assistant. Answer directly, no tools. Return text only, no tool calls.
```

### Example: JSON config

`opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "llm-direct": {
      "description": "One-shot direct LLM, no tools",
      "mode": "subagent",
      "model": "anthropic/claude-haiku-4-5",
      "prompt": "You are a helpful assistant. Answer directly, no tools.",
      "steps": 1,
      "temperature": 0.1,
      "permission": {
        "edit": "deny",
        "bash": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "task": "deny"
      }
    }
  }
}
```

### Invoke and aggregate

- [ ] Manual: `@llm-direct Summarize X in one sentence.`
- [ ] Agentic fan-out: primary agent calls Task tool N times with `subagent: llm-direct`, then merges strings.
- [ ] Keep `subagent_depth: 1` so `llm-direct` cannot spawn children.

## 3. Sources

Docs:

- https://opencode.ai/docs/agents/#prompt
- https://opencode.ai/docs/agents/#model
- https://opencode.ai/docs/agents/#permissions
- https://opencode.ai/docs/agents/#max-steps
- https://opencode.ai/docs/agents/#mode
- https://opencode.ai/docs/config/#agents
- https://opencode.ai/docs/models/
- https://opencode.ai/docs/rules/
- https://opencode.ai/v2/docs/agents/
- https://opencode.ai/v2/docs/instructions

Code (`sst/opencode`, same in `anomalyco/opencode` fork):

- https://github.com/sst/opencode/blob/dev/packages/opencode/src/session/system.ts
- https://github.com/sst/opencode/blob/dev/packages/opencode/src/session/llm.ts
- https://github.com/sst/opencode/blob/dev/packages/opencode/src/session/prompt.ts
- https://github.com/sst/opencode/blob/dev/packages/opencode/src/agent/agent.ts
- https://github.com/sst/opencode/tree/dev/packages/opencode/src/session/prompt
- https://raw.githubusercontent.com/sst/opencode/dev/packages/opencode/src/session/prompt/default.txt

## 4. Shortcomings

- [ ] No `systemPrompt: false` flag. `environment()` (`Working directory`, `Workspace root`, `git yes/no`, `Platform`, `Today's date`, model/provider IDs) is always sent.
- [ ] `AGENTS.md` / `instructions`, skills, references, MCP instructions are still added separately. Must empty/disable them per project to truly minimize.
- [ ] Tool schemas disappear only if permissions deny them. Miss one key (`lsp`, `read`, `glob`, custom `mcp_*`) and bloat + tool-call risk returns.
- [ ] `steps: 1` forces text-only after limit but still costs one agentic loop; model may still attempt a tool call first.
- [ ] Subagent inherits session context and runs inside OpenCode session billing/logging. Not equivalent to raw API cost/latency.
- [ ] V1 `prompt` vs V2 `system` naming differs. Docs quote: `A non-empty value replaces OpenCode's provider-specific base prompt... Project instructions, skills, references... are still added separately.` Easy to misread as full replacement.
- [ ] Aggregation is manual. No built-in map-reduce / fan-out helper; primary must coordinate Task calls and handle partial failures.
- [ ] Debugging bloat requires reading source (`system.ts`, `llm.ts`, `prompt.ts`), not docs. Behavior can drift between `sst/opencode` upstream and `anomalyco/opencode` fork.

## 5. Alternatives

Use these when you need true direct-LLM behavior, lower tokens, or bulk throughput.

- [ ] A. Direct provider SDK in script (`anthropic` / `openai` / `google` npm, Python). Best for pure one-shots, batch, evals. No OpenCode wrapper at all. Keep keys in env, not config.

  - [ ] Or better just OpenRouter.

- [ ] B. `opencode run --agent your-minified-agent --model <cheap-model> "prompt"` for ad-hoc CLI one-shots outside TUI session. Still has wrapper, but no subagent plumbing.

- [x] ~~C. `small_model` in `opencode.json` for built-in lightweight tasks (title/summary). Already optimized by OpenCode, no custom agent needed.~~

  Not possible, it's for OpenCode internal stuff:

  > small_model: used for built-in lightweight jobs — session title (title agent), summary (summary agent), auto-compaction. Docs: https://opencode.ai/docs/config/#models

- [x] ~~D. Custom OpenCode plugin with `experimental.chat.system.transform` hook to strip/mutate `input.system`. Powerful but fragile across versions; test after each update.~~ 
  Trash.

- [x] ~~E. Hidden internal subagent (`hidden: true`, `mode: subagent`) + strict `permission.task` allowlist, invoked only via Task tool. Same bloat as above, but cleaner UX for orchestrator pattern.~~ 
  Trash.

- [ ] F. External runner (Node/Python batch script) that calls ~~OpenCode SDK / server API~~ OpenRouter for N prompts in parallel and aggregates JSON. Better parallelism and retry control than in-TUI Task calls.
  :red_circle: This. You have Python just walk the subdirs, provide it with a system prompt from a file, and put the content of each file as user prompt.

- [ ] ~~G. MCP tool that wraps LLM call (`mcp_*` server doing direct API). Lets agent call `mcp_llm_ask` as a tool instead of spawning subagent. Still pays tool-schema cost, but centralizes model/key management.~~
  Trash.

- [x] ~~H. Do not use OpenCode at all for this step: use `llm` CLI, `mods`, `aichat`, or plain `curl` to provider endpoint in `assets/scripts/`. Simplest for Java repo preprocessing where agentic context adds zero value.~~
  Same as F.

Recommendation:

- Stay in OpenCode if orchestration + human review matters: use recipe in section 2.
- Leave OpenCode if token-exactness, reproducibility, or high-volume fan-out matters: use A or H.
