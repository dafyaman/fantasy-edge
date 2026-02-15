# SLM-001 — Progress Log

## 2026-02-15 12:13 America/Chicago
- Pulled the latest CI run list and confirmed `SLM ps-exec-export-smoke` is still failing **before** our downloader fix landed (run timestamp 2026-02-15T17:04Z / 11:04 local).
  - Proof: `gh run list --limit 5` shows export-smoke failure run id `22039613728`.
  - Proof: `gh run view 22039613728 --log-failed` shows `Downloaded OK (0 MB)` from a `blender.org/download/...` redirect URL.
- Updated task tracking to reflect that the next action is to re-run export-smoke after committing the downloader change to `download.blender.org`.

## 2026-02-15 11:56 America/Chicago
- Diagnosed current GitHub Actions failure for `SLM ps-exec-export-smoke`: the portable Blender download produced an **empty/invalid** zip (`Downloaded OK (0 MB)`) and extraction then failed.
  - Proof: `gh run view 22039613728 --log-failed` shows `Downloaded OK (0 MB)` then `Downloader failed with exit code 1`.
- Fixed the downloader script to avoid redirects by using `download.blender.org` directly, and added a sanity check to fail fast if the zip is unexpectedly small.
  - File: `tools/blender/get_blender_portable.ps1`
  - Proof (local run):
    - `pwsh -File tools/blender/get_blender_portable.ps1 -Version 4.2.14 -Force` → `Downloaded OK (366.6 MB)` and `FOUND_BLENDER_EXE=...\blender.exe`

## 2026-02-15 11:40 America/Chicago
- Ran the export-enabled smoke via the repo-root npm script and confirmed it produces both `model.dae` and `report.json` (portable Blender 4.2.14 LTS).
  - Command: `npm run -s slm:export-smoke`
  - Output folder: `slm-tool/_runs/export-smoke-20260215-114005/`
  - Proof artifacts:
    - `slm-tool/_runs/export-smoke-20260215-114005/model.dae` (2642 bytes)
    - `slm-tool/_runs/export-smoke-20260215-114005/report.json`

## 2026-02-15 10:35 America/Chicago
- Confirmed the `slm-workflow-only` branch is still **ahead by 3 commits** and captured fresh dry-run push proof (no external push performed).
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/review_pending_push.ps1` → `BEHIND=0 AHEAD=3`, `COMMITS_TO_PUSH: b651452, eda75f2, cbeafc8`, `DRY_RUN_PUSH: a2e0dc7..cbeafc8  slm-workflow-only -> slm-workflow-only`.

## 2026-02-15 10:50 America/Chicago
- Improved the **read-only** pending-push review helper to emit a machine-readable dirty working tree indicator (`DIRTY=...` + uncommitted count), and re-ran it to capture updated proof output.
  - File: `slm-tool/scripts/review_pending_push.ps1`
  - Proof: `pwsh -NoProfile -NonInteractive -File slm-tool/scripts/review_pending_push.ps1` → `DIRTY=True (uncommitted entries=3)` and `DRY_RUN_PUSH: a2e0dc7..cbeafc8  slm-workflow-only -> slm-workflow-only`.

## 2026-02-15 10:18 America/Chicago
- Re-ran the pending-push review for `slm-workflow-only` to confirm the CI-fix commits are still queued and capture fresh proof output (no external push performed).
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/review_pending_push.ps1` → `AHEAD=3`, `COMMITS_TO_PUSH: b651452, eda75f2, cbeafc8`, and `DRY_RUN_PUSH: a2e0dc7..cbeafc8  slm-workflow-only -> slm-workflow-only`.

## 2026-02-15 05:09 America/Chicago
- Investigated why `SLM ps-exec-export-smoke` fails on GitHub Actions and fixed the root cause locally.
  - Found failing run: `gh run view 22034211307 --log-failed` → `Expected downloader script not found: ...\tools\blender\get_blender_portable.ps1`.
  - Fix: updated `tools/blender/.gitignore` to allow tracking `get_blender_portable.ps1`, and committed it.
  - Commit: `b651452` ("Track Blender portable downloader script for CI").

