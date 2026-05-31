# Use launchd for macOS port forwarding services

Port forwards should behave like durable local services, not terminal-bound SSH sessions. On macOS, we use per-mapping `launchd` user services with keepalive so forwards survive transient SSH drops and can be stopped intentionally with `pf down`.

Termux does not have `launchctl`, so `pf` uses a per-mapping background supervisor process there. The process backend keeps pid files in the `pf` state directory and restarts `ssh` until `pf down` creates the stop signal and terminates the supervisor.

## Considered Options

- Detached SSH processes with pid files would be more portable but would duplicate process supervision.
- tmux sessions would be inspectable but would couple the service lifecycle to terminal tooling.
- Foreground SSH would be simplest but would not satisfy the service-like behavior.
