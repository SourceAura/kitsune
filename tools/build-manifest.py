#!/usr/bin/env python3
"""Rebuild the RyoStore manifest for Fūin by hashing the product folder.

Usage: build-manifest.py <product-dir>

The store folder for a lockscreen is laid out as:

    lockscreens/kitsune/
        content/     the theme (Main.qml, theme.conf, fonts, ...)
        assets/      preview art (not installed)
        manifest.json
        LICENSE, PROVENANCE.txt

Installed destinations flatten content/ to the theme root and map
assets/preview.webp to preview.webp at the root; every content file is
install:true, assets are not installed. Prints the manifestSha256 the
registry row must carry.
"""
import hashlib
import json
import os
import sys

root = sys.argv[1]


def dest(rel):
    if rel.startswith("content/"):
        return rel[len("content/"):]
    if rel == "assets/preview.webp":
        return "preview.webp"
    return rel


files = []
for dirpath, dirs, names in os.walk(root):
    dirs.sort()
    for name in sorted(names):
        full = os.path.join(dirpath, name)
        rel = os.path.relpath(full, root)
        if rel == "manifest.json":
            continue
        data = open(full, "rb").read()
        files.append({
            "source": rel,
            "destination": dest(rel),
            "mode": "0644",
            "size": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
            "install": not rel.startswith("assets/"),
        })
files.sort(key=lambda f: f["source"])
manifest = {
    "schema": 1,
    "id": "kitsune",
    "category": "lockscreens",
    "version": "1.0.2",
    "destination": "qylock/themes/kitsune",
    "files": files,
}
out = json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"
open(os.path.join(root, "manifest.json"), "w").write(out)
print(hashlib.sha256(out.encode()).hexdigest())
