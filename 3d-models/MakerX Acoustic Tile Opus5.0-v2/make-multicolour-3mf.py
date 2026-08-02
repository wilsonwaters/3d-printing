#!/usr/bin/env python3
"""Turn a settings-baked Bambu project .3mf into a MULTI-COLOUR one.

Why this exists
---------------
make-bambu-3mf.py (in the 3d-print-designer skill) bakes print settings into a project
3mf, but the result is a single mesh printed in one filament. This tile wants four
filaments applied as elevation bands.

The mechanism used here is the documented multi-material one: ONE object containing
several <part> elements, each carrying its own `extruder` index. Bambu Studio assigns a
filament per part and inserts the tool changes itself. That is preferred over writing
Metadata/custom_gcode_per_layer.xml, whose schema is not publicly documented.

Input is N aligned meshes (band 1..N, bottom to top) whose union is the whole part; they
are emitted by the model's part="band" export, so the split is done by OpenSCAD rather
than by cutting triangles here.

Usage:
  python make-multicolour-3mf.py --base base.3mf --out multi.3mf \
      --band band1.stl "#0F1C57" navy --band band2.stl "#16ACF2" "electric blue" ...
"""
import argparse
import re
import shutil
import struct
import uuid
import zipfile

NS = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
      'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
      'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" '
      'requiredextensions="p"')


def read_stl(path):
    """Return (vertices, triangles) with vertices de-duplicated. Handles ASCII + binary."""
    with open(path, 'rb') as f:
        head = f.read(5)
        f.seek(0)
        raw = f.read()
    tris_xyz = []
    if head == b'solid' and b'facet' in raw[:2048]:
        for m in re.finditer(rb'vertex\s+(\S+)\s+(\S+)\s+(\S+)', raw):
            tris_xyz.append(tuple(float(g) for g in m.groups()))
    else:
        n = struct.unpack('<I', raw[80:84])[0]
        for i in range(n):
            off = 84 + i * 50 + 12
            for k in range(3):
                tris_xyz.append(struct.unpack('<3f', raw[off + k * 12: off + k * 12 + 12]))
    verts, index, tris = [], {}, []
    for i in range(0, len(tris_xyz), 3):
        idx = []
        for v in tris_xyz[i:i + 3]:
            key = (round(v[0], 6), round(v[1], 6), round(v[2], 6))
            j = index.get(key)
            if j is None:
                j = len(verts)
                index[key] = j
                verts.append(key)
            idx.append(j)
        if len(set(idx)) == 3:                      # drop degenerates
            tris.append(tuple(idx))
    return verts, tris


