# SLM-001 — Task Queue

Status: **source recovered (Blender pipeline script restored from git)**

## Active / Next
1. **[DONE]** Inventory the current `slm-tool/` codebase (entrypoints, CLI surface, build scripts).
2. **[DONE]** Unblock: locate the *source* for the Blender pipeline / UI (the working tree had only build artifacts).
3. **[IN PROGRESS]** Confirm how to run the restored Blender pipeline end-to-end (inputs/outputs, required Blender version, command line), and wire a repeatable smoke run (fixture + script).
   - Fixture + runner script added.
   - Improved Blender exe discovery + error diagnostics in the runner (common install paths + winget tip).
   - Fixed runner parameter defaults to avoid `Resolve-Path` at parse-time and made `-NoExport/-SaveBlend` plain booleans for reliable non-interactive invocation.
   - Fixed a PowerShell gotcha: renamed runner param from `$Input` (conflicts with the automatic `$input`) to `$InputPath` and added `-PrintOnly` to emit the exact Blender command line without requiring Blender.
   - Added Blender-free preflight check: `slm-tool/scripts/check_ps_printonly.ps1` (runs the smoke runner with `-PrintOnly` so CI/dev can validate wiring without installing Blender).
   - Added Blender-free syntax check: `slm-tool/scripts/check_py_compile.ps1` (runs `py_compile` on `blender_sl_pipeline.py` to catch syntax errors without Blender).
   - Added combined preflight runner: `slm-tool/scripts/check_preflight.ps1` (runs both checks above in one command; suitable for CI/dev).
   - Added Blender locator helper: `slm-tool/scripts/find_blender.ps1` (prints checked locations + best found exe).
   - Added quickstart doc: `slm-tool/README_PIPELINE.md` (and corrected expected output filenames to `model.dae`/`model.blend`).
   - Added CI-facing integration wrapper: `slm-tool/scripts/check_ps_exec_smoke.ps1` (calls the smoke runner and enforces a Blender path).
   - Environment check: Blender is **not** on PATH and not present in `%ProgramFiles%\Blender Foundation\`.

4. **[DONE]** Run the smoke script once on this machine (or in CI) and confirm it produces `report.json`.
   - Proof (Blender exec smoke): `pwsh -NoProfile -File slm-tool/scripts/check_ps_exec_smoke.ps1` with `BLENDER_EXE=C:\Program Files\Blender Foundation\Blender 5.0\blender.exe` → `OK: report.json written: ...\slm-tool\_runs\smoke-20260214-195619\report.json`

5. **[IN PROGRESS]** Re-run the smoke pipeline with export enabled (`-NoExport $false`) and verify it produces `model.dae` (and optionally `model.blend` when `-SaveBlend $true`).
   - Latest run with `-NoExport $false` still produced `export.collada_dae=null` in `report.json` (no `.dae` written).
   - Blender 5.0.1 appears to **not ship the Collada addon**: stdout shows `Add-on not loaded: "io_scene_dae", cause: No module named 'io_scene_dae'`.
   - Next: standardize export smoke runs on Blender **4.2.14 LTS** (which previously exported `.dae` per historical report), or vendor/install a Collada exporter for 5.x.
   - Next concrete action: run `pwsh -File tools/blender/get_blender_portable.ps1 -Version 4.2.14` then set `BLENDER_EXE` to the extracted `blender.exe` and rerun `slm-tool/scripts/run_blender_pipeline_smoke.ps1 -NoExport 0`.
   - Added helper to fetch portable Blender 4.2.x: `tools/blender/get_blender_portable.ps1` (download + unzip into `tools/blender/<version>/`).

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
