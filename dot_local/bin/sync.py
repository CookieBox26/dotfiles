#!/usr/bin/env python
import os
import shutil
import argparse
from pathlib import Path


def sync_dirs(src, dst, delete=False, dry_run=False):
    src = Path(src)
    dst = Path(dst)

    for root, _, files in os.walk(src):
        rel = Path(root).relative_to(src)
        target_dir = dst / rel
        if not dry_run:
            target_dir.mkdir(parents=True, exist_ok=True)
        for f in files:
            s = Path(root) / f
            d = target_dir / f
            need_copy = (
                not d.exists()
                or s.stat().st_mtime > d.stat().st_mtime
            )
            if need_copy:
                print(f"[COPY] {s} -> {d}")
                if not dry_run:
                    shutil.copy2(s, d)

    if delete:
        for root, _, files in os.walk(dst):
            rel = Path(root).relative_to(dst)
            src_dir = src / rel

            for f in files:
                d = Path(root) / f
                if not (src_dir / f).exists():
                    print(f"[DELETE] {d}")
                    if not dry_run:
                        d.unlink()


if __name__ == "__main__":
    p = argparse.ArgumentParser(description="Simple rsync-like directory sync")
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--delete", action="store_true",
                   help="remove files not present in src")
    p.add_argument("--apply", action="store_true",
                   help="actually perform changes (default: dry-run)")
    args = p.parse_args()

    sync_dirs(
        args.src,
        args.dst,
        delete=args.delete,
        dry_run=not args.apply,
    )
