"""Synthetic loopback provider for acceptance only; never a real model claim."""

import json
import os
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Fixture:
    def __init__(self, mode="success"):
        self.mode, self.roles = mode, []

    def __enter__(self):
        fixture = self

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                role = request["messages"][0]["content"].split()[3]
                payload = json.loads(request["messages"][1]["content"])
                fixture.roles.append(role)
                if role == "researcher":
                    result = {"analysis": "value() returns 41; acceptance requires 42"}
                elif role == "worker":
                    path = "../escape.py" if fixture.mode == "scope" else "app.py"
                    result = {"changes": [{"path": path, "content": "def value():\n    return 42\n"}]}
                else:
                    result = {"verdict": "FAIL" if fixture.mode == "review" else "PASS",
                              "candidate_digest": payload["candidate_digest"]}
                body = json.dumps({"choices": [{"message": {"content": json.dumps(result)}}]}).encode()
                self.send_response(200)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, *_):
                pass

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        return self

    def __exit__(self, *_):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()


def scenario(folder, mode="success"):
    root = folder / "source"
    root.mkdir(parents=True)
    original = "def value():\n    return 41\n"
    (root / "app.py").write_text(original, encoding="utf-8")
    (root / "test_app.py").write_text("from app import value\nassert value() == 42\n", encoding="utf-8")
    task = {"goal": "Make value() return 42", "read_files": ["app.py", "test_app.py"],
            "write_files": ["app.py"], "checks": [["python3", "-B", "test_app.py"]]}
    if mode == "check":
        task["checks"] = [["python3", "-c", "raise SystemExit(7)"]]
    task_path = folder / "task.json"
    task_path.write_text(json.dumps(task), encoding="utf-8")
    entry = Path(__file__).resolve().parents[1] / "run_orchestra.py"
    with Fixture(mode) as fixture:
        env = os.environ | {"UMAF_ENDPOINT": f"http://127.0.0.1:{fixture.server.server_port}/chat/completions",
                            "UMAF_MODEL": "synthetic-fixture", "UMAF_API_KEY": ""}
        process = subprocess.run([sys.executable, "-B", str(entry), "--root", str(root),
                                  "--task", str(task_path), "--output", str(folder / "run"), "--apply"],
                                 env=env, capture_output=True, timeout=30, check=False)
        roles = fixture.roles.copy()
    report = json.loads((folder / "run" / "report.json").read_text())
    expected = "DONE" if mode == "success" else "BLOCKED"
    if report["status"] != expected or process.returncode != (0 if mode == "success" else 2):
        raise RuntimeError("CLI acceptance failed")
    if mode != "success" and (root / "app.py").read_text() != original:
        raise RuntimeError("Rejected candidate changed source")
    if mode == "success" and roles != ["researcher", "worker", "verifier", "security-auditor"]:
        raise RuntimeError("Role sequence incorrect")
    if (folder / "escape.py").exists():
        raise RuntimeError("Scope escaped")
    return {"scenario": mode, "status": "PASS", "observed": expected,
            "roles": roles, "candidate_digest": report.get("candidate_digest")}