## 2026-02-15 04:53 America/Chicago
- Tried to verify the GitHub PR/Actions status for the new Blender-free preflight workflow, but I can’t find a public PR for branch `slm-workflow-only` via web search.
  - Proof: `web_search` for `site:github.com dafyaman fantasy-edge slm-workflow-only pull request` returned no matching PR results.
  - Unblock needed: paste the PR URL/number (or the Actions run URL) so I can confirm `SLM preflight (Blender-free)` is passing.

## 2026-02-15 04:37 America/Chicago
- Pushed the updated `slm-workflow-only` branch to GitHub so the Blender-free preflight workflow can be verified on the PR.
  - Proof: `git push` → `4dd9c9e..a2e0dc7  slm-workflow-only -> slm-workflow-only`

## 2026-02-15 04:21 America/Chicago
- Updated tracking docs and prepared the repo to push/verify the new Blender-free CI workflow on GitHub.
  - Files: `TASK_QUEUE.md`, `progress/PROGRESS_LOG.md`
  - Proof: see the subsequent commit in `git log -1 --oneline`.

## 2026-02-15 04:06 America/Chicago
- Checked local git state for the `slm-workflow-only` branch to prep the next push/PR verification step.
  - Proof: `git status -sb` → `## slm-workflow-only...origin/slm-workflow-only [ahead 4]` and shows modified `TASK_QUEUE.md` + `progress/PROGRESS_LOG.md`.
  - Proof: `git remote -v` → `origin https://github.com/dafyaman/fantasy-edge.git`

## 2026-02-15 03:49 America/Chicago
- Committed repo-leaning ignore rules and checked-in `tools/blender/` placeholder docs so Git keeps the folder structure without tracking Blender binaries.
  - Commit: `bfe86e2` ("SLM-001: ignore Blender binaries; track tools/blender docs")
  - Files: `.gitignore`, `tools/blender/.gitignore`, `tools/blender/README.md`
  - Proof: `git show --name-only --oneline bfe86e2`

## 2026-02-15 03:33 America/Chicago
- Added `.gitignore` entries to ignore `slm-tool/slm-tool-app/` build artifacts and large portable Blender extracts/binaries (so `git status` stays readable and we don’t accidentally commit huge blobs).
  - File: `.gitignore`
  - Proof: `git diff -- .gitignore` (see diff snippet in this run)

## 2026-02-15 03:16 America/Chicago
- Committed the accumulated SLM pipeline runner + CI work to the `slm-workflow-only` branch so it’s ready to push/PR for GitHub verification.
  - Commit: `b4d8895` ("SLM-001: add Blender-free preflight + export smoke workflows")
  - Proof: `git show --name-only --oneline b4d8895` (see output below)

## 2026-02-15 02:59 America/Chicago
- Hardened the Blender-free GitHub Actions workflow invocation so it runs `check_preflight.ps1` in a clean, non-interactive PowerShell (`pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ...`).
  - File updated: `.github/workflows/slm_preflight.yml`
  - Proof snippet: `run:` now calls `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ./slm-tool/scripts/check_preflight.ps1`

## 2026-02-15 02:43 America/Chicago
- Documented GitHub Actions CI check names and the exact required-check string for branch protection.
  - File updated: `slm-tool/README_PIPELINE.md`
  - Proof snippet: the new "## CI checks" section lists workflows and the required check name `SLM preflight (Blender-free) / preflight`.

## 2026-02-15 02:27 America/Chicago
- Ran the Blender-free preflight script locally to confirm it completes cleanly (Python compile + PS PrintOnly wiring + regression).
  - Command: `pwsh -NoProfile -File slm-tool/scripts/check_preflight.ps1`
  - Proof output: ends with `[check_preflight] OK`

## 2026-02-15 02:11 America/Chicago
- Added a lightweight GitHub Actions workflow to run the Blender-free preflight checks on pushes/PRs.
  - New file: `.github/workflows/slm_preflight.yml`
  - Runs: `slm-tool/scripts/check_preflight.ps1` (Python compile + PS PrintOnly wiring/regression)
  - Proof: `.github/workflows/slm_preflight.yml` created (see file contents in this run)

