#!/usr/bin/env python3
"""Baut SlapTheGyatt.rbxlx aus default.project.json (ohne Rojo).

Unterstuetzt dieselben Regeln wie Rojo:
  Ordner            -> Folder (oder Skript, wenn init.*.lua darin liegt)
  init.server.lua   -> Script,  init.client.lua -> LocalScript,  init.lua -> ModuleScript
  *.server.lua      -> Script,  *.client.lua    -> LocalScript,  *.lua    -> ModuleScript

Aufruf:  python3 tools/build_place.py
"""
import json
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "SlapTheGyatt.rbxlx"
_ref = [0]


def ref():
    _ref[0] += 1
    return f"RBX{_ref[0]:08d}"


def props(name, source=None):
    xml = f'<Properties><string name="Name">{escape(name)}</string>'
    if source is not None:
        if "]]>" in source:
            raise SystemExit(f"{name}: Quelltext enthaelt ']]>'")
        xml += f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>'
    return xml + "</Properties>"


def script_class(filename):
    if filename.endswith(".server.lua"):
        return "Script", filename[: -len(".server.lua")]
    if filename.endswith(".client.lua"):
        return "LocalScript", filename[: -len(".client.lua")]
    return "ModuleScript", filename[: -len(".lua")]


def from_path(path, name):
    if path.is_file():
        cls, _ = script_class(path.name)
        return f'<Item class="{cls}" referent="{ref()}">{props(name, path.read_text(encoding="utf-8"))}</Item>'
    init = None
    for candidate in ("init.server.lua", "init.client.lua", "init.lua"):
        if (path / candidate).exists():
            init = path / candidate
            break
    children = []
    for child in sorted(path.iterdir()):
        if child == init or child.name.startswith("."):
            continue
        if child.is_dir():
            children.append(from_path(child, child.name))
        elif child.suffix == ".lua":
            children.append(from_path(child, script_class(child.name)[1]))
    if init:
        cls, _ = script_class(init.name)
        return f'<Item class="{cls}" referent="{ref()}">{props(name, init.read_text(encoding="utf-8"))}{"".join(children)}</Item>'
    return f'<Item class="Folder" referent="{ref()}">{props(name)}{"".join(children)}</Item>'


def from_node(name, node):
    if "$path" in node:
        return from_path(ROOT / node["$path"], name)
    cls = node.get("$className", name)
    children = [from_node(k, v) for k, v in node.items() if not k.startswith("$")]
    return f'<Item class="{cls}" referent="{ref()}">{props(name)}{"".join(children)}</Item>'


def main():
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    services = [from_node(k, v) for k, v in project["tree"].items() if not k.startswith("$")]
    xml = (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
        + "".join(services)
        + "</roblox>\n"
    )
    OUT.write_text(xml, encoding="utf-8")
    print(f"Geschrieben: {OUT}")


if __name__ == "__main__":
    main()
