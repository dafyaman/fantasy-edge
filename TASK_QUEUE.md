# SLM-001 — Task Queue

Status: **CLI shim + runners working; PrintOnly passthrough fixed; preflight passes locally**

## Active / Next

- **[DONE]** Added a lightweight GitHub Actions job that runs `slm-tool/scripts/check_preflight.ps1` (Blender-free) on PRs, in addition to the export-smoke job.
- **[DONE]** Documented the CI check names + how to mark the preflight check as required (see `slm-tool/README_PIPELINE.md`).

- **[DONE]** Hardened `.github/workflows/slm_preflight.yml` to invoke preflight via `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ...` for consistent CI behavior.

- **[DONE]** Added `.gitignore` rules to keep the repo lean by ignoring `slm-tool/slm-tool-app/` build artifacts and large portable Blender extracts/binaries.

- **[DONE]** Pushed `slm-workflow-only` to GitHub (now includes the Blender-free preflight workflow).

NEXT: Push the CI fix commit on `slm-workflow-only` and re-check Actions runs:
- `SLM ps-exec-export-smoke` was failing because CI couldn’t find `tools/blender/get_blender_portable.ps1`.
- Fix is committed locally (`b651452`) by allowing that script through `tools/blender/.gitignore`.

BLOCKED (1 input): OK to `git push origin slm-workflow-only` from this worker? (Yes/No)

- **[DONE]** Ran `slm-tool/scripts/check_preflight.ps1` locally (Blender-free) to validate wiring end-to-end.

- **[DONE]** Added a Blender-free regression check script: `slm-tool/scripts/check_ps_printonly_regression.ps1`.
- **[DONE]** Wired the regression check into `slm-tool/scripts/check_preflight.ps1` so `preflight` covers it automatically.

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
