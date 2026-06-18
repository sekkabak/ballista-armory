#!/usr/bin/env python3
"""Aggregate every packages/**/package.yaml + bundles/*.yaml into index.json.

Run from the repo root:  python3 scripts/build-index.py
The manager only ever reads index.json, so this is the single source of truth
the client downloads (a few KB) instead of cloning the whole armory.
"""
import json, sys, datetime, pathlib

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required: pip install pyyaml")

ROOT = pathlib.Path(__file__).resolve().parent.parent


def load_yaml(p):
    with open(p, "r", encoding="utf-8") as fh:
        return yaml.safe_load(fh) or {}


def main():
    cfg = load_yaml(ROOT / "armory.yaml")

    tools = []
    for mf in sorted((ROOT / "packages").rglob("package.yaml")):
        data = load_yaml(mf)
        name = data.get("name")
        if not name:
            print(f"  ! skipping {mf} (no name)", file=sys.stderr)
            continue
        tools.append({
            "name": name,
            "category": data.get("category", "misc"),
            "version": data.get("version", ""),
            "description": data.get("description", ""),
            "tags": data.get("tags", []),
            "homepage": data.get("homepage", ""),
            "size_note": data.get("size_note", ""),
            "files": data.get("files", []),
            "c2": data.get("c2", {}),
            "path": str(mf.parent.relative_to(ROOT)),
        })

    bundles = []
    bdir = ROOT / "bundles"
    if bdir.is_dir():
        for bf in sorted(bdir.glob("*.yaml")):
            b = load_yaml(bf)
            if b.get("name"):
                bundles.append({
                    "name": b["name"],
                    "description": b.get("description", ""),
                    "tools": b.get("tools", []),
                })

    names = [t["name"] for t in tools]
    dupes = {n for n in names if names.count(n) > 1}
    if dupes:
        sys.exit(f"Duplicate tool names: {', '.join(sorted(dupes))}")
    known = set(names)
    for b in bundles:
        missing = [t for t in b["tools"] if t not in known]
        if missing:
            print(f"  ! bundle {b['name']} references unknown tools: {missing}",
                  file=sys.stderr)

    index = {
        "schema": 1,
        "generated": datetime.datetime.now(datetime.timezone.utc)
                       .isoformat(timespec="seconds"),
        "owner": cfg.get("owner", ""),
        "repo": cfg.get("repo", ""),
        "branch": cfg.get("branch", "main"),
        "release_base": cfg.get("release_base", ""),
        "raw_base": cfg.get("raw_base", ""),
        "tools": sorted(tools, key=lambda t: (t["category"], t["name"])),
        "bundles": bundles,
    }

    out = ROOT / "index.json"
    out.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {out}  ({len(tools)} tools, {len(bundles)} bundles)")


if __name__ == "__main__":
    main()