## 2026-02-15 01:08 America/Chicago
- Fixed `slm-tool/scripts/slm.ps1` `-PrintOnly` passthrough so it does **not** execute Blender.
  - Root cause: array-based argument splatting to a `.ps1` script was not reliably binding the `-PrintOnly` switch.
  - Change: switched `Invoke-Runner` to **hashtable** parameter splatting for named args.
  - File: `slm-tool/scripts/slm.ps1`
  - Proof run: `pwsh -NoProfile -File slm-tool/scripts/slm.ps1 run -PrintOnly` → includes `PrintOnly enabled: not executing Blender.`

## 2026-02-15 00:10 America/Chicago
- Added a general-purpose PowerShell runner for the Blender pipeline (not the fixture-specific smoke wrapper).
  - File: `slm-tool/scripts/run_blender_pipeline.ps1`
  - Supports: `-InputPath`, `-OutDir`, `-NoExport`, `-SaveBlend`, `-PrintOnly`, `-SummaryOnly`
  - Proof snippet: see `slm-tool/scripts/run_blender_pipeline.ps1:1-20`.

## 2026-02-15 00:29 America/Chicago
- Added a minimal CLI shim/dispatcher for SLM pipeline scripts.
  - File: `slm-tool/scripts/slm.ps1`
  - Subcommands: `run`, `smoke`, `export-smoke`, `preflight`, `find-blender`, `check-collada`
  - Proof run: `pwsh -NoProfile -File .\slm-tool\scripts\slm.ps1 preflight` → `[check_preflight] OK`

## 2026-02-14 14:55 America/Chicago
- Bootstrapped project tracking: added `TASK_QUEUE.md` and `progress/PROGRESS_LOG.md`.
- WORKFLOW_ONLY_BRANCH: Created branch `slm-workflow-only` from `origin/HEAD`, cherry-picked workflow commit `1c2b817`, and pushed it to GitHub.
  - Proof: `scripts/prepare_slm_workflow_only_branch.ps1 -ConfirmCreate` → `OK=True`, `CREATED_BRANCH_AT=4dd9c9e`
  - Proof: `git push -u origin slm-workflow-only` → `* [new branch] slm-workflow-only -> slm-workflow-only`
  - PR URL: https://github.com/dafyaman/fantasy-edge/pull/new/slm-workflow-only

## 2026-02-14 18:25 America/Chicago
- Step (SLM-001): Tried to run the Blender smoke pipeline using user-provided Blender path `C:\Program Files\Blender Foundation\Blender 5.0\blender.exe`, but it does not exist on this host.
  - Proof: `if exist "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe" ...` → `BLENDER_MISSING`

## 2026-02-14 15:11 America/Chicago
- Inventory pass on `slm-tool/` completed. Findings: the folder currently contains **build artifacts** (Tauri `target/`, Vite `dist/`, `node_modules`) plus a compiled python bytecode file `scripts/__pycache__/blender_sl_pipeline.cpython-313.pyc`, but **no readable pipeline source** (`.py`/`.rs`/`.ts`) in this workspace.
  - Proof: `dir slm-tool` → shows only `scripts/`, `slm-tool-app/`, `_runs/`
  - Proof: `dir slm-tool\slm-tool-app` → `dist/`, `node_modules/`, `src-tauri/` (no `package.json`)
  - Proof: `slm-tool/slm-tool-app/src-tauri/_runs/rel-input-smoke3/report.json` indicates Blender `4.2.14 LTS` and tool name `slm-blender-pipeline` exporting a Collada `.dae`.

## 2026-02-14 15:32 America/Chicago
- Recovered the missing Blender pipeline source by restoring `slm-tool/scripts/blender_sl_pipeline.py` from git history (commit `183aa49`).
  - Proof: `git log --all -- slm-tool/scripts/blender_sl_pipeline.py` shows multiple commits including `183aa49`.
  - Proof: `git checkout 183aa49 -- slm-tool/scripts/blender_sl_pipeline.py` → file now present in working tree (12100 bytes).
  - Proof snippet (file header): `slm-tool/scripts/blender_sl_pipeline.py:1-8` includes the documented Blender headless run example.

## 2026-02-14 15:47 America/Chicago
- Added a tiny OBJ fixture and a repeatable smoke runner script for the Blender pipeline.
  - Files:
    - `slm-tool/fixtures/cube.obj`
    - `slm-tool/scripts/run_blender_pipeline_smoke.ps1`
  - Proof: `Get-Command blender` → `blender not found on PATH` (script supports `-BlenderExe` / `BLENDER_EXE`).