def mesh_xml(obj_id, verts, tris):
    out = [f'  <object id="{obj_id}" p:UUID="{uuid.uuid4()}" type="model">', '   <mesh>',
           '    <vertices>']
    out += [f'     <vertex x="{x:.6f}" y="{y:.6f}" z="{z:.6f}"/>' for x, y, z in verts]
    out += ['    </vertices>', '    <triangles>']
    out += [f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris]
    out += ['    </triangles>', '   </mesh>', '  </object>']
    return '\n'.join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', required=True, help='single-colour project 3mf to start from')
    ap.add_argument('--out', required=True)
    ap.add_argument('--band', nargs=3, action='append', required=True,
                    metavar=('MESH', 'HEXCOLOUR', 'NAME'))
    ap.add_argument('--name', default='MakerX diffuser quadrant')
    a = ap.parse_args()

    bands = [(m, c, n) for m, c, n in a.band]
    parent = len(bands) + 1                          # ids 1..N are the band meshes

    src = zipfile.ZipFile(a.base)
    names = src.namelist()
    data = {n: src.read(n) for n in names}
    src.close()

    # --- the band meshes, as sibling objects in the objects model file ---
    objs, stats = [], []
    for i, (mesh, _, _) in enumerate(bands, start=1):
        v, t = read_stl(mesh)
        objs.append(mesh_xml(i, v, t))
        stats.append(len(t))
        print(f'  band {i}: {len(v)} vertices, {len(t)} triangles  <- {mesh}')

    # The trailing <build/> is NOT optional. Every 3MF model part must carry a build
    # element even when it declares no items; lib3mf rejects the whole package without it
    # ("Could not read file", with no further detail). Verified by round-tripping.
    data['3D/Objects/object_1.model'] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<model unit="millimeter" xml:lang="en-US" {NS}>\n'
        ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
        ' <resources>\n' + '\n'.join(objs) + '\n </resources>\n <build/>\n</model>\n'
    ).encode('utf-8')

    # --- parent object gains one <component> per band; keep the plate transform ---
    root = data['3D/3dmodel.model'].decode('utf-8')
    keep = re.search(r'transform="([^"]*)"\s*printable="1"', root)
    build_tf = keep.group(1) if keep else '1 0 0 0 1 0 0 0 1 0 0 0'
    comps = '\n'.join(
        f'    <component p:path="/3D/Objects/object_1.model" objectid="{i}" '
        f'p:UUID="{uuid.uuid4()}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>'
        for i in range(1, len(bands) + 1))
    root = re.sub(r'<resources>.*?</resources>',
                  '<resources>\n'
                  f'  <object id="{parent}" p:UUID="{uuid.uuid4()}" type="model">\n'
                  '   <components>\n' + comps + '\n   </components>\n  </object>\n'
                  ' </resources>', root, flags=re.S)
    root = re.sub(r'<item objectid="\d+"',
                  f'<item objectid="{parent}"', root)
    data['3D/3dmodel.model'] = root.encode('utf-8')

    # --- model_settings: one <part> per band, each with its own extruder ---
    parts = []
    for i, (_, _, nm) in enumerate(bands, start=1):
        parts.append(
            f'    <part id="{i}" subtype="normal_part">\n'
            f'      <metadata key="name" value="{nm}"/>\n'
            f'      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
            f'      <metadata key="extruder" value="{i}"/>\n'
            f'      <mesh_stat face_count="{stats[i-1]}" edges_fixed="0" '
            f'degenerate_facets="0" facets_removed="0" facets_reversed="0" '
            f'backwards_edges="0"/>\n'
            f'    </part>')
    data['Metadata/model_settings.config'] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n'
        f'  <object id="{parent}">\n'
        f'    <metadata key="name" value="{a.name}"/>\n'
        '    <metadata key="extruder" value="1"/>\n'
        f'    <metadata face_count="{sum(stats)}"/>\n'
        + '\n'.join(parts) + '\n  </object>\n'
        '  <plate>\n'
        '    <metadata key="plater_id" value="1"/>\n'
        '    <metadata key="plater_name" value=""/>\n'
        '    <metadata key="locked" value="false"/>\n'
        '    <model_instance>\n'
        f'      <metadata key="object_id" value="{parent}"/>\n'
        '      <metadata key="instance_id" value="0"/>\n'
        '    </model_instance>\n  </plate>\n</config>\n').encode('utf-8')

    # --- filament colours ---
    cfg = data['Metadata/project_settings.config'].decode('utf-8')
    cols = ',\n        '.join(f'"{c}"' for _, c, _ in bands)
    if '"filament_colour"' in cfg:
        cfg = re.sub(r'"filament_colour":\s*\[[^\]]*\]',
                     '"filament_colour": [\n        ' + cols + '\n    ]', cfg, flags=re.S)
    else:
        cfg = cfg.replace('{', '{\n    "filament_colour": [\n        ' + cols + '\n    ],', 1)
    data['Metadata/project_settings.config'] = cfg.encode('utf-8')

    with zipfile.ZipFile(a.out, 'w', zipfile.ZIP_DEFLATED) as z:
        for n in names:
            z.writestr(n, data[n])
    print(f'Wrote {a.out}  ({len(bands)} filament-assigned parts, transform {build_tf})')


if __name__ == '__main__':
    main()
