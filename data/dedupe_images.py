import argparse
import hashlib
import time
from pathlib import Path


VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
FS_RETRIES = 8
FS_SLEEP_SECONDS = 0.35


def get_image_files(folder: Path) -> list[Path]:
    return sorted(
        [
            path
            for path in folder.iterdir()
            if path.is_file() and path.suffix.lower() in VALID_EXTENSIONS
        ],
        key=lambda p: p.name.casefold(),
    )


def file_sha256(file_path: Path) -> str:
    hasher = hashlib.sha256()
    with file_path.open("rb") as file:
        for chunk in iter(lambda: file.read(8192), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def safe_unlink(file_path: Path) -> bool:
    for attempt in range(FS_RETRIES):
        try:
            file_path.unlink()
            return True
        except FileNotFoundError:
            return True
        except PermissionError:
            if attempt < FS_RETRIES - 1:
                time.sleep(FS_SLEEP_SECONDS)
                continue
            return False
        except OSError:
            if attempt < FS_RETRIES - 1:
                time.sleep(FS_SLEEP_SECONDS)
                continue
            return False


def safe_rename(src: Path, dst: Path) -> None:
    for attempt in range(FS_RETRIES):
        try:
            src.rename(dst)
            return
        except PermissionError:
            if attempt < FS_RETRIES - 1:
                time.sleep(FS_SLEEP_SECONDS)
                continue
            raise
        except OSError:
            if attempt < FS_RETRIES - 1:
                time.sleep(FS_SLEEP_SECONDS)
                continue
            raise


def unique_destination(dest: Path) -> Path:
    if not dest.exists():
        return dest
    stem = dest.stem
    suffix = dest.suffix
    parent = dest.parent
    for i in range(1, 10_000):
        candidate = parent / f"{stem}_{i:03d}{suffix}"
        if not candidate.exists():
            return candidate
    raise FileExistsError(f"Could not find unique destination for: {dest}")


def iter_dish_folders(data_path: Path) -> list[Path]:
    return sorted(
        [
            p
            for p in data_path.iterdir()
            if p.is_dir() and not p.name.startswith(".") and p.name != "_duplicates"
        ],
        key=lambda p: p.name,
    )


def dedupe_folder(
    folder: Path,
    *,
    global_seen: dict[str, Path] | None,
    dry_run: bool,
    delete: bool,
    duplicates_root: Path,
) -> tuple[int, int]:
    removed = 0
    scanned = 0
    local_seen: dict[str, Path] = {}

    for file_path in get_image_files(folder):
        scanned += 1
        try:
            image_hash = file_sha256(file_path)
        except (FileNotFoundError, PermissionError, OSError):
            continue

        first = local_seen.get(image_hash)
        if first is None and global_seen is not None:
            first = global_seen.get(image_hash)

        if first is None:
            local_seen[image_hash] = file_path
            if global_seen is not None:
                global_seen[image_hash] = file_path
            continue

        # Duplicate found
        if dry_run:
            print(f"[DUP] {file_path} == {first}")
            removed += 1
            continue

        if delete:
            if safe_unlink(file_path):
                removed += 1
            continue

        target_dir = duplicates_root / folder.name
        target_dir.mkdir(parents=True, exist_ok=True)
        dest = unique_destination(target_dir / file_path.name)
        safe_rename(file_path, dest)
        removed += 1

    return scanned, removed


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Remove duplicate images by exact file hash (sha256)."
    )
    parser.add_argument(
        "--data-path",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "datasets" / "tunisian",
        help="Folder containing dish subfolders (default: datasets/tunisian in this repository).",
    )
    parser.add_argument(
        "--across-folders",
        action="store_true",
        help="Also remove duplicates across different subfolders (keeps the first seen).",
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Permanently delete duplicates (default: move to _duplicates/).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print duplicates without deleting/moving.",
    )
    args = parser.parse_args()

    data_path = args.data_path.expanduser()
    if not data_path.exists():
        raise FileNotFoundError(f"Not found: {data_path}")
    if not data_path.is_dir():
        raise NotADirectoryError(f"Not a directory: {data_path}")

    duplicates_root = data_path / "_duplicates"
    if not args.delete and not args.dry_run:
        duplicates_root.mkdir(parents=True, exist_ok=True)

    global_seen: dict[str, Path] | None = {} if args.across_folders else None
    total_scanned = 0
    total_removed = 0

    for folder in iter_dish_folders(data_path):
        scanned, removed = dedupe_folder(
            folder,
            global_seen=global_seen,
            dry_run=args.dry_run,
            delete=args.delete,
            duplicates_root=duplicates_root,
        )
        total_scanned += scanned
        total_removed += removed
        print(f"{folder.name}: scanned={scanned} duplicates={removed}")

    action = "would remove" if args.dry_run else ("deleted" if args.delete else "moved")
    print(f"Done. scanned={total_scanned} duplicates {action}={total_removed}")
    if (not args.delete) and (not args.dry_run):
        print(f"Moved duplicates to: {duplicates_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
