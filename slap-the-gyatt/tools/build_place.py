#!/usr/bin/env python3
"""Baut SlapTheGyatt.rbxlx aus den Skripten in src/ (ohne Rojo).

Aufruf:  python3 tools/build_place.py
"""
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "SlapTheGyatt.rbxlx"

_ref = 0


def ref():
    global _ref
    _ref += 1
    return f"RBX{_ref:08d}"


def script_item(class_name, name, path):
    source = (ROOT / path).read_text(encoding="utf-8")
    if "]]>" in source:
        raise SystemExit(f"{path} enthaelt ']]>' und kann nicht in CDATA gepackt werden")
    return (
        f'<Item class="{class_name}" referent="{ref()}"><Properties>'
        f'<string name="Name">{escape(name)}</string>'
        f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>'
        f"</Properties></Item>"
    )


def container(class_name, name, children):
    return (
        f'<Item class="{class_name}" referent="{ref()}"><Properties>'
        f'<string name="Name">{escape(name)}</string></Properties>'
        + "".join(children)
        + "</Item>"
    )


def main():
    items = [
        container("ReplicatedStorage", "ReplicatedStorage", [
            script_item("ModuleScript", "SlapConfig", "src/shared/SlapConfig.lua"),
        ]),
        container("ServerScriptService", "ServerScriptService", [
            script_item("Script", "SlapServer", "src/server/SlapServer.server.lua"),
        ]),
        container("StarterPlayer", "StarterPlayer", [
            container("StarterPlayerScripts", "StarterPlayerScripts", [
                script_item("LocalScript", "SlapClient", "src/client/SlapClient.client.lua"),
            ]),
        ]),
    ]
    xml = (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
        + "".join(items)
        + "</roblox>\n"
    )
    OUT.write_text(xml, encoding="utf-8")
    print(f"Geschrieben: {OUT}")


if __name__ == "__main__":
    main()
