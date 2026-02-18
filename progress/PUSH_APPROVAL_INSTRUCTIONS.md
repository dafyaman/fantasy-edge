# SLM-001 — slm-workflow-only push approval (one-time)

This repo is in a state where the `slm-workflow-only` branch is **ahead of origin by 1 commit** and is waiting on explicit human approval before pushing.

## What’s queued

- Branch: `slm-workflow-only`
- Commit(s) queued: `ca3ad15` — `SLM-001: validate CI artifacts in smoke workflows`

## Offline review artifacts

Pick whichever is easiest:

1) Patch bundle (full diff of the queued commit(s)):
- `progress/pending_push_bundle_ahead1.patch`

2) Human-readable status/review snapshot:
- `progress/pending_push_review_2026-02-18_0133.txt`

3) Machine-readable status snapshot (pins ahead/dirty-effective):
- `progress/pending_push_status_2026-02-18_0224.json`

## How to approve

Reply with exactly this line (case-sensitive):

OK to push slm-workflow-only

Then the worker will run:
- `slm-tool/scripts/push_slm_workflow_only.ps1 -ConfirmPush`

No push will be attempted without that explicit approval.
