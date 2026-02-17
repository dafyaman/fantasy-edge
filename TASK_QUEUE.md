# SLM-001 — Task Queue

Status: **CLI shim + runners working; PrintOnly passthrough fixed; Blender-free preflight wired in CI; Windows smoke + export-smoke workflows green on `slm-workflow-only` (latest runs succeeded)**

## Active / Next

- **[DONE]** Established a `slm-tool/fixtures/` convention with a short README (keeps future smoke/validation tests repeatable).
  - Files: `slm-tool/fixtures/README.md`, `slm-tool/fixtures/.gitkeep`
  - Commit: `4cce4bb`

- **[DONE]** Added a fixtures sanity check to the Blender-free preflight so CI/dev fails fast if required tiny fixtures go missing.
  - Files: `slm-tool/scripts/check_fixtures.ps1`, `slm-tool/scripts/check_preflight.ps1`
  - Proof: `pwsh -File slm-tool/scripts/check_preflight.ps1` includes `[check_fixtures] OK: cube.obj bytes=323`

- **[DONE]** Added a repo-root `slm.cmd` wrapper so you can run `slm ...` from `cmd.exe` without a long path.
  - File: `slm.cmd`
  - Proof: `cmd /c "cd /d C:\Users\newor\.openclaw\workspace && slm.cmd smoke-summary-schema"` → prints `...\\slm-tool\\scripts\\smoke_summary.schema.json`.

- **[DONE]** Added a Windows `cmd.exe` convenience wrapper so `slm` commands can be run without typing `pwsh -File ...`.
  - File: `slm-tool/scripts/slm.cmd`
  - Proof: `cmd /c slm-tool\scripts\slm.cmd smoke-summary-schema` → prints full path to `smoke_summary.schema.json`.

- **[DONE]** Committed the Windows `cmd.exe` wrapper + smoke-summary schema discovery plumbing (and updated tracking docs).
  - Commit: `e63077d`
  - Proof: `cmd /c slm-tool\scripts\slm.cmd smoke-summary-schema` → prints `...\slm-tool\scripts\smoke_summary.schema.json`.

- **[DONE]** Committed the repo-root npm scripts for smoke-summary (`package.json`) + tracking doc updates.
  - Commit: `1a3dac0`
  - Proof: `git show --name-only --oneline 1a3dac0` → lists `package.json`, `TASK_QUEUE.md`, `progress/PROGRESS_LOG.md`.

- **NEXT (needs one-time approval)** Reply **"OK to push slm-workflow-only"** and I’ll push `slm-workflow-only` to `origin` (now 5 commits): `c865828` + `4cce4bb` + `1a3dac0` + `0bf5833` + `e63077d`.
  - After approval I’ll re-check: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/pending_push_status.ps1` (must show `dirty_effective=false`) then run the safe push helper.

- **[DONE]** Re-ran Blender-free preflight locally to confirm wiring still passes: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\\slm-tool\\scripts\\check_preflight.ps1` → `[check_preflight] OK`. 

- **[DONE]** Added `slm-tool/scripts/run_smoke_summary.ps1` helper that runs the smoke pipeline in `-SummaryOnly` mode and validates the JSON schema (stable keys for downstream tooling).

- **[DONE]** Wired `run_smoke_summary.ps1` into the CLI shim (`slm-tool/scripts/slm.ps1`) as `slm smoke-summary` and added repo-root npm scripts (`slm:smoke-summary`, `slm:smoke-summary-schema`).

- **[DONE]** Added a short note to `slm-tool/README_PIPELINE.md` documenting `slm smoke-summary` + `npm run -s slm:smoke-summary` and what it outputs (single JSON line).

- **[DONE]** Fixed `slm smoke-summary` so it emits the JSON summary on stdout (capturable by `run_smoke_summary.ps1`) and no longer fails with `Smoke summary produced no output.`
  - Proof: `pwsh -File slm-tool/scripts/slm.ps1 smoke-summary` now prints a single JSON line.

- **[DONE]** Captured the `smoke-summary` JSON line into `progress/smoke_summary_<timestamp>.json` as a real sample artifact for downstream tooling.
  - Sample: `progress/smoke_summary_2026-02-16_134948.json`