## 2026-02-14 16:03 America/Chicago
- Improved the smoke runner’s Blender discovery + failure diagnostics (more common install paths + prints checked locations + winget install tip).
  - File: `slm-tool/scripts/run_blender_pipeline_smoke.ps1`
  - Proof snippet: see `slm-tool/scripts/run_blender_pipeline_smoke.ps1:Resolve-BlenderExe` and the `Checked common locations` error output block.

## 2026-02-14 16:20 America/Chicago
- Hardened `run_blender_pipeline_smoke.ps1` for non-interactive execution:
  - Removed `Resolve-Path` calls from parameter defaults (those run at parse-time and can fail before the script body executes).
  - Switched `NoExport`/`SaveBlend` from `[switch]` to `[bool]` so callers can reliably pass `-NoExport $true/$false`.
  - Resolved `$Input` and `$OutDir` after validation/creation.
  - Proof snippet: `slm-tool/scripts/run_blender_pipeline_smoke.ps1:1-14` shows the new param block and comments.

## 2026-02-14 16:39 America/Chicago
- Checked for Blender on this machine; it is not currently discoverable via PATH or the default Program Files location.
  - Proof: where blender -> INFO: Could not find files for the given pattern(s).
  - Proof: dir "%ProgramFiles%\Blender Foundation\" -> NO_PROGRAMFILES_BLENDER_FOUND

## 2026-02-14 16:56 America/Chicago
- Added a minimal quickstart doc for running the Blender pipeline + smoke script, including winget install command and expected outputs.
  - File: `slm-tool/README_PIPELINE.md`
  - Proof: see snippet below.

## 2026-02-14 17:12 America/Chicago
- Added a CI-facing PowerShell wrapper script referenced by the Windows smoke workflow: `slm-tool/scripts/check_ps_exec_smoke.ps1`.
  - It enforces a Blender path (env `BLENDER_EXE` or `tools/blender/4.2.14/blender.exe`) then calls `slm-tool/scripts/run_blender_pipeline_smoke.ps1`.
  - Proof: new file created at `slm-tool/scripts/check_ps_exec_smoke.ps1`.

## 2026-02-14 17:29 America/Chicago
- Added a `tools/blender/` placeholder with `.gitignore` + README documenting the expected portable Blender layout (`tools/blender/4.2.14/blender.exe`) to match the smoke wrapper.
  - Proof: `tools/blender/README.md` and `tools/blender/.gitignore` created.

## 2026-02-14 17:46 America/Chicago
- Improved Blender smoke runner so it can be used for "command line generation" even on machines without Blender, and fixed a parameter naming bug.
  - Changes:
    - Added `-PrintOnly` (prints the Blender command and exits 0).
    - Renamed param `$Input` → `$InputPath` to avoid conflict with PowerShell's automatic `$input` variable (which caused the default input path to be empty).
  - Files: `slm-tool/scripts/run_blender_pipeline_smoke.ps1`
  - Proof: `pwsh -NoProfile -Command '& .\\slm-tool\\scripts\\run_blender_pipeline_smoke.ps1 -PrintOnly'` →
    - `Running: <BLENDER_EXE_NOT_FOUND> -b -noaudio --python ... -- --input ...\\slm-tool\\fixtures\\cube.obj ... --no-export`
    - `PrintOnly enabled: not executing Blender.`

## 2026-02-14 18:03 America/Chicago
- Added a Blender-free preflight wrapper that validates our PowerShell wiring without requiring Blender.
  - File: `slm-tool/scripts/check_ps_printonly.ps1`
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\\slm-tool\\scripts\\check_ps_printonly.ps1` →
    - `Running: <BLENDER_EXE_NOT_FOUND> -b -noaudio --python ... -- --input ...\\slm-tool\\fixtures\\cube.obj ... --no-export`
    - `[check_ps_printonly] OK`

## 2026-02-14 18:18 America/Chicago
- Added a small helper script to locate Blender on Windows and print the most likely `blender.exe` path for `-BlenderExe` / `BLENDER_EXE`.
  - File: `slm-tool/scripts/find_blender.ps1`
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\\slm-tool\\scripts\\find_blender.ps1` →
    - `NOT_FOUND`
    - `Checked:` (lists common locations + `tools/blender/4.2.14/blender.exe`)
    - `Tip: winget install -e --id BlenderFoundation.Blender`

