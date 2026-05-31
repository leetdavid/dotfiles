# Use launchd for port forwarding services

Port forwards should behave like durable local services, not terminal-bound SSH sessions. We use per-mapping `launchd` user services with keepalive so forwards survive transient SSH drops and can be stopped intentionally with `pf down`, accepting macOS-specific implementation in exchange for reliable lifecycle management.

## Considered Options

- Detached SSH processes with pid files would be more portable but would duplicate process supervision.
- tmux sessions would be inspectable but would couple the service lifecycle to terminal tooling.
- Foreground SSH would be simplest but would not satisfy the service-like behavior.