- **[DONE]** Added an `-OutPath` option to `slm-tool/scripts/run_smoke_summary.ps1` (and CLI shim) so CI and devs can save the JSON artifact deterministically.
  - Proof: `pwsh -File slm-tool/scripts/slm.ps1 smoke-summary -OutPath .\\progress\\smoke_summary_latest.json` writes the file.

- **[DONE]** Wired `-OutPath` into CI to write a deterministic artifact path (`progress/smoke_summary_ci.json`) and upload it as an Actions artifact (ps-exec-smoke workflow).

- **[DONE]** Mirrored the same smoke-summary artifact step in `SLM ps-exec-export-smoke` so export runs also publish the JSON summary.

- **[DONE]** Committed the smoke-summary CI artifact upload steps + `slm smoke-summary` CLI wiring on `slm-workflow-only` (commit `2ceb819`).

- **NEXT** If you want this live in GitHub Actions: reply with **"OK to push 2ceb819"** and I’ll push `slm-workflow-only` to `origin`.

- **[DONE]** Ensured the PowerShell CLI shim supports `help` and `/?` so usage is self-discoverable (this had regressed briefly).
  - File: `slm-tool/scripts/slm.ps1`
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/slm.ps1 help` → prints `Usage:` + `Commands:`.

- **[DONE]** Mirrored `help` behavior into the `cmd.exe` wrappers (`slm.cmd` + `slm-tool/scripts/slm.cmd`) so `slm help` works in cmd without knowing PowerShell.
  - Proof: `cmd /c "cd /d C:\\Users\\newor\\.openclaw\\workspace && slm.cmd help"` prints `Usage:` + `Commands:`.

- **[DONE]** Verified the repo-root cmd wrapper prints help via `/?` (so `cmd.exe` users can discover commands without knowing `help`).
  - Proof: `cmd /c "cd /d C:\\Users\\newor\\.openclaw\\workspace && slm.cmd /?"` prints `Usage:` + `Commands:`.

- **[DONE]** Added a small `slm fixtures` discovery command (prints fixtures dir + lists available tiny inputs) so downstream tooling/scripts don’t need to hardcode paths.
  - File: `slm-tool/scripts/slm.ps1`
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/slm.ps1 fixtures` → prints `...\slm-tool\fixtures` + `.gitkeep`, `cube.obj`, `README.md`.

- **[DONE]** Added a repo-root npm script `slm:fixtures` (thin wrapper over `slm fixtures`) for consistency with the other `slm:*` scripts.
  - File: `package.json`
  - Proof: `npm run -s slm:fixtures` prints the fixtures directory and lists `.gitkeep`, `cube.obj`, `README.md`.

- **[DONE]** Committed the `slm:fixtures` npm script + `slm fixtures` CLI additions so they’re versioned alongside the other `slm:*` scripts.
  - Files: `package.json`, `slm-tool/scripts/slm.ps1` (plus tracking docs)
  - Proof: `git show -1 --name-only --oneline` (see progress log entry for commit id)

- **[DONE]** Added `slm validate-obj` command (Blender-free) that checks an OBJ contains at least one vertex + face (fast sanity for fixtures/downstream tooling).
  - Files: `slm-tool/scripts/validate_obj.ps1`, `slm-tool/scripts/slm.ps1`
  - Proof: `pwsh -NoProfile -File slm-tool/scripts/slm.ps1 validate-obj -InputPath .\slm-tool\fixtures\cube.obj` → `[validate_obj] OK: ... bytes=323 hasVertex=True hasFace=True`

- **[DONE]** Wired `slm validate-obj` into `check_preflight.ps1` (validates `slm-tool/fixtures/cube.obj` by default) so CI/dev logs include a Blender-free OBJ sanity check.

- **[DONE]** Committed `slm validate-obj` + preflight wiring on `slm-workflow-only` so CI/dev logs include an explicit `[validate_obj]` line.
  - Commit: `7460be7`

- **NEXT** If you want this on GitHub: reply **"OK to push slm-workflow-only"** and I’ll push the branch to `origin` (now includes commit `7460be7`).

- **[DONE]** Verified the nested wrapper also supports `/?` (cmd.exe discoverability).
  - Proof (command): `cmd /c "cd /d C:\\Users\\newor\\.openclaw\\workspace && slm-tool\\scripts\\slm.cmd /?"`
  - Proof (output excerpt): prints `Usage:` and `Commands:`.

