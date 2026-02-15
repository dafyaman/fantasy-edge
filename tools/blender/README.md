# Blender (portable) for SLM-001

The SLM-001 Blender pipeline smoke runner can use either:

- `BLENDER_EXE` (env var), **or**
- a portable Blender install at: `tools/blender/<version>/blender.exe`

## Recommended version

Use **Blender 4.2 LTS** (the last known-good run report references 4.2.14 LTS).

## Expected layout

Place a portable Blender zip/extracted folder so that this path exists:

- `tools/blender/4.2.14/blender.exe`

(Version folder name can be different, but the CI wrapper currently checks `4.2.14` first.)

## Local run

In PowerShell from repo root:

```powershell
$env:BLENDER_EXE = "C:\path\to\blender.exe"
.\slm-tool\scripts\check_ps_exec_smoke.ps1
```

This should create a run folder under `slm-tool/_runs/` and write `report.json`.