## 2026-02-14 18:35 America/Chicago
- Added a Blender-free Python syntax check for the restored pipeline script (static compile via `py_compile`).
  - File: `slm-tool/scripts/check_py_compile.ps1`
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\\slm-tool\\scripts\\check_py_compile.ps1` → `OK`

## 2026-02-14 18:51 America/Chicago
- Verified Blender is still missing on this host by running the locator helper.
  - Proof: `pwsh -NoProfile -File slm-tool/scripts/find_blender.ps1` → `NOT_FOUND` (checked common install paths + `tools/blender/4.2.14/blender.exe`).

## 2026-02-14 19:07 America/Chicago
- Fixed slm-tool/README_PIPELINE.md to match actual pipeline default output names (model.dae / model.blend).
  - Proof: README now lists model.dae and model.blend under Outputs.

## 2026-02-14 19:23 America/Chicago
- Added a single-command preflight runner that aggregates our Blender-free checks (Python syntax compile + PowerShell PrintOnly wiring).
  - File: `slm-tool/scripts/check_preflight.ps1`
  - Proof: `pwsh -File slm-tool/scripts/check_preflight.ps1` → `[check_preflight] OK`

## 2026-02-14 19:39 America/Chicago
- Improved Blender locator helper to detect versioned install folders (wildcard search under Program Files / LocalAppData).
  - File: `slm-tool/scripts/find_blender.ps1`
  - Proof: `pwsh -NoProfile -File slm-tool/scripts/find_blender.ps1` → `FOUND=C:\Program Files\Blender Foundation\Blender 5.0\blender.exe`

## 2026-02-14 19:56 America/Chicago
- Ran the Blender pipeline smoke end-to-end on this host using Blender 5.0.1, successfully producing a run report.
  - Proof command:
    - `$env:BLENDER_EXE="C:\Program Files\Blender Foundation\Blender 5.0\blender.exe"; pwsh -NoProfile -File slm-tool/scripts/check_ps_exec_smoke.ps1`
  - Proof output:
    - `OK: report.json written: C:\Users\newor\.openclaw\workspace\slm-tool\_runs\smoke-20260214-195619\report.json`
  - Note: this run used `--no-export` (so no `.dae` expected).

## 2026-02-14 20:12 America/Chicago
- Attempted an export-enabled smoke run by setting `-NoExport $false`.
  - Proof command:
    - `$env:BLENDER_EXE='C:\Program Files\Blender Foundation\Blender 5.0\blender.exe'; & .\slm-tool\scripts\run_blender_pipeline_smoke.ps1 -NoExport $false -SaveBlend $false`
  - Proof output:
    - `OK: report.json written: C:\Users\newor\.openclaw\workspace\slm-tool\_runs\smoke-20260214-201240\report.json`
  - Result: `report.json` still shows `export.collada_dae=null` and `export.collada_dae_bytes=null` (no `.dae` emitted).
  - Next: inspect `blender_sl_pipeline.py` CLI args to determine how export is triggered and adjust the smoke runner to pass the correct export flags.

## 2026-02-14 20:28 America/Chicago
- Updated the Blender pipeline to auto-enable the Collada export addon (`io_scene_dae`) during headless runs when `bpy.ops.wm.collada_export` is missing.
  - File: `slm-tool/scripts/blender_sl_pipeline.py`
  - Proof (syntax compile): `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\\slm-tool\\scripts\\check_py_compile.ps1` → `OK`
  - Next: re-run export-enabled smoke (`-NoExport $false`) and confirm `model.dae` is produced; if still missing, capture warnings from `report.json` (expect `collada_addon_enable_failed` or `collada_export_failed: ...`).

## 2026-02-14 20:44 America/Chicago
- Improved Collada addon enablement for Blender 5.x headless export by switching to `addon_utils.enable(...)` and adding an operator `poll()` availability check before attempting export.
  - File: `slm-tool/scripts/blender_sl_pipeline.py`
  - Proof: `pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\\slm-tool\\scripts\\check_py_compile.ps1` → `[check_py_compile] OK`

## 2026-02-14 21:02 America/Chicago
- Re-ran export-enabled smoke with Blender 5.0.1; Collada addon is missing entirely in this Blender build (so `.dae` export cannot succeed as-is).
  - Proof command:
    - `$env:BLENDER_EXE='C:\Program Files\Blender Foundation\Blender 5.0\blender.exe'; pwsh -NoProfile -Command '& .\\slm-tool\\scripts\\run_blender_pipeline_smoke.ps1 -NoExport 0 -SaveBlend 0'`
  - Proof output (stdout):
    - `Add-on not loaded: "io_scene_dae", cause: No module named 'io_scene_dae'`
  - Proof artifact:
    - `slm-tool\_runs\smoke-20260214-210222\report.json` contains `"export": { "collada_dae": null, ... }`
  - Next: run export smoke against Blender 4.2.14 LTS (known-good for Collada per historical report) or vendor/install a Collada exporter for Blender 5.x.

## 2026-02-14 21:19 America/Chicago
- Added a small helper script to download + unpack a portable Blender 4.2.x zip to `tools/blender/<version>/` so we can pin Blender 4.2.14 for export smoke runs.
  - File: `tools/blender/get_blender_portable.ps1`
  - Proof (header): includes default `Version='4.2.14'` and URL template `https://www.blender.org/download/release/Blender4.2/blender-$version-$platform.zip`
  - Next: run `pwsh -File tools/blender/get_blender_portable.ps1 -Version 4.2.14`, then rerun `slm-tool/scripts/run_blender_pipeline_smoke.ps1 -NoExport 0` with `BLENDER_EXE` set to the extracted `blender.exe`.

