# SLM-001 — Progress Log

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
