"""Trusted orchestration state machine; model outputs are untrusted proposals."""

import json
from datetime import datetime, timezone
from pathlib import Path

from .checks import run_checks, validate_checks
from .paths import no_links
from .workspace import Workspace
from .transfer import TransferFailure

SCHEMAS = {
    "researcher": {"analysis": "nonempty string explaining evidence and proposed fix"},
    "worker": {"changes": [{"path": "one exact write_files path", "content": "full UTF-8 file"}]},
    "review": {"verdict": "PASS or FAIL", "candidate_digest": "exact supplied digest"},
}


def validate_plan(plan):
    fields = {"goal", "read_files", "write_files", "checks"}
    if not isinstance(plan, dict) or set(plan) != fields:
        raise ValueError("Task fields must be goal/read_files/write_files/checks")
    if not isinstance(plan["goal"], str) or not 1 <= len(plan["goal"]) <= 8000:
        raise ValueError("Invalid goal")
    validate_checks(plan["checks"])


def ask(provider, role, payload, expected):
    result = provider.complete(role, payload | {"required_response": expected})
    if not isinstance(result, dict) or set(result) != set(expected):
        raise ValueError("Model response schema rejected")
    return result


def review(provider, role, payload):
    result = ask(provider, role, payload, SCHEMAS["review"])
    if result["verdict"] != "PASS" or result["candidate_digest"] != payload["candidate_digest"]:
        raise ValueError("Independent review rejected candidate")
    return result


def execute(plan, root, output, provider, report, apply):
    report["stage"] = "task-policy"
    validate_plan(plan)
    ws = Workspace(root, plan["read_files"], plan["write_files"])
    report["source_manifest"] = ws.manifest()
    context = {"goal": plan["goal"], "files": ws.context(), "write_files": ws.write_files}
    report["stage"] = "researcher"
    research = ask(provider, "researcher", context, SCHEMAS["researcher"])
    if not isinstance(research["analysis"], str) or not research["analysis"].strip():
        raise ValueError("Research evidence missing")
    report["roles"].append("researcher")
    report["stage"] = "worker"
    proposal = ask(provider, "worker", context | research, SCHEMAS["worker"])
    report["roles"].append("worker")
    candidate = output / "candidate"
    report["stage"] = "candidate-policy"
    ws.stage(candidate, proposal["changes"])
    digest = ws.digest(candidate)
    report.update(candidate=str(candidate), candidate_digest=digest)
    report["stage"] = "sandbox-checks"
    report["checks"] = run_checks(plan["checks"], candidate)
    if any(check["status"] != "PASS" for check in report["checks"]):
        raise ValueError("Real check failed or could not run")
    if ws.digest(candidate) != digest:
        raise ValueError("Checks modified the candidate")
    payload = context | proposal | {"candidate_digest": digest, "checks": report["checks"]}
    for role in ["verifier", "security-auditor"]:
        report["stage"] = role
        review(provider, role, payload)
        report["roles"].append(role)
        if ws.digest(candidate) != digest:
            raise ValueError("Candidate changed during review")
    ws.assert_source()
    report["status"] = "REVIEWED"
    if apply:
        report["stage"] = "apply"
        ws.backup(output / "original")
        report["backup"] = str(output / "original")
        ws.apply(candidate, digest)
        report["status"] = "DONE"
    report["stage"] = "complete"


def run(plan, root, output, provider, *, apply=False):
    """Output must be a new external directory; no overwrite/reuse of prior evidence."""
    output = Path(output).absolute()
    source = Path(root).absolute()
    no_links(output)
    no_links(source)
    output = output.resolve()
    source = source.resolve()
    if output.is_relative_to(source) or source.is_relative_to(output):
        raise ValueError("Run output must be outside source")
    output.mkdir(parents=True, exist_ok=False)
    report = {"schema_version": 1, "status": "BLOCKED", "utc": datetime.now(timezone.utc).isoformat(),
              "roles": [], "checks": [], "apply_requested": apply}
    try:
        execute(plan, source, output, provider, report, apply)
    except TransferFailure as error:
        report.update(status="BLOCKED", reason="Apply rollback incomplete; inspect original backup",
                      recovery_required=error.recovery_required)
    except (ValueError, RuntimeError, OSError, UnicodeError):
        # No model output, source content or credentials are persisted in reports.
        report["reason"] = "Policy, provider, check, source conflict or review gate rejected the run"
        report["status"] = "BLOCKED"
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report
