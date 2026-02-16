# SLM-001 — Blender Mesh Prep Pipeline (headless)

This repo contains a Blender-driven mesh prep/export pipeline at:

- `slm-tool/scripts/blender_sl_pipeline.py`

A repeatable smoke runner is provided:

- `slm-tool/scripts/run_blender_pipeline_smoke.ps1`

## Prereqs

- **Blender 4.2 LTS** (recommended). The earlier run report in this repo references **4.2.14 LTS**.

### Install Blender (Windows)

Option A — winget:

```powershell
winget install -e --id BlenderFoundation.Blender
```

Option B — download from https://www.blender.org/download/

## Run the smoke test

From the repo root:

```powershell
# if Blender is on PATH
powershell -ExecutionPolicy Bypass -File .\slm-tool\scripts\run_blender_pipeline_smoke.ps1

# or provide an explicit path
powershell -ExecutionPolicy Bypass -File .\slm-tool\scripts\run_blender_pipeline_smoke.ps1 -BlenderExe "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe"
```

### Outputs

The smoke run writes into `slm-tool/_runs/smoke-<timestamp>/`:

- `report.json` — pipeline stage timings + results
- `model.dae` — Collada export (unless you run with `-NoExport $true`)
- `model.blend` — saved blend (only if `-SaveBlend $true`)

## CI checks

GitHub Actions workflows included:

- **SLM preflight (Blender-free)** (`.github/workflows/slm_preflight.yml`)
  - Runs `slm-tool/scripts/check_preflight.ps1` (Python syntax compile + PowerShell wiring/regression).
  - Safe to run on PRs without Blender.
- **SLM export smoke (portable Blender 4.2.14 LTS)** (`.github/workflows/slm_ps_exec_export_smoke.yml`)
  - Runs `slm-tool/scripts/check_ps_exec_export_smoke.ps1` (downloads portable Blender and verifies `model.dae` export).

If you want to make the preflight check required on `main`, set the required status check name to:

- `SLM preflight (Blender-free) / preflight`

## Notes

- The default input fixture is `slm-tool/fixtures/cube.obj`.
- If Blender isn’t found, the smoke script prints the locations it checked and a winget install hint.
- **Portable Blender layout:** the CI wrappers can use either of these:
  - `tools/blender/<ver>/extracted/blender-<ver>-windows-x64/blender.exe` (preferred; avoids Windows "side-by-side configuration is incorrect" issues that can happen when running a copied `blender.exe` without adjacent DLLs)
  - `tools/blender/<ver>/blender-<ver>-windows-x64/blender.exe` (works for the current local unzip layout)
