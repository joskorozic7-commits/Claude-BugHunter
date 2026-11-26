#!/usr/bin/env python3
"""Baut SlapTheBlob.rbxl (Roblox-Binaerformat) aus default.project.json.

Gleiche Regeln wie tools/build_place.py (Rojo-Aufbau), aber im binaeren
Roblox-Format (Header, INST/PROP/PRNT/END-Chunks, LZ4-komprimiert wenn
das Paket "lz4" installiert ist, sonst unkomprimiert).

Aufruf:  python3 tools/build_rbxl.py
"""
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "SlapTheBlob.rbxl"

SERVICES = {"ReplicatedStorage", "ServerScriptService", "StarterPlayer", "Workspace", "Lighting"}


class Node:
    def __init__(self, cls, name, source=None):
        self.cls = cls
        self.name = name
        self.source = source
        self.children = []
        self.ref = None


def script_class(filename):
    if filename.endswith(".server.lua"):
        return "Script", filename[: -len(".server.lua")]
    if filename.endswith(".client.lua"):
        return "LocalScript", filename[: -len(".client.lua")]
    return "ModuleScript", filename[: -len(".lua")]


def from_path(path, name):
    if path.is_file():
        cls, _ = script_class(path.name)
        return Node(cls, name, path.read_text(encoding="utf-8"))
    init = None
    for candidate in ("init.server.lua", "init.client.lua", "init.lua"):
        if (path / candidate).exists():
            init = path / candidate
            break
    if init:
        cls, _ = script_class(init.name)
        node = Node(cls, name, init.read_text(encoding="utf-8"))
    else:
        node = Node("Folder", name)
    for child in sorted(path.iterdir()):
        if child == init or child.name.startswith("."):
            continue
        if child.is_dir():
            node.children.append(from_path(child, child.name))
        elif child.suffix == ".lua":
            node.children.append(from_path(child, script_class(child.name)[1]))
    return node


def from_node(name, data):
    if "$path" in data:
        return from_path(ROOT / data["$path"], name)
    node = Node(data.get("$className", name), name)
    for key, value in data.items():
        if not key.startswith("$"):
            node.children.append(from_node(key, value))
    return node


# ---------------------------------------------------------------- Kodierung
def u8(v):
    return struct.pack("<B", v)


def u32(v):
    return struct.pack("<I", v)


def string(s):
    data = s.encode("utf-8")
    return u32(len(data)) + data


def interleaved_i32(values):
    """Int32-Array: Zickzack-kodiert, big-endian, Bytes verschraenkt."""
    rotated = []
    for v in values:
        z = ((v << 1) ^ (v >> 31)) & 0xFFFFFFFF
        rotated.append(struct.pack(">I", z))
    out = bytearray()
    for byte_index in range(4):
        for item in rotated:
            out.append(item[byte_index])
    return bytes(out)


def referents(values):
    """Referenz-Array: Differenzen zum Vorgaenger, dann wie Int32-Array."""
    deltas = []
    previous = 0
    for v in values:
        deltas.append(v - previous)
        previous = v
    return interleaved_i32(deltas)


try:
    import lz4.block as _lz4  # pip install lz4 (optional, wie Roblox Studio)
except ImportError:
    _lz4 = None


def chunk(name, data, compress=True):
    assert len(name) == 4
    if compress and _lz4 is not None:
        packed = _lz4.compress(data, store_size=False)
        return name + u32(len(packed)) + u32(len(data)) + u32(0) + packed
    # Laenge 0 bei "komprimiert" = Daten liegen unkomprimiert vor
    return name + u32(0) + u32(len(data)) + u32(0) + data


def build(tree_nodes):
    # alle Instanzen sammeln (Eltern vor Kindern)
    instances = []
    parents = {}

    def walk(node, parent):
        node.ref = len(instances)
        instances.append(node)
        parents[node.ref] = parent.ref if parent else -1
        for child in node.children:
            walk(child, node)

    for node in tree_nodes:
        walk(node, None)

    classes = sorted({n.cls for n in instances})
    class_ids = {cls: i for i, cls in enumerate(classes)}
    by_class = {cls: [n for n in instances if n.cls == cls] for cls in classes}

    body = b""
    for cls in classes:
        nodes = by_class[cls]
        is_service = cls in SERVICES
        data = u32(class_ids[cls]) + string(cls) + u8(1 if is_service else 0) + u32(len(nodes)) + referents([n.ref for n in nodes])
        if is_service:
            data += bytes([1] * len(nodes))
        body += chunk(b"INST", data)

    for cls in classes:
        nodes = by_class[cls]
        data = u32(class_ids[cls]) + string("Name") + u8(0x01) + b"".join(string(n.name) for n in nodes)
        body += chunk(b"PROP", data)
        if cls in ("Script", "LocalScript", "ModuleScript"):
            data = u32(class_ids[cls]) + string("Source") + u8(0x01) + b"".join(string(n.source or "") for n in nodes)
            body += chunk(b"PROP", data)

    order = [n.ref for n in instances]
    data = u8(0) + u32(len(order)) + referents(order) + referents([parents[r] for r in order])
    body += chunk(b"PRNT", data)
    body += chunk(b"END\0", b"</roblox>", compress=False)

    header = b"<roblox!" + b"\x89\xff\x0d\x0a\x1a\x0a" + struct.pack("<H", 0) + struct.pack("<i", len(classes)) + struct.pack("<i", len(instances)) + b"\x00" * 8
    return header + body, instances


def main():
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    nodes = [from_node(k, v) for k, v in project["tree"].items() if not k.startswith("$")]
    data, instances = build(nodes)
    OUT.write_bytes(data)
    print(f"Written: {OUT} ({len(instances)} instances, {len(data)} bytes)")


if __name__ == "__main__":
    main()
