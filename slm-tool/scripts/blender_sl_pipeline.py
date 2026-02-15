"""SLM Tool: Blender headless pipeline (skeleton)

Run example (Windows):
  blender.exe -b -noaudio --python blender_sl_pipeline.py -- \
    --input model.fbx \
    --out-dir out/model1 \
    --preset building

This file is intentionally a scaffold. It will be expanded to:
- import various formats
- normalize transforms
- generate LOD chain
- generate physics proxy
- validate + report
- export Collada (.dae) files

"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from datetime import datetime, timezone


# NOTE: bpy only exists when running under Blender.
try:
    import bpy  # type: ignore
    from mathutils import Vector  # type: ignore
except Exception:  # pragma: no cover
    bpy = None
    Vector = None  # type: ignore


@dataclass
class PipelineConfig:
    input_path: Path
    out_dir: Path
    preset: str
    lod_ratios: tuple[float, float, float, float]
    physics_mode: str
    name: str
    no_export: bool
    save_blend: bool


def parse_args(argv: list[str]) -> PipelineConfig:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--out-dir", required=True)
    p.add_argument("--preset", default="building", choices=["building", "landscape", "prop"])
    p.add_argument("--physics-mode", default="proxy", choices=["proxy", "convex_hull"])
    p.add_argument("--name", default="model", help="Base name for exported files (default: model)")
    p.add_argument("--no-export", action="store_true", help="Skip Collada export; only produce report.json")
    p.add_argument("--save-blend", action="store_true", help="Save a debug .blend file into out-dir")

    # Default LOD ratios; tune per preset later.
    p.add_argument("--lod-high", type=float, default=1.0)
    p.add_argument("--lod-med", type=float, default=0.5)
    p.add_argument("--lod-low", type=float, default=0.2)
    p.add_argument("--lod-lowest", type=float, default=0.1)

    ns = p.parse_args(argv)
    return PipelineConfig(
        input_path=Path(ns.input),
        out_dir=Path(ns.out_dir),
        preset=str(ns.preset),
        lod_ratios=(float(ns.lod_high), float(ns.lod_med), float(ns.lod_low), float(ns.lod_lowest)),
        physics_mode=str(ns.physics_mode),
        name=str(ns.name),
        no_export=bool(ns.no_export),
        save_blend=bool(ns.save_blend),
    )


def ensure_out_dir(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)


def write_report(out_dir: Path, data: dict) -> None:
    # Stable key ordering makes diffs/reviews easier.
    (out_dir / "report.json").write_text(
        json.dumps(data, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def main(argv: list[str]) -> int:
    if bpy is None:
        raise RuntimeError("This script must be run under Blender (bpy not available).")

    cfg = parse_args(argv)
    started_dt = datetime.now(timezone.utc)
    started_at = started_dt.isoformat()

    if not cfg.input_path.exists():
        raise FileNotFoundError(str(cfg.input_path))

    ensure_out_dir(cfg.out_dir)

    # Reset scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # Import asset (minimal: OBJ / FBX / GLTF / DAE)
    ext = cfg.input_path.suffix.lower()
    if ext == ".obj":
        bpy.ops.wm.obj_import(filepath=str(cfg.input_path))
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(cfg.input_path))
    elif ext in (".gltf", ".glb"):
        bpy.ops.import_scene.gltf(filepath=str(cfg.input_path))
    elif ext == ".dae":
        bpy.ops.wm.collada_import(filepath=str(cfg.input_path))
    else:
        raise ValueError(f"Unsupported input format for now: {ext}")

    # Collect mesh objects.
    # Only include objects linked into the current view layer to avoid selection/apply errors.
    view_layer = bpy.context.view_layer
    mesh_objs = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.name in view_layer.objects]
    if not mesh_objs:
        raise RuntimeError("No view-layer mesh objects found after import")

    warnings: list[str] = []

    # Basic cleanup: apply transforms + triangulate (non-destructive MVP defaults)
    # Some imported objects may not be linked to the active View Layer; select only linkable ones.
    bpy.ops.object.select_all(action="DESELECT")
    view_layer = bpy.context.view_layer
    for o in mesh_objs:
        if o.name in view_layer.objects:
            o.select_set(True)

    # Set an active object that is actually in the current view layer.
    active = next((o for o in mesh_objs if o.name in view_layer.objects), None)
    bpy.context.view_layer.objects.active = active

    try:
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    except Exception as e:
        warnings.append(f"transform_apply_failed: {e}")

    try:
        for o in mesh_objs:
            tri = o.modifiers.new(name="Triangulate", type="TRIANGULATE")
            tri.keep_custom_normals = True  # type: ignore[attr-defined]
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.modifier_apply(modifier=tri.name)
    except Exception as e:
        warnings.append(f"triangulate_failed: {e}")
    # TODO: create LOD copies + decimate modifiers
    # TODO: create physics proxy

    exported_dae = None
    exported_dae_bytes = None

    safe_name = "".join([c for c in cfg.name if c.isalnum() or c in ("-", "_", ".")]).strip() or "model"

    saved_blend = None
    if cfg.save_blend:
        blend_path = cfg.out_dir / f"{safe_name}.blend"
        try:
            bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), compress=True)
            saved_blend = str(blend_path)
        except Exception as e:
            warnings.append(f"save_blend_failed: {e}")

    if not cfg.no_export:
        # Export Collada (.dae) (baseline export; SL-specific settings will come later)
        # Ensure only mesh objects are selected for export.
        try:
            bpy.ops.object.select_all(action="DESELECT")
        except Exception:
            pass
        for o in mesh_objs:
            if o.name in bpy.context.view_layer.objects:
                o.select_set(True)

        active = next(
            (o for o in mesh_objs if o.name in bpy.context.view_layer.objects),
            None,
        )
        bpy.context.view_layer.objects.active = active

        dae_path = cfg.out_dir / f"{safe_name}.dae"

        # Blender 5.x may not have Collada export available unless the addon is enabled.
        # Attempt to enable it so export works in headless runs.
        def _collada_export_available() -> bool:
            op = getattr(bpy.ops.wm, "collada_export", None)
            if op is None:
                return False
            try:
                return bool(op.poll())
            except Exception:
                # If poll() itself errors, treat as unavailable.
                return False

        if not _collada_export_available():
            try:
                import addon_utils

                # addon_utils.enable tends to be more reliable in headless runs than
                # bpy.ops.preferences.addon_enable.
                addon_utils.enable("io_scene_dae", default_set=True, persistent=True)
            except Exception as e:
                warnings.append(f"collada_addon_enable_failed: {e}")

        if not _collada_export_available():
            warnings.append("collada_export_operator_missing")
        else:
            try:
                bpy.ops.wm.collada_export(filepath=str(dae_path))
                exported_dae = str(dae_path)
            except Exception as e:
                exported_dae = None
                warnings.append(f"collada_export_failed: {e}")

        if exported_dae and Path(exported_dae).exists():
            try:
                exported_dae_bytes = Path(exported_dae).stat().st_size
            except Exception:
                exported_dae_bytes = None

    # TODO: run validations + fill report

    # Basic stats
    total_tris = 0
    min_x = min_y = min_z = float("inf")
    max_x = max_y = max_z = float("-inf")

    meshes: list[dict] = []

    # Use object bounding boxes in world space (good enough for buildings/landscape).
    for o in mesh_objs:
        # triangle estimate
        tris = 0
        me = o.data
        if me is not None:
            for poly in me.polygons:
                n = len(poly.vertices)
                if n >= 3:
                    tris += (n - 2)
        total_tris += tris

        # bounds
        o_min_x = o_min_y = o_min_z = float("inf")
        o_max_x = o_max_y = o_max_z = float("-inf")
        mat = o.matrix_world
        for corner in o.bound_box:
            x, y, z = (mat @ Vector(corner))
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            min_z = min(min_z, z)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            max_z = max(max_z, z)

            o_min_x = min(o_min_x, x)
            o_min_y = min(o_min_y, y)
            o_min_z = min(o_min_z, z)
            o_max_x = max(o_max_x, x)
            o_max_y = max(o_max_y, y)
            o_max_z = max(o_max_z, z)

        meshes.append(
            {
                "name": o.name,
                "triangles_approx": tris,
                "bbox_world": {
                    "min": [o_min_x, o_min_y, o_min_z],
                    "max": [o_max_x, o_max_y, o_max_z],
                    "size": [o_max_x - o_min_x, o_max_y - o_min_y, o_max_z - o_min_z],
                },
            }
        )

    bbox = {
        "min": [min_x, min_y, min_z],
        "max": [max_x, max_y, max_z],
        "size": [max_x - min_x, max_y - min_y, max_z - min_z],
    }

    # Simple validation heuristics (tune later; SL specifics depend on upload settings).
    max_dim = max(bbox["size"]) if bbox["size"] else 0
    if max_dim > 64.0:
        warnings.append(f"bbox_world.max_dim_gt_64m: {max_dim:.3f}")
    if total_tris > 200_000:
        warnings.append(f"triangles_approx_gt_200k: {total_tris}")

    # Unit settings sanity (SL uses meters; unit_scale should typically be 1.0)
    try:
        us = bpy.context.scene.unit_settings
        unit_system = getattr(us, "system", None)
        unit_scale = float(getattr(us, "scale_length", 1.0))
        if unit_system and str(unit_system).upper() not in ("METRIC", "NONE"):
            warnings.append(f"scene.unit_system_unexpected: {unit_system}")
        if abs(unit_scale - 1.0) > 1e-6:
            warnings.append(f"scene.unit_scale_not_1: {unit_scale}")
    except Exception:
        pass

    status = "exported" if exported_dae else "imported"
    finished_dt = datetime.now(timezone.utc)
    finished_at = finished_dt.isoformat()
    duration_ms = int((finished_dt - started_dt).total_seconds() * 1000)

    write_report(
        cfg.out_dir,
        {
            "tool": {
                "name": "slm-blender-pipeline",
                "blender": getattr(bpy.app, "version_string", None),
            },
            "scene": {
                "unit_system": getattr(getattr(bpy.context.scene, "unit_settings", None), "system", None),
                "unit_scale": getattr(getattr(bpy.context.scene, "unit_settings", None), "scale_length", None),
            },
            "run": {
                "started_at": started_at,
                "finished_at": finished_at,
                "duration_ms": duration_ms,
            },
            "input": str(cfg.input_path),
            "input_ext": cfg.input_path.suffix.lower(),
            "name": cfg.name,
            "preset": cfg.preset,
            "lod_ratios": cfg.lod_ratios,
            "physics_mode": cfg.physics_mode,
            "no_export": cfg.no_export,
            "objects": len(mesh_objs),
            "meshes": meshes,
            "triangles_approx": total_tris,
            "bbox_world": bbox,
            "warnings": warnings,
            "export": {
                "name_sanitized": safe_name,
                "debug_blend": saved_blend,
                "collada_dae": exported_dae,
                "collada_dae_bytes": exported_dae_bytes,
            },
            "status": status,
        },
    )

    return 0


if __name__ == "__main__":
    # Blender passes args after '--'
    import sys

    if "--" in sys.argv:
        idx = sys.argv.index("--")
        args = sys.argv[idx + 1 :]
    else:
        args = []

    raise SystemExit(main(args))
