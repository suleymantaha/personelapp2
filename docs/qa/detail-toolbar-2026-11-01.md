# Activity detail toolbar adjustment — 2026-11-01

- User-approved scope: align personnel-add and team-selection actions; remove combined-output entry from activity detail, retain archive entry.
- Added optional leadingAction slot to existing ActivityAssignmentGroups header. Selection state, persistent toolbar and existing callbacks retained.
- Removed detail-only combined-route callback/button; archive merge and service logic unchanged.
- Regression: real GoRouter checks no merge action in detail, same action-row alignment at320/390logicalpixels, team-selection/cancel, archive merge-preview-back navigation and retained source assignments.
- Existing combined Excel test now enters output route independently; retains workbook identity, revalidation, repeated export and unchanged ordinary output assertions.
- RED: new router expectation failed before implementation; intermediate layout check exposed wrapping; constrained shared Row resolves it.
- Focused21tests PASS; full1013PASS/1SKIP (opt-in capture), analyze PASS, format and diff check PASS.
- Logs/source hashes: output/archive-flow-verification/detail-toolbar-*.log and detail-toolbar-snapshot.json; commands/revision/UTC/exits recorded.
- Branch codex/archive-flow-redesign; no commit/push, no new dependency, no data/service contract change.
- No new APK; existing10326 artifact predates these UI changes. Physical-device/native emulator validation NOT_RUN for this adjustment.
