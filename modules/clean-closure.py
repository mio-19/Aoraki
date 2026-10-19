#!/usr/bin/env python3
"""
clean-closure.py: Sanitizes closure-info for cross-compiled rootfs images.

When cross-compiling, build tools (such as buildPackages.qt6.qtbase or buildPackages.bash)
can inadvertently leak into the target closure via CMake configuration files,
shebangs, or cross wrapper scripts.

This script inspects the ELF architecture of all store paths in the closure.
Any store path containing an ELF binary built for a foreign architecture (e.g. host x86_64
when targeting ARM) is identified as a foreign root. Its transitive closure is pruned,
and all references from valid target paths to foreign paths are cleanly removed
from registration and store-paths.

This yields a clean target-only closure without corrupting Nix database verification.
"""

import os
import struct
import sys

def get_elf_machine(filepath):
    try:
        with open(filepath, "rb") as f:
            if f.read(4) != b"\x7fELF":
                return None
            f.seek(18)
            return struct.unpack("<H", f.read(2))[0]
    except Exception:
        return None

def check_store_path_elf(path):
    if os.path.isfile(path):
        m = get_elf_machine(path)
        if m is not None:
            return [m]
    elif os.path.isdir(path):
        machines = []
        for root, _, files in os.walk(path):
            for file in files:
                p = os.path.join(root, file)
                if not os.path.islink(p):
                    m = get_elf_machine(p)
                    if m is not None:
                        machines.append(m)
        return machines
    return []

def main():
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <rawClosureDir> <targetElfMachine> <outDir>", file=sys.stderr)
        sys.exit(1)

    raw_closure_dir = sys.argv[1]
    target_elf_machine = int(sys.argv[2])
    out_dir = sys.argv[3]

    reg_file = os.path.join(raw_closure_dir, "registration")
    with open(reg_file, "r", encoding="utf-8") as f:
        lines = [line.rstrip("\r\n") for line in f]

    entries = []
    i = 0
    while i < len(lines):
        if not lines[i]:
            i += 1
            continue
        path = lines[i]
        nar_hash = lines[i + 1]
        nar_size = int(lines[i + 2])
        deriver = lines[i + 3]
        num_refs = int(lines[i + 4])
        refs = lines[i + 5 : i + 5 + num_refs]
        entries.append({
            "path": path,
            "hash": nar_hash,
            "size": nar_size,
            "deriver": deriver,
            "refs": refs,
        })
        i = i + 5 + num_refs

    entry_map = {e["path"]: e for e in entries}

    # Identify foreign ELF roots (packages containing binaries for another architecture)
    foreign_roots = set()
    for e in entries:
        machines = check_store_path_elf(e["path"])
        if any(m != target_elf_machine for m in machines):
            foreign_roots.add(e["path"])

    # Compute transitive closure of foreign paths
    visited = set()
    stack = list(foreign_roots)
    while stack:
        cur = stack.pop()
        if cur not in visited:
            visited.add(cur)
            if cur in entry_map:
                for r in entry_map[cur]["refs"]:
                    if r not in visited:
                        stack.append(r)

    foreign_closure = visited

    # Filter target entries and clean references
    clean_entries = []
    for e in entries:
        if e["path"] in foreign_closure:
            continue
        clean_refs = [r for r in e["refs"] if r not in foreign_closure]
        clean_entries.append({
            "path": e["path"],
            "hash": e["hash"],
            "size": e["size"],
            "deriver": e["deriver"],
            "refs": clean_refs,
        })

    os.makedirs(out_dir, exist_ok=True)

    # 1. total-nar-size
    total_size = sum(e["size"] for e in clean_entries)
    with open(os.path.join(out_dir, "total-nar-size"), "w", encoding="utf-8") as f:
        f.write(f"{total_size}\n")

    # 2. store-paths
    with open(os.path.join(out_dir, "store-paths"), "w", encoding="utf-8") as f:
        for e in clean_entries:
            f.write(f"{e['path']}\n")

    # 3. registration
    with open(os.path.join(out_dir, "registration"), "w", encoding="utf-8") as f:
        for e in clean_entries:
            f.write(f"{e['path']}\n{e['hash']}\n{e['size']}\n{e['deriver']}\n{len(e['refs'])}\n")
            for r in e["refs"]:
                f.write(f"{r}\n")

    print(f"Cleaned closure: {len(entries)} -> {len(clean_entries)} paths ({len(foreign_closure)} foreign paths removed).")
    print(f"Cleaned NAR size: {total_size / (1024 * 1024):.2f} MB.")

if __name__ == "__main__":
    main()
