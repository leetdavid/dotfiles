# Port Forwarding Manager

`pf` manages SSH-backed local port forwards as background services.

## Command Shape

```text
pf up 3000
pf up 3000:5000
pf check
pf check --all
pf check 3000 4983 8000:8080
pf up 3000 4983 8000:8080
pf down 3000
pf down --all
pf restart --all
pf ls
```

## Port Mapping

Port mappings are local-first, matching Docker and `ssh -L`:

- `pf up 3000` listens on local `3000` and connects to remote `3000`.
- `pf up 3000:5000` listens on local `3000` and connects to remote `5000`.

## Profile Defaults

Defaults live in `~/.config/pf/config` as shell assignments:

```sh
PF_HOST=mac
PF_REMOTE_HOST=localhost
PF_BIND=127.0.0.1
```

The command also supports one-off global overrides:

```text
pf --host mac --remote-host localhost --bind 127.0.0.1 up 3000
```

## Lifecycle

Each mapping is managed as its own forwarding service. Backend selection is automatic: on macOS, `pf` uses a per-mapping `launchd` user service. On Termux and other non-macOS shells, `pf` uses a small background supervisor process with pid files under `~/.local/state/pf`; the supervisor restarts `ssh` if it exits. Set `PF_BACKEND=launchd` or `PF_BACKEND=process` only when you need to override detection.

Termux needs OpenSSH installed:

```text
pkg install openssh
```

Because forwards run in the background, SSH must be able to connect non-interactively with keys and known hosts already set up.

`pf up` is idempotent when the existing service has the same mapping, profile, and service backend. If the same local port is already managed with different settings, `pf up` fails instead of silently replacing it.

`pf check` defaults to `pf check --all`, checking every managed forwarding service shown by `pf ls`. `pf check 3000 4983` verifies that those forwarding services are loaded and that a local connection can pass through the SSH forward without producing a fresh remote connect failure. It starts missing services and restarts matching managed services when the check fails. Use it after network changes, hibernation, or wake-from-sleep when the service may still exist but the SSH connection may be stale.

`pf down 3000` stops the service for local port `3000`. `pf down --all` stops every managed forwarding service.

`pf restart 3000` restarts an existing managed forwarding service from saved state. `pf restart --all` refreshes every managed forwarding service after network changes, hibernation, or wake-from-sleep without retyping the mappings.

## Listing

`pf ls` shows managed local ports, remote targets, SSH hosts, bind addresses, and service state. Launchd-backed services show `loaded`; process-backed services show `running`.
