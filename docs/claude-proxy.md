# Claude Code proxy

Tinyproxy runs on the Mac mini at `mac:8888`, reachable over Tailscale.
Claude Code runs on each client with that client's existing authentication.

```text
Client Claude Code -> Tailscale -> Mac mini Tinyproxy
                   -> Mac mini's selected exit node -> Anthropic
```

HTTPS uses CONNECT tunnels, with TLS between Claude Code and Anthropic. The
proxy does not decrypt requests or store Anthropic credentials. The HTTP proxy
connection between devices is carried inside Tailscale's encrypted network.

## Use from a client

Connect the client to the same tailnet with Tailscale DNS enabled so `mac`
resolves through MagicDNS. With these dotfiles installed, run:

```sh
claude --settings "$HOME/.config/claude-proxy/client-settings.json"
```

Without the dotfiles, copy `client-settings.json` to the client and pass its
path to `claude --settings`. In PowerShell:

```powershell
claude --settings "$HOME\.config\claude-proxy\client-settings.json"
```

To use the proxy for every Claude Code session, merge the file's `env` entries
into the client's existing `~/.claude/settings.json`. Preserve the file's other
settings. Settings also reach background agents; shell-only exports may not.

Both lowercase and uppercase proxy variables are set because Claude Code gives
lowercase variables precedence. Loopback requests bypass the proxy. Claude's
child commands that honor proxy variables can also use it. Browser-based sign-in
uses the browser's network configuration, independently of this settings file.

Use `/status` in Claude Code to confirm the active proxy. Managed organization
settings can override these settings.

## Routing and failures

The Mac must keep a Tailscale exit node selected. At setup, that node was
`jp-tyo-wg-001` in Tokyo. Tinyproxy follows the Mac's current routing table;
changing or deselecting its exit node changes the proxy's outbound route.

Configured clients do not fall back to a direct connection when this proxy is
unreachable. They retry through the proxy and eventually report connection
errors. Tailscale blocks internet traffic when a selected exit node is
unavailable. The proxy itself does not enforce which exit node an administrator
selects.

Tinyproxy binds only to the Mac's Tailscale IPv4 address and accepts Tailscale
source addresses. Tailnet policy must permit clients to reach TCP port 8888 on
`tag:macmini`. Access follows that policy, including any future sharing changes.
HTTPS tunnels are limited to destination port 443.

## Install on the Mac mini

The server configuration targets David's Apple Silicon Mac mini. On another
host, update the address and absolute paths first.

```sh
brew install tinyproxy
mkdir -p "$HOME/.local/state/claude-proxy" "$HOME/Library/LaunchAgents"
chmod 700 "$HOME/.local/state/claude-proxy"

# Stow installs ~/.config/claude-proxy. For a targeted first install instead:
ln -s "$HOME/dotfiles/.config/claude-proxy" "$HOME/.config/claude-proxy"
ln -s "$HOME/.config/claude-proxy/com.david.claude-proxy.plist" \
  "$HOME/Library/LaunchAgents/com.david.claude-proxy.plist"

launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.david.claude-proxy.plist"
```

Skip a symlink command when that link already exists. The LaunchAgent starts at
login and restarts the proxy if it exits. If the Tailscale address is not ready
at startup, launchd retries. Keep this Mac awake for remote use.

## Check and manage

```sh
# Check egress through the proxy. This endpoint identifies Mullvad exit IPs.
curl --proxy http://mac:8888 --noproxy '' \
  --connect-timeout 10 --max-time 20 https://am.i.mullvad.net/json

# An unauthenticated 401 verifies the HTTPS tunnel to Anthropic.
curl --proxy http://mac:8888 --noproxy '' \
  --connect-timeout 10 --max-time 20 -sS -o /dev/null -w '%{http_code}\n' \
  https://api.anthropic.com/v1/models

# Inspect or restart after editing tinyproxy.conf.
launchctl print "gui/$(id -u)/com.david.claude-proxy"
launchctl kickstart -k "gui/$(id -u)/com.david.claude-proxy"

# Stop until loaded again or the next login.
launchctl bootout "gui/$(id -u)/com.david.claude-proxy"
```

Logs are in `~/.local/state/claude-proxy/`. To remove automatic startup, boot out
the service and remove its symlink from `~/Library/LaunchAgents/`.

## References

- [Claude Code proxy configuration](https://code.claude.com/docs/en/network-config)
- [Tinyproxy configuration](https://tinyproxy.github.io/)
- [Tailscale exit nodes](https://tailscale.com/docs/features/exit-nodes)
