#!/usr/bin/env python
import os
import shutil
import argparse
from pathlib import Path
import filecmp


def remove_empty_dirs(dst: Path, dry_run: bool, keep_names=None):
    keep_names = set(keep_names or [])
    for root, dirs, _ in os.walk(dst, topdown=False):
        root_p = Path(root)
        for dname in dirs:
            if dname in keep_names:
                continue
            d = root_p / dname
            try:
                if d.is_dir() and not any(d.iterdir()):
                    print(f"[RMDIR] {d}")
                    if not dry_run:
                        d.rmdir()
            except FileNotFoundError:
                pass


def sync_dirs(
    src,
    dst,
    mirror_mode=False,
    delete=False,
    dry_run=False,
    ignore_suffixes={'.log'},
):
    src = Path(src)
    dst = Path(dst)

    def is_ignored(p: Path) -> bool:
        return p.suffix.lower() in ignore_suffixes

    def same_content(a: Path, b: Path) -> bool:
        return filecmp.cmp(a, b, shallow=False)

    for root, _, files in os.walk(src):
        rel = Path(root).relative_to(src)
        target_dir = dst / rel
        if not dry_run:
            target_dir.mkdir(parents=True, exist_ok=True)
        for f in files:
            s = Path(root) / f
            if is_ignored(s):
                continue

            d = target_dir / f
            create = False
            overwrite = False
            if not d.exists():
                create = True
            elif same_content(s, d):
                pass
            elif mirror_mode:
                overwrite = True
            else:
                if s.stat().st_mtime > d.stat().st_mtime:
                    overwrite = True
                else:
                    print(f'[WARN] dst is newer but content differs: {s} -> {d}')

            if create or overwrite:
                label = 'CREATE' if create else 'OVERWRITE'
                print(f'[{label}] -> {d}')
                if not dry_run:
                    shutil.copy2(s, d)

    if delete:
        for root, _, files in os.walk(dst, topdown=False):
            rel = Path(root).relative_to(dst)
            src_dir = src / rel
            for f in files:
                d = Path(root) / f
                if is_ignored(d):
                    print(f'[DELETE] {d}')
                    if not dry_run:
                        d.unlink()
                    continue
                s = src_dir / f
                if not s.exists() or is_ignored(s):
                    print(f'[DELETE] {d}')
                    if not dry_run:
                        d.unlink()
        remove_empty_dirs(dst, dry_run=dry_run, keep_names={".git"})


if __name__ == "__main__":
    p = argparse.ArgumentParser(description="Simple rsync-like directory sync")
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--mirror", action="store_true")
    p.add_argument("--delete", action="store_true")
    p.add_argument("--apply", action="store_true", help="actually sync (default: dry-run)")
    args = p.parse_args()

    sync_dirs(
        args.src,
        args.dst,
        mirror_mode=args.mirror,
        delete=args.delete,
        dry_run=not args.apply,
    )