## 2026-02-14 21:36 America/Chicago
- Ran export-enabled smoke successfully using portable Blender 4.2.14 LTS (Collada addon available there).
  - Proof command:
    - $env:BLENDER_EXE='C:\Users\newor\.openclaw\workspace\tools\blender\4.2.14\extracted\blender-4.2.14-windows-x64\blender.exe'; & .\slm-tool\scripts\run_blender_pipeline_smoke.ps1 -NoExport 0 -SaveBlend 0
  - Proof output: Collada export to: ...\\slm-tool\\_runs\\smoke-20260214-213611\\model.dae and OK: report.json written: ...\\report.json
  - Proof artifacts:
    - slm-tool/_runs/smoke-20260214-213611/model.dae (2642 bytes)
    - slm-tool/_runs/smoke-20260214-213611/report.json (export.collada_dae_bytes=2642)

## 2026-02-14 21:52 America/Chicago
- Added an export-enabled exec smoke wrapper that pins Blender 4.2.14 LTS by default.
  - File: `slm-tool/scripts/check_ps_exec_export_smoke.ps1`
  - Proof snippet: invokes `run_blender_pipeline_smoke.ps1` with `-NoExport 0 -SaveBlend 0` and defaults `BLENDER_EXE` to `tools/blender/4.2.14/blender.exe`.

## 2026-02-14 22:08 America/Chicago
- Added `.gitignore` entries to ignore OpenClaw workspace noise + SLM-generated artifacts so `git status` is usable.
  - File: `.gitignore`
  - Proof: `git diff -- .gitignore` shows new ignores for `logs/`, `_runs/`, `memory/`, `slm-tool/_runs/`, `__pycache__/`, `*.pyc`, `.env.*`, `tts-*`.

## 2026-02-14 22:24 America/Chicago
- Added a GitHub Actions workflow to run the **export-enabled** Blender pipeline smoke check on Windows runners.
  - File: `.github/workflows/slm_ps_exec_export_smoke.yml`
  - Runs: `./slm-tool/scripts/check_ps_exec_export_smoke.ps1` (which pins portable Blender 4.2.14 by default)
  - Proof: `git diff -- .github/workflows/slm_ps_exec_export_smoke.yml` (see diff snippet below).

