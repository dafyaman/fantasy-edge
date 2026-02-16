# SLM-001 — Task Queue

Status: **CLI shim + runners working; PrintOnly passthrough fixed; preflight guards against missing Blender downloader script; repo-root npm script `slm:preflight` wired + verified; progress log normalized to UTF-8 for clean diffs; portable Blender layout notes (extracted vs direct unzip) captured in README**

## Active / Next

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

NEXT: Decide how to incorporate the **portable Blender layout compatibility fix** into the pending CI push.

Context:
- Pending commit `7334753` makes CI wrappers prefer `tools\\blender\\4.2.14\\extracted\\...\\blender.exe` first (avoids Windows `side-by-side configuration is incorrect`).
- On this workstation, the portable Blender unzip currently lives at `tools\\blender\\4.2.14\\blender-4.2.14-windows-x64\\blender.exe` (no `extracted\\` folder).
- I updated both wrappers to support **both** layouts (`extracted\\...` and direct `blender-...\\blender.exe`) and validated locally with real Blender runs.

Proof (local runs):
- `pwsh -File slm-tool/scripts/check_ps_exec_smoke.ps1` → uses `...\tools\blender\4.2.14\blender-4.2.14-windows-x64\blender.exe` and writes `slm-tool/_runs/smoke-20260215-201953/report.json`.
- `pwsh -File slm-tool/scripts/check_ps_exec_export_smoke.ps1` → exports `slm-tool/_runs/export-smoke-20260215-201959/model.dae` (2642 bytes) and reports `[check_ps_exec_export_smoke] OK`.

**UNBLOCK NEEDED (one-time OK to push):**
- `slm-workflow-only` is currently **ahead by 4 commits** awaiting push:
  - `7334753` (prefer extracted portable Blender in CI wrappers)
  - `3db862b` (support both portable Blender layouts in CI wrappers)
  - `e71c91a` (update tracking for pending wrapper push)
  - `34380f7` (document portable Blender layout in README)
- Reply **"OK push SLM wrappers"** and I will push these commits to `origin/slm-workflow-only`.

Review aids:
- Read-only summary helper: `slm-tool/scripts/review_pending_wrapper_push.ps1`
- Worktree patch (compat fix only): `progress/pending_push_blender_layout_compat_worktree.patch`

- **[DONE]** Hardened the safe push helper (`slm-tool/scripts/push_slm_workflow_only.ps1`) to refuse pushing when the working tree is dirty (unless explicitly overridden with `-AllowDirty`).

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
