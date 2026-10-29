# Claude subscription fallback through Vercel

Claude Code sends requests to CLIProxyAPI at `http://mac:8317`. CLIProxyAPI uses
available Claude subscription credentials first, then Vercel AI Gateway when
those credentials are unavailable or cooling down after a quota error.

The Mac mini's live configuration is `/opt/homebrew/etc/cliproxyapi.conf`.
It contains credentials and is not tracked in this repository.

## Model matching

CLIProxyAPI matches client model IDs against configured aliases. The imported
Vercel alias `Claude Opus 5.5` does not match Claude Code's `claude-opus-5-5`.
Without a matching alias, subscription exhaustion returns 429 even when the
Vercel provider works.

The active Vercel Claude provider retains its imported display aliases and adds
native Claude IDs for the imported Anthropic models. For example:

| Client alias | Vercel upstream model |
| --- | --- |
| `claude-opus-5-5` | `claude-code/anthropic/claude-opus-5.5[1m]` |
| `claude-sonnet-5-5` | `claude-code/anthropic/claude-sonnet-5.5[1m]` |
| `claude-haiku-5-5` | `claude-code/anthropic/claude-haiku-5.5[1m]` |

These mappings belong in the existing key's `models` list under
`api-keys.claude`. Per-key model lists override group-level lists, so add new
mappings alongside the existing per-key entries.

## Priority

- Subscription credentials use their default priority of `0`.
- The Vercel key has `priority: -1` and `weight: 1`.
- Session affinity is disabled, so a recovered subscription can serve the next
  request instead of leaving the session bound to Vercel.

Higher priority wins among available matching credentials. Weight controls
selection within a priority tier; a small weight alone does not make Vercel a
fallback. Explicit `-subscription` model aliases still select subscription
credentials only.

The Vercel provider's base URL is
`https://ai-gateway.vercel.sh/claude-code`. CLIProxyAPI appends `/v1/messages`.
Vercel accepts the catalog's `claude-code/` prefix and `[1m]` suffix.

CLIProxyAPI reloads this configuration live. Retry the failed Claude Code turn
after saving; existing sessions do not need to restart.

## Check

Inspect `/v1/models` for the exact client aliases, then send a small request to
`/v1/messages` using the same model as the failed turn. During subscription
cooldown, `claude-opus-5-5` should succeed through Vercel rather than return
`All credentials ... are cooling down`. A successful model-list request alone
does not verify inference or fallback routing.

See [Vercel's Claude Code endpoint documentation](https://vercel.com/docs/ai-gateway/coding-agents/claude-code#claude-code-compatibility-endpoint)
and [CLIProxyAPI's v8 configuration reference](https://github.com/router-for-me/CLIProxyAPI/blob/v8.0.20/config.example.yaml).
