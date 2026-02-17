# SLM fixtures

This folder is for small, versioned test inputs used by the SLM Blender pipeline smoke tests.

Guidelines:
- Keep fixtures tiny (ideally < 1-2 MB).
- Prefer formats the pipeline already supports (e.g., .blend, .fbx, .obj, .dae) once confirmed.
- Include a short note next to each fixture describing provenance and expected behavior.

Example layout:
- minimal-cube/ - a single cube mesh with sane transforms
- bad-normals/ - intentionally broken normals to exercise validation

(Actual fixtures TBD; this file just establishes the convention.)
