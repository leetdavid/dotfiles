# Claude Code through CLIProxyAPI

Clients use `http://mac:8317` as their Anthropic API base URL. CLIProxyAPI selects
the upstream Claude subscription credential on the Mac mini.

```text
Claude Code -> Tailscale -> mac:8317 CLIProxyAPI -> selected exit node -> Anthropic
```

The profile also sends other proxy-aware Claude CLI traffic through Tinyproxy
at `mac:8888`. `NO_PROXY` sends calls to `mac:8317` directly over Tailscale.
Browser sign-in and other applications use their own network settings.

## Set up each client

Connect Tailscale and enable its DNS settings so `mac` resolves. The Mac mini
has a ready-to-use private profile with the gateway client key filled in:

```sh
mkdir -p "$HOME/.claude"
scp david@mac:.claude/cliproxyapi.json "$HOME/.claude/cliproxyapi.json"
chmod 600 "$HOME/.claude/cliproxyapi.json"
claude --settings "$HOME/.claude/cliproxyapi.json"
```

The key is transferred over SSH and stays outside the dotfiles repository.
Replace an existing private profile only if it is the one you intend to update.
If the gateway client key changes, update the private profile and client copies.

### Recreate a profile from the template

Copy `.config/claude-gateway/client-settings.example.json` to the private path
`~/.claude/cliproxyapi.json`. Replace `REPLACE_WITH_CLIPROXYAPI_CLIENT_KEY` with
the key under `access.api-keys` in `/opt/homebrew/etc/cliproxyapi.conf` on the Mac
mini, then set the private file's permissions to `600`. Keep the real key out of
the repository.

On Windows, save the edited private file at `$HOME\.claude\cliproxyapi.json`
and run this in PowerShell:

```powershell
claude --settings "$HOME\.claude\cliproxyapi.json"
```

To apply this to ordinary `claude` launches and background agents, merge the
profile's `env`, `model`, and `availableModels` entries into the client's existing
`~/.claude/settings.json`, preserving its other settings. Managed organization
settings can override user settings.

The client authenticates to CLIProxyAPI using the gateway key. Upstream Claude
subscription tokens stay on the Mac mini. The gateway processes model request
contents; Tailscale encrypts the connection between client and gateway.

## Subscription-only model routing

This server also has API-key routes. Unprefixed Claude model names can select
those routes, so this profile uses three unique aliases:

| Client model | Upstream model |
| --- | --- |
| `claude-sonnet-5-5-subscription` | `claude-sonnet-5-5` |
| `claude-opus-5-5-subscription` | `claude-opus-5-5` |
| `claude-haiku-5-5-subscription` | `claude-haiku-5-5` |

They are configured under `oauth.model-alias.claude`, which does not apply to
API-key routes. The reproducible configuration fragment is
`.config/claude-gateway/cliproxyapi-oauth-models.yaml`. Merge it into the existing
`oauth` section of the server configuration. `fork: true` also keeps the original
model IDs available to existing clients.

Keep these aliases unique to Claude OAuth credentials. Requests using them fail
when no eligible subscription credential can serve the request. Choosing a raw
model ID or adding the aliases to an API-key provider can change the billing
route. The available-model list in this client profile is a convenience, not a
server-side access restriction.

The model list confirms advertised routing, not upstream account validity. A
revoked upstream account still fails through a gateway.

Setup verification on October 23, 2026: the subscription-only Haiku alias
returned `OK` through the Messages API. Native Claude Code returned `OK` with
both Haiku and the profile's default Sonnet alias. A concurrent network sample
showed the gateway's Anthropic connection on Tailscale.

## Verify routing and watch traffic

Run `/status` inside the client session and check that the API base URL is
`http://mac:8317` and the selected model ends in `-subscription`.

On the Mac mini, observe connection metadata and byte counters:

```sh
lsof -nP -a -c cliproxyapi -iTCP
nettop -n -m tcp -p cliproxyapi -L 10 -s 1 -x \
  -J interface,state,bytes_in,bytes_out
```

A connection from the client's Tailscale IP to port 8317 confirms the gateway
connection. Process counters combine traffic from all clients and both sides of
forwarded requests. These counters do not identify the model, billing account,
or contents of a request.

The gateway-side capture shows traffic that reaches this Mac. To find direct
connections from Claude Code on a client, run `nettop` on that client with
`-p claude`.

## References

- [CLIProxyAPI Claude Code client configuration](https://help.router-for.me/agent-client/claude-code)
- [CLIProxyAPI v8 routing and OAuth aliases](https://help.router-for.me/configuration/options)
- [Claude Code network configuration](https://code.claude.com/docs/en/network-config)