- **[DONE]** Added `/?` support to the **PowerShell** CLI shim too, so `pwsh ... slm.ps1 /?` prints help (matches cmd.exe convention).
  - File: `slm-tool/scripts/slm.ps1`
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/slm.ps1 /?` → prints `Usage:` + `Commands:`.

- **[DONE]** Added a JSON Schema file for the `slm smoke-summary` output so downstream tooling has an explicit contract.
  - File: `slm-tool/scripts/smoke_summary.schema.json`

- **[DONE]** Added a `-Schema` mode so consumers can discover the schema path programmatically (does not require Blender).
  - Proof: `pwsh -File slm-tool/scripts/slm.ps1 smoke-summary -Schema` prints the full path to `smoke_summary.schema.json`.

- **[DONE]** Exposed schema discovery as a separate CLI command: `slm smoke-summary-schema` (alias for `slm smoke-summary -Schema`).

- **[DONE]** Added a lightweight GitHub Actions job that runs `slm-tool/scripts/check_preflight.ps1` (Blender-free) on PRs, in addition to the export-smoke job.
- **[DONE]** Wired repo-root `package.json` script `slm:preflight` to run the Blender-free preflight checks locally/CI via a single command (`npm run slm:preflight`).
- **[DONE]** Documented the CI check names + how to mark the preflight check as required (see `slm-tool/README_PIPELINE.md`).
- **[DONE]** Documented the **portable Blender layout options** (extracted vs direct unzip) and why CI prefers the extracted exe (see `slm-tool/README_PIPELINE.md`).

- **[DONE]** Hardened `.github/workflows/slm_preflight.yml` to invoke preflight via `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ...` for consistent CI behavior.

- **[DONE]** Added `.gitignore` rules to keep the repo lean by ignoring `slm-tool/slm-tool-app/` build artifacts and large portable Blender extracts/binaries.

- **[DONE]** Pushed `slm-workflow-only` to GitHub (now includes the Blender-free preflight workflow).

- **[DONE]** Added repo-root npm scripts for the Blender-backed runners (`slm:smoke`, `slm:export-smoke`) that dispatch to `slm-tool/scripts/slm.ps1`.

- **[DONE]** Ran `npm run slm:export-smoke` (pinned portable Blender 4.2.14) and confirmed it produces `model.dae` + `report.json` under `slm-tool/_runs/`.
- **[DONE]** Fixed portable Blender downloader to use `download.blender.org` directly + added a small-zip sanity check (prevents CI from downloading an empty/invalid zip and failing extraction).

- **[DONE]** Guarded the `Build slm-tool-app.exe` step in the **ps-exec-smoke** workflow behind a `hashFiles('.../Cargo.toml')` presence check (prevents failures when `slm-tool-app/src-tauri` sources are absent).

- **[DONE]** Pushed the committed workflow-guard fix (`1a44ecd`) to `origin/slm-workflow-only`.
  - Proof: `git push origin slm-workflow-only` → `380f5b1..1a44ecd  slm-workflow-only -> slm-workflow-only`

NEXT: (superseded; queued count is now 9 — see next item)

- **[DONE]** Worker hygiene: added a UTF-8 artifact writer for pending-push reviews (avoids UTF-16/NUL-separated text).
  - Script: `slm-tool/scripts/write_pending_push_review.ps1`
  - Latest artifact: `progress/pending_push_review_2026-02-16_1030.txt`

- **[DONE]** Added a **machine-readable** pending-push summary helper (single-line JSON) to make "OK to push" reviews easier.
  - Script: `slm-tool/scripts/pending_push_status.ps1`
  - Commit: `13fb990`

NEXT: (after approval) push the queued `slm-workflow-only` commits so CI picks up the portable Blender layout compatibility fix.

(Internal note: `progress/PROGRESS_LOG.md` had embedded NUL bytes again; added `progress/fix_progress_log_encoding.ps1` to strip/normalize when it happens — now committed locally on `slm-workflow-only`.)

Context:
- Pending commit `7334753` makes CI wrappers prefer `tools\\blender\\4.2.14\\extracted\\...\\blender.exe` first (avoids Windows `side-by-side configuration is incorrect`).
- On this workstation, the portable Blender unzip currently lives at `tools\\blender\\4.2.14\\blender-4.2.14-windows-x64\\blender.exe` (no `extracted\\` folder).
- I updated both wrappers to support **both** layouts (`extracted\\...` and direct `blender-...\\blender.exe`) and validated locally with real Blender runs.

Proof (local runs):
- `pwsh -File slm-tool/scripts/check_ps_exec_smoke.ps1` → uses `...\tools\blender\4.2.14\blender-4.2.14-windows-x64\blender.exe` and writes `slm-tool/_runs/smoke-20260215-201953/report.json`.
- `pwsh -File slm-tool/scripts/check_ps_exec_export_smoke.ps1` → exports `slm-tool/_runs/export-smoke-20260215-201959/model.dae` (2642 bytes) and reports `[check_ps_exec_export_smoke] OK`.

**UNBLOCK NEEDED (one-time OK to push):**
- `slm-workflow-only` is currently **ahead of origin** awaiting push (working tree should be **CLEAN** before pushing). Current queued commits (ahead **12**):
  - `1428ed9` (add pending-push file list helper)
  - `13fb990` (add pending-push JSON status helper)
  - `0a471f0` (commit pending-push review helpers + tracking)
  - `7334753` (prefer extracted portable Blender in CI wrappers)
  - `3db862b` (support both portable Blender layouts in CI wrappers)
  - `e71c91a` (update tracking for pending wrapper push)
  - `34380f7` (document portable Blender layout in README)
  - `116f8cf` (add pending-wrapper review helper)
  - `812ebc0` (track progress log encoding fixer + harden push helper)
  - `2da88c2` (update pending-push review + tracking logs)
  - `90d26f9` (record clean worktree + ahead7 status)
  - `305f096` (make push blocker text stable — no exact ahead count)
- (Unblocked) The queued commits have been pushed; CI is now green on `slm-workflow-only`.
- Proof of current state (most recent):
  - 2026-02-16 11:37 — `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/pending_push_status.ps1` → `{ "ahead": 12, "dirty_effective": false, "uncommitted_relevant": [] }`
    - Snapshot saved: `progress/pending_push_status_2026-02-16_113720.json`
  - 2026-02-16 11:20 — same command/output → `{ "ahead": 12, "dirty_effective": false, "uncommitted_relevant": [] }`
    - Snapshot saved: `progress/pending_push_status_2026-02-16_112028.json`
  - 2026-02-16 11:03 — same command/output → `{ "ahead": 12, "dirty_effective": false, "uncommitted_relevant": [] }`
  - 2026-02-16 10:47 — same command/output → `ahead=12`, `dirty_effective=false`, `uncommitted_relevant=[]`
  - 2026-02-16 10:30 — same command/output captured + review artifact: `progress/pending_push_review_2026-02-16_1030.txt`
- NEXT STEP: after approval, run the safe push helper (`slm-tool/scripts/push_slm_workflow_only.ps1`).

Review aids:
- Read-only summary helper: `slm-tool/scripts/review_pending_wrapper_push.ps1`
- File list (machine-readable JSON): `slm-tool/scripts/pending_push_files.ps1`
- Worktree patch (compat fix only): `progress/pending_push_blender_layout_compat_worktree.patch`
- Patch bundle (current, ahead11): `progress/pending_push_bundle_ahead11.patch`
- Patch bundle (older, ahead6): `progress/pending_push_bundle_ahead6.patch`
- Machine-readable status snapshot (local artifact): `progress/pending_push_status_2026-02-16_0835.json`
  - Note: ignored via `.git/info/exclude` pattern `progress/pending_push_status_*.json` so it won’t make `DIRTY_EFFECTIVE` true.

- **[DONE]** Hardened the safe push helper (`slm-tool/scripts/push_slm_workflow_only.ps1`) to refuse pushing when the working tree is dirty (unless explicitly overridden with `-AllowDirty`).
  - Proof: `pwsh -File slm-tool/scripts/push_slm_workflow_only.ps1` now fails with `Refusing to push: working tree is dirty...` when `git status` is not clean.

- **[DONE]** Improved the pending-push review helper to distinguish **raw dirty** vs **effective dirty** by ignoring the tracking docs (`TASK_QUEUE.md`, `progress/PROGRESS_LOG.md`).
  - File: `slm-tool/scripts/review_pending_wrapper_push.ps1`
  - Proof: running it now prints both `DIRTY_RAW=...` and `DIRTY_EFFECTIVE=...` and lists `UNCOMMITTED_RELEVANT` separately.

**[PARTIAL]** Pushed the portable Blender downloader fix to `origin/slm-workflow-only` (head=`380f5b1`).
- Proof: `git push origin slm-workflow-only` → `57d5381..380f5b1  slm-workflow-only -> slm-workflow-only`
- Note: CI is still failing because the **workflow-guard fix** is on local commit `1a44ecd` and has **not** been pushed yet.

- **[DONE]** Ran `slm-tool/scripts/check_preflight.ps1` locally (Blender-free) to validate wiring end-to-end.

- **[DONE]** Added a Blender-free regression check script: `slm-tool/scripts/check_ps_printonly_regression.ps1`.
- **[DONE]** Wired the regression check into `slm-tool/scripts/check_preflight.ps1` so `preflight` covers it automatically.
- **[DONE]** Added a preflight guard that fails fast if `tools/blender/get_blender_portable.ps1` is missing (prevents the export-smoke CI workflow from failing with a confusing missing-file error).

1. **[DONE]** Inventory the current `slm-tool/` codebase (entrypoints, CLI surface, build scripts).
2. **[DONE]** Unblock: locate the *source* for the Blender pipeline / UI (the working tree had only build artifacts).
3. **[DONE]** Confirm how to run the restored Blender pipeline end-to-end (inputs/outputs, required Blender version, command line), and wire a repeatable smoke run (fixture + script).
4. **[IN-PROGRESS]** Add a minimal, stable CLI entrypoint (PowerShell or Node) that runs `blender_sl_pipeline.py` with explicit args and emits a single machine-readable summary (paths + key metrics) for downstream tooling.
   - Fixture + runner script added.
   - Added a **general (non-smoke) runner**: `slm-tool/scripts/run_blender_pipeline.ps1` (supports `-InputPath`, `-OutDir`, `-NoExport`, `-SaveBlend`, `-SummaryOnly`).
   - Added a thin command dispatcher CLI shim: `slm-tool/scripts/slm.ps1` (subcommands: `run|smoke|export-smoke|preflight|find-blender|check-collada`).
   - Improved Blender exe discovery + error diagnostics in the runner (common install paths + winget tip).
   - Fixed runner parameter defaults to avoid `Resolve-Path` at parse-time and made `-NoExport/-SaveBlend` plain booleans for reliable non-interactive invocation.
   - Fixed a PowerShell gotcha: renamed runner param from `$Input` (conflicts with the automatic `$input`) to `$InputPath` and added `-PrintOnly` to emit the exact Blender command line without requiring Blender.
   - Added Blender-free preflight check: `slm-tool/scripts/check_ps_printonly.ps1` (runs the smoke runner with `-PrintOnly` so CI/dev can validate wiring without installing Blender).
   - Added Blender-free syntax check: `slm-tool/scripts/check_py_compile.ps1` (runs `py_compile` on `blender_sl_pipeline.py` to catch syntax errors without Blender).
   - Added combined preflight runner: `slm-tool/scripts/check_preflight.ps1` (runs both checks above in one command; suitable for CI/dev).
   - Added `-SummaryOnly` to `slm-tool/scripts/run_blender_pipeline_smoke.ps1` to emit a single JSON summary line (and suppress Blender stdout/stderr) for downstream tooling.
   - Added Blender locator helper: `slm-tool/scripts/find_blender.ps1` (prints checked locations + best found exe).
   - Added Collada presence checker: `slm-tool/scripts/check_blender_collada.ps1` (attempts to detect whether `io_scene_dae` exists in the current Blender build; useful because Blender 5.x may ship without it).
   - Added quickstart doc: `slm-tool/README_PIPELINE.md` (and corrected expected output filenames to `model.dae`/`model.blend`).
   - Added CI-facing integration wrapper: `slm-tool/scripts/check_ps_exec_smoke.ps1` (calls the smoke runner and enforces a Blender path).
   - Environment check: Blender is **not** on PATH and not present in `%ProgramFiles%\Blender Foundation\`.

4. **[DONE]** Run the smoke script once on this machine (or in CI) and confirm it produces `report.json`.
   - Proof (Blender exec smoke): `pwsh -NoProfile -File slm-tool/scripts/check_ps_exec_smoke.ps1` with `BLENDER_EXE=C:\Program Files\Blender Foundation\Blender 5.0\blender.exe` → `OK: report.json written: ...\slm-tool\_runs\smoke-20260214-195619\report.json`

5. **[DONE]** Re-run the smoke pipeline with export enabled (`-NoExport $false`) and verify it produces `model.dae` (and optionally `model.blend` when `-SaveBlend $true`).
   - Blender 5.0.1 on this host **does not ship the Collada addon**: `Add-on not loaded: "io_scene_dae", cause: No module named 'io_scene_dae'`.
   - Export smoke run **succeeds** with portable Blender **4.2.14 LTS**.
   - Proof command:
     - `$env:BLENDER_EXE='...\\tools\\blender\\4.2.14\\extracted\\blender-4.2.14-windows-x64\\blender.exe'; pwsh -File slm-tool/scripts/run_blender_pipeline_smoke.ps1 -NoExport 0 -SaveBlend 0`
   - Proof artifacts:
     - `slm-tool/_runs/smoke-20260214-213611/model.dae` (2642 bytes)
     - `slm-tool/_runs/smoke-20260214-213611/report.json` (`export.collada_dae` set)

6. **[DONE]** Make export-enabled smoke runs use Blender 4.2.14 by default.
   - Added `slm-tool/scripts/check_ps_exec_export_smoke.ps1` which enforces `tools/blender/4.2.14/blender.exe` (unless `BLENDER_EXE` is set) and runs the smoke runner with `-NoExport 0 -SaveBlend 0`.

7. **[DONE]** Add a CI workflow that runs the **export-enabled** smoke pipeline (portable Blender 4.2.14 LTS).
   - Workflow: `.github/workflows/slm_ps_exec_export_smoke.yml` (runs `slm-tool/scripts/check_ps_exec_export_smoke.ps1`).
   - Wrapper now also **asserts artifacts exist** (`model.dae` + `export.collada_dae_bytes>0`) for a clear CI pass/fail signal.

8. **[DONE]** Add `.gitignore` entries for OpenClaw/SLM generated artifacts so `git status` stays readable.
   - Ignored: `logs/`, `_runs/`, `memory/`, `slm-tool/_runs/`, `__pycache__/`, `*.pyc`, `.env.*`, `tts-*`.
   - Also ignored OpenClaw agent meta files: `AGENTS.md`, `BOOTSTRAP.md`, `HEARTBEAT.md`, `IDENTITY.md`, `SOUL.md`, `TOOLS.md`, `USER.md` (keep local).

## Inventory Notes (2026-02-14)
- `slm-tool/` top-level contains:
  - `slm-tool/slm-tool-app/dist/` (Vite-ish web assets: `index.html`, `assets/index-*.js/css`)
  - `slm-tool/slm-tool-app/src-tauri/` (generated schemas + `target/` build artifacts; **no** `src/`)
  - `slm-tool/scripts/__pycache__/blender_sl_pipeline.cpython-313.pyc` (compiled python bytecode)
  - `slm-tool/scripts/blender_sl_pipeline.py` (**restored from git history**; see progress log)
  - `slm-tool/_runs/` exists but was empty in this workspace
- There is a run report at `slm-tool/slm-tool-app/src-tauri/_runs/rel-input-smoke3/report.json` indicating a tool named `slm-blender-pipeline` ran with Blender `4.2.14 LTS` and exported Collada `.dae`.
- Repo root `package.json` scripts are for the Fantasy Edge Electron/Next app; no SLM CLI scripts are wired in yet.

## Backlog (rough)
- Define the exact mesh-prep pipeline stages (import → validate → optimize → export) and expected I/O formats.
- Add a minimal CLI command skeleton (e.g. `slm validate`, `slm pack`, `slm export`) if not present.
- Create a fixtures folder with 1–2 tiny sample meshes for repeatable tests.
- Add a smoke test (`npm test` / `node scripts/...`) to run the pipeline on fixtures.

## Done
- 2026-02-14: Created task tracking files (`TASK_QUEUE.md`, `progress/PROGRESS_LOG.md`).
- 2026-02-14: Created and pushed workflow-only branch `slm-workflow-only` (cherry-picked workflow commit `1c2b817`). PR: https://github.com/dafyaman/fantasy-edge/pull/new/slm-workflow-only
- 2026-02-14: Fixed Windows CI workflow Blender download step by adding missing wrapper script `scripts/get_blender_lts_portable.ps1` (calls `tools/blender/get_blender_portable.ps1` and ensures `tools/blender/<ver>/blender.exe`).