## 2026-02-14 22:41 America/Chicago
- Fixed a CI break: the workflow referenced `./scripts/get_blender_lts_portable.ps1` but the repo only had `tools/blender/get_blender_portable.ps1`.
  - Added wrapper: `scripts/get_blender_lts_portable.ps1`
    - Calls: `tools/blender/get_blender_portable.ps1`
    - Ensures: `tools/blender/<version>/blender.exe` exists (copies it from the extracted folder)
  - Proof (no-download mode):
    - `pwsh -File scripts/get_blender_lts_portable.ps1` →
      - `Portable Blender not present at: ...\tools\blender\4.2.14\blender.exe`
      - `Re-run with -ConfirmDownload to download + extract Blender 4.2.14 (~400MB).`

## 2026-02-14 22:57 America/Chicago
- Added `.gitignore` entries to keep OpenClaw agent meta files from accidentally getting committed.
  - Files ignored: `AGENTS.md`, `BOOTSTRAP.md`, `HEARTBEAT.md`, `IDENTITY.md`, `SOUL.md`, `TOOLS.md`, `USER.md`
  - Proof: `git diff -- .gitignore` shows the new ignore block under “OpenClaw agent meta files (keep local)”. 

## 2026-02-14 23:13 America/Chicago
- Added a helper script to check whether the Blender build includes the Collada addon/module (`io_scene_dae`).
  - File: `slm-tool/scripts/check_blender_collada.ps1`
  - Proof run (Blender 5.0.1 on this host):
    - `set BLENDER_EXE=C:\Program Files\Blender Foundation\Blender 5.0\blender.exe && pwsh -File slm-tool/scripts/check_blender_collada.ps1`
    - Output includes: `[check_blender_collada] Assuming missing.`

## 2026-02-14 23:35 America/Chicago
- Tightened the export-enabled smoke wrapper so it gives a crisp pass/fail signal:
  - `slm-tool/scripts/check_ps_exec_export_smoke.ps1` now:
    - Defaults BLENDER_EXE to the **extracted** portable path (`tools/blender/4.2.14/extracted/.../blender.exe`) in addition to `tools/blender/4.2.14/blender.exe`.
    - Runs the smoke with an explicit `-OutDir slm-tool/_runs/export-smoke-<timestamp>`.
    - Asserts `model.dae` exists and `export.collada_dae_bytes > 0` in `report.json`.
  - Proof run:
    - `pwsh -NoProfile -File .\slm-tool\scripts\check_ps_exec_export_smoke.ps1`
    - Output ends with: `[check_ps_exec_export_smoke] OK: model.dae bytes=2642 at ...\slm-tool\_runs\export-smoke-20260214-233504\model.dae`

## 2026-02-14 23:53 America/Chicago
- Added a `-SummaryOnly` mode to `slm-tool/scripts/run_blender_pipeline_smoke.ps1` to emit a single machine-readable JSON summary line (and suppress Blender stdout/stderr) for downstream tooling.
  - Proof command:
    - `$env:BLENDER_EXE='C:\Users\newor\.openclaw\workspace\tools\blender\4.2.14\extracted\blender-4.2.14-windows-x64\blender.exe'; pwsh -NoProfile -File .\slm-tool\scripts\run_blender_pipeline_smoke.ps1 -NoExport:$true -SaveBlend:$false -SummaryOnly`
  - Proof output (single line):
    - `{"ok":true,"input":"C:\\Users\\newor\\.openclaw\\workspace\\slm-tool\\fixtures\\cube.obj",...,"report":"...\\report.json",...}`

## 2026-02-15 01:38 America/Chicago
- Added a Blender-free regression check to ensure `slm.ps1 run -PrintOnly` does not execute Blender and does not emit a Blender version banner.
  - File: `slm-tool/scripts/check_ps_printonly_regression.ps1`
  - Proof run: `pwsh -NoProfile -File slm-tool/scripts/check_ps_printonly_regression.ps1` → `[check_ps_printonly_regression] OK`

## 2026-02-15 01:55 America/Chicago
- Wired the new PrintOnly regression check into the combined preflight script so it runs automatically in `slm.ps1 preflight` / CI preflight contexts.
  - File updated: `slm-tool/scripts/check_preflight.ps1`
  - Proof run: `pwsh -NoProfile -File slm-tool/scripts/check_preflight.ps1` → includes `[check_ps_printonly_regression] OK` then `[check_preflight] OK`
