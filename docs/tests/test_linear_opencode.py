import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CLIENT = ROOT / ".local/bin/linear-opencode"
SERVER = ROOT / ".local/bin/linear-opencode-start"


class LinearOpenCodeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name).resolve()
        self.repo = self.home / "dev/pulse"
        self.repo.mkdir(parents=True)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.calls = self.home / "calls.jsonl"
        self.ssh_call = self.home / "ssh.json"
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "TEST_CALLS": str(self.calls),
            "TEST_SSH": str(self.ssh_call),
        }
        for key in ("LINEAR_PROMPT", "LINEAR_ISSUE_IDENTIFIER", "TEST_FAIL"):
            self.env.pop(key, None)

        receiver = self.home / ".local/bin/linear-opencode-start"
        receiver.parent.mkdir(parents=True)
        receiver.symlink_to(SERVER)
        self.executable(self.bin / "ssh", '''
import json, os, subprocess, sys
from pathlib import Path
prompt = sys.stdin.read()
Path(os.environ["TEST_SSH"]).write_text(json.dumps({"args": sys.argv[1:], "stdin": prompt}))
result = subprocess.run(["/bin/sh", "-c", sys.argv[-1]], input=prompt, text=True, cwd=os.environ["HOME"])
sys.exit(result.returncode)
''')
        self.executable(self.home / ".opencode/bin/opencode", '''
import json, os, sys
from pathlib import Path
path = sys.argv[3]
body = json.loads(sys.argv[5])
with Path(os.environ["TEST_CALLS"]).open("a") as file:
    file.write(json.dumps({"args": sys.argv[1:], "body": body, "directory": os.getcwd()}) + "\\n")
if os.environ.get("TEST_FAIL") == path:
    print("test API failure", file=sys.stderr)
    sys.exit(1)
if path == "/api/session":
    print(json.dumps({"data": {"id": "ses_test"}}))
else:
    print(json.dumps({"data": {"id": "msg_test", "sessionID": "ses_test", "type": "user"}}))
''')

    def executable(self, path, code):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"#!{sys.executable}\n" + code.lstrip())
        path.chmod(0o755)

    def client(self, *args, prompt="Implement the fix", issue="PULSE-123"):
        env = {**self.env, "LINEAR_PROMPT": prompt, "LINEAR_ISSUE_IDENTIFIER": issue}
        return subprocess.run(
            ["/bin/bash", str(CLIENT), *args], env=env, text=True,
            capture_output=True, timeout=10,
        )

    def server(self, prompt="Implement the fix", *args):
        return subprocess.run(
            [sys.executable, str(SERVER), *args], input=prompt, env=self.env,
            text=True, capture_output=True, timeout=10,
        )

    def requests(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def test_submission_creates_and_starts_a_normal_session(self):
        prompt = "Issue details\nLinear says: create a git worktree.\nFix café's bug.\n"
        result = self.client(prompt=prompt)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        outcome = json.loads(result.stdout)
        self.assertEqual(outcome, {"sessionID": "ses_test", "directory": str(self.repo), "submitted": True})
        create, submit = self.requests()
        self.assertEqual(create["body"], {
            "title": "PULSE-123",
            "location": {"directory": str(self.repo)},
            "model": {"id": "gpt-6.1-sol", "providerID": "openai", "variant": "max"},
        })
        self.assertEqual(create["directory"], str(self.repo))
        self.assertEqual(submit["directory"], str(self.repo))
        self.assertEqual(submit["args"][:3], ["api", "post", "/api/session/ses_test/prompt"])
        self.assertTrue(submit["body"]["resume"])
        self.assertTrue(submit["body"]["text"].startswith(prompt))
        self.assertIn("Do not create or switch branches", submit["body"]["text"])
        self.assertIn("override Linear-generated", submit["body"]["text"])
        self.assertIn(outcome["sessionID"], (self.home / "Library/Logs/linear-opencode.log").read_text())

    def test_session_title_is_ticket_and_linear_title(self):
        prompt = (
            "Work on Linear issue WEB-1032:\n\n"
            '<issue identifier="WEB-1032">\n'
            "<title>Tool suggestion using jev</title>\n"
            "<description>\nDo it.\n</description>\n</issue>\n"
        )
        result = self.client(prompt=prompt, issue="WEB-1032")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        create, _ = self.requests()
        self.assertEqual(create["body"]["title"], "WEB-1032 - Tool suggestion using jev")

    def test_model_and_effort_can_be_overridden(self):
        result = self.client("--model", "openai/gpt-6.1-sol-fast", "--effort", "high")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        create, _ = self.requests()
        self.assertEqual(create["body"]["model"], {"id": "gpt-6.1-sol-fast", "providerID": "openai", "variant": "high"})

    def test_model_must_name_a_provider_and_effort_needs_a_model(self):
        for args in [("--model", "gpt-6.1-sol"), ("--effort", "max")]:
            with self.subTest(args=args):
                result = self.server("Implement", *args)
                self.assertEqual(result.returncode, 2)
                self.assertFalse(self.calls.exists())

    def test_ssh_is_noninteractive_and_prompt_is_not_a_shell_argument(self):
        prompt = "$(touch INJECTED)\n'; touch INJECTED; #\nUnicode λ"
        result = self.client(prompt=prompt)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        call = json.loads(self.ssh_call.read_text())
        self.assertIn("-T", call["args"])
        self.assertIn("BatchMode=yes", call["args"])
        self.assertEqual(call["args"][-2], "mac")
        self.assertEqual(call["stdin"], prompt)
        self.assertNotIn(prompt, call["args"][-1])
        self.assertFalse((self.home / "INJECTED").exists())

    def test_repository_and_issue_are_safely_quoted(self):
        repo = self.home / "repo '; touch INJECTED; #"
        repo.mkdir()
        issue = "PULSE-1'; touch INJECTED; #"
        result = self.client("--repo", str(repo), "--host", "other-mac", issue=issue)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        create, submit = self.requests()
        self.assertEqual(create["body"]["location"]["directory"], str(repo))
        self.assertEqual(create["body"]["title"], issue)
        self.assertIn(json.dumps(str(repo)), submit["body"]["text"])
        self.assertEqual(json.loads(self.ssh_call.read_text())["args"][-2], "other-mac")
        self.assertFalse((self.home / "INJECTED").exists())

    def test_dry_run_never_calls_opencode_or_logs_the_prompt(self):
        result = self.client("--dry-run")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        preview = json.loads(result.stdout)
        self.assertEqual(preview["session"]["location"]["directory"], str(self.repo))
        self.assertIn("Workspace instructions from the user", preview["prompt"]["text"])
        self.assertFalse(self.calls.exists())
        self.assertFalse((self.home / "Library/Logs/linear-opencode.log").exists())

    def test_empty_prompt_fails_before_connecting(self):
        result = self.client(prompt="")
        self.assertEqual(result.returncode, 2)
        self.assertIn("LINEAR_PROMPT is empty", result.stderr)
        self.assertFalse(self.ssh_call.exists())

    def test_bad_client_options_fail_before_connecting(self):
        for args in [("--host", "-bad"), ("--host", "mac; touch INJECTED"), ("--repo",), ("--model",), ("--effort",), ("--unknown",)]:
            with self.subTest(args=args):
                result = self.client(*args)
                self.assertEqual(result.returncode, 2)
                self.assertFalse(self.ssh_call.exists())

    def test_missing_repository_never_calls_opencode(self):
        result = self.server("Implement", "--repo", "~/missing")
        self.assertEqual(result.returncode, 2)
        self.assertIn("repository directory does not exist", result.stderr)
        self.assertFalse(self.calls.exists())

    def test_relative_repository_and_whitespace_prompt_are_rejected(self):
        for prompt, args in [("Implement", ("--repo", "relative")), (" \n\t", ())]:
            with self.subTest(prompt=prompt, args=args):
                result = self.server(prompt, *args)
                self.assertEqual(result.returncode, 2)
                self.assertFalse(self.calls.exists())

    def test_creation_failure_does_not_submit_a_prompt(self):
        self.env["TEST_FAIL"] = "/api/session"
        result = self.server()
        self.assertEqual(result.returncode, 1)
        self.assertIn("test API failure", result.stderr)
        self.assertEqual(len(self.requests()), 1)

    def test_prompt_failure_reports_the_session_without_retrying(self):
        self.env["TEST_FAIL"] = "/api/session/ses_test/prompt"
        result = self.client()
        self.assertEqual(result.returncode, 1)
        self.assertIn("ses_test", result.stdout)
        self.assertIn("before retrying", result.stdout)
        self.assertEqual(len(self.requests()), 2)


if __name__ == "__main__":
    unittest.main()
