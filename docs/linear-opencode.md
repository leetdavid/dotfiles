# Linear to remote OpenCode

Clicking **Work on issue → Custom script** in Linear desktop submits the issue prompt to a fresh OpenCode session on the SSH host `mac`. It starts coding in `~/dev/pulse` without opening a terminal or browser. Join the session later through OpenCode web.

The client sends the prompt through SSH stdin. The server uses `opencode api` to discover and authenticate with the existing shared OpenCode service, creates a session, and submits a prompt with execution enabled. SSH exits after submission is acknowledged, not after the coding task finishes. The service and machine must stay running.

Normal model, agent, project instructions, and permissions apply. There is no auto-approval flag or Linear API credential. Permission requests can pause the task until you approve them in OpenCode web.

## Server setup

The server needs OpenCode V2, Python 3, and the receiver at `~/.local/bin/linear-opencode-start`. This file can be symlinked from these dotfiles:

```sh
mkdir -p ~/.local/bin
chmod +x ~/dotfiles/.local/bin/linear-opencode-start
ln -s ~/dotfiles/.local/bin/linear-opencode-start ~/.local/bin/linear-opencode-start
```

Do not replace an existing file blindly. The client command supplies a PATH that includes the usual OpenCode and Homebrew installation directories, so it does not depend on an interactive shell.

## Client setup

On the client Mac, copy the launcher from this server:

```sh
mkdir -p ~/.local/bin ~/.linear
scp mac:dotfiles/.local/bin/linear-opencode ~/.local/bin/linear-opencode
chmod +x ~/.local/bin/linear-opencode
```

SSH must work without authentication or host-key prompts. Test it from the client:

```sh
ssh -T -o BatchMode=yes -o ConnectTimeout=10 mac 'printf "connected\n"'
```

If it fails, establish and authenticate `ssh mac` in a terminal and configure noninteractive access before trying Linear. Do not disable host-key verification or embed passwords in the launcher.

Create `~/.linear/coding-tools.json` with the following contents. Replace `/Users/YOUR_CLIENT_USER` with the client's actual home directory. `/bin/bash` is Linear's executable; the launcher calls `ssh` by name.

```json
{
  "openIssue": {
    "path": "/bin/bash",
    "args": [
      "/Users/YOUR_CLIENT_USER/.local/bin/linear-opencode",
      "--host", "mac",
      "--repo", "~/dev/pulse"
    ],
    "env": ["LINEAR_PROMPT", "LINEAR_ISSUE_IDENTIFIER"]
  }
}
```

Enable **Custom script** in **Settings → Code & reviews → Configure coding tools**. No terminal or browser needs to open when you trigger it. If Linear creates a starter config, preserve the launcher settings above.

## Repository and workspace behavior

Change `--repo` in the client JSON to select a different existing checkout on the server. `~` is resolved on the server. The client's `LINEAR_WORK_DIR` and Linear's suggested branch name are intentionally ignored.

The original issue prompt is preserved. A final user instruction overrides Linear-generated workspace setup: work in the existing checkout on its current branch, without creating or switching branches or creating worktrees. This is a prompt instruction, not a Git permission sandbox.

Every click creates a fresh session. Avoid simultaneous editing tasks in the same checkout. If submission fails or the connection drops before acknowledgement, check OpenCode web before retrying to avoid starting duplicate work.

## Model, effort, and session title

Each session uses `openai/gpt-6.1-sol` at `max` effort by default. The defaults are `model` and `effort` in the launcher; change them on the server in `~/dotfiles/.local/bin/linear-opencode`, then copy it to the client as in Client setup. To change one setup only, add `--model` and `--effort` to the client JSON `args`. Effort is passed to OpenCode as the model variant. `--model` must be `provider/model`.

The session title is `ISSUE-ID - ticket title`, such as `WEB-1032 - Tool suggestion using jev`. The ticket title comes from the `<title>` in the Linear prompt. If the prompt has no title, the session is named by the issue ID alone.

## Check without starting coding

From the client:

```sh
LINEAR_PROMPT='Preview only' LINEAR_ISSUE_IDENTIFIER=PULSE-123 \
  ~/.local/bin/linear-opencode --dry-run
```

This connects over SSH and prints the intended request, including the session title, model, effort, and workspace override, without creating a session or calling a model. Normal submission results and errors are recorded in `~/Library/Logs/linear-opencode.log` on the client. Dry-run output is not logged.

Tests use fake SSH and OpenCode executables and do not launch real coding tasks:

```sh
python3 -m unittest discover -s docs/tests -v
```

References: [Linear custom scripts](https://linear.app/docs/open-issues-with-custom-scripts?noRedirect=1), [OpenCode V2 CLI](https://opencode.ai/v2/docs/cli), [OpenCode V2 API](https://opencode.ai/v2/docs/api).
