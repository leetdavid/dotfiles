# Dotfiles

Personal command-line tooling and machine-local workflows managed as dotfiles.

## Language

**Forwarding profile**:
A named set of defaults used when opening SSH-backed port forwards.
_Avoid_: Default host, remote PC

**Port mapping**:
A local-first pair that connects a local listening port to a port reachable from the forwarding target.
_Avoid_: Remote-first mapping

**Forwarding service**:
A managed background port forward that stays available until explicitly stopped.
_Avoid_: Tunnel process, SSH job

## Relationships

- A **Forwarding profile** selects the remote machine used by a port-forward command when the command does not name one explicitly.
- A **Port mapping** with one port mirrors that port locally and remotely; a two-port mapping names the local port first and the remote port second.
- A **Forwarding service** applies a **Forwarding profile** to one **Port mapping**.

## Example dialogue

> **Dev:** "Should the forwarding command always connect to `mac`?"
> **Domain expert:** "No — it should use the configured **Forwarding profile** so the short command stays machine-independent."

> **Dev:** "Does `3000:5000` follow the Docker and `ssh -L` order?"
> **Domain expert:** "Yes — the **Port mapping** listens on local `3000` and reaches remote `5000`."

> **Dev:** "If the SSH connection drops, should I run the command again?"
> **Domain expert:** "No — the **Forwarding service** should keep the mapping available until you stop it."

## Flagged ambiguities

- "remote PC" was used for the machine reached over SSH — resolved: command defaults come from a **Forwarding profile** rather than from a hard-coded host.
- `3000:5000` could be read as remote-first — resolved: **Port mapping** is local-first, matching Docker and `ssh -L`.
