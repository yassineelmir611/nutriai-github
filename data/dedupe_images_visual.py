import argparse
import time
from dataclasses import dataclass
from pathlib import Path


VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
FS_RETRIES = 8
FS_SLEEP_SECONDS = 0.35


try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Pillow n'est pas installé. Installe-le puis relance:\n"
        "  pip install pillow\n"
    ) from exc


def get_image_files(folder: Path) -> list[Path]:
    return sorted(
        [
            path
            for path in folder.iterdir()
            if path.is_file() and path.suffix.lower() in VALID_EXTENSIONS
        ],
        key=lambda p: p.name.casefold(),
    )


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


def dhash(path: Path, *, hash_size: int = 8) -> int:
    with Image.open(path) as img:
        img = img.convert("L").resize((hash_size + 1, hash_size))
        pixels = list(img.getdata())

    result = 0
    bit = 0
    for row in range(hash_size):
        row_start = row * (hash_size + 1)
        for col in range(hash_size):
            left = pixels[row_start + col]
            right = pixels[row_start + col + 1]
            if left > right:
                result |= 1 << bit
            bit += 1
    return result


def hamming(a: int, b: int) -> int:
    return (a ^ b).bit_count()


@dataclass(frozen=True)
class HashEntry:
    path: Path
    value: int


def iter_dish_folders(data_path: Path) -> list[Path]:
    return sorted(
        [
            p
            for p in data_path.iterdir()
            if p.is_dir() and not p.name.startswith(".") and p.name != "_duplicates"
        ],
        key=lambda p: p.name,
    )


def index_keys(hash_value: int, *, bands: int = 4) -> list[tuple[int, int]]:
    # Split 64-bit hash into N bands for candidate lookup (LSH-ish).
    band_bits = 64 // bands
    mask = (1 << band_bits) - 1
    keys: list[tuple[int, int]] = []
    for band in range(bands):
        keys.append((band, (hash_value >> (band * band_bits)) & mask))
    return keys


def dedupe_folder_visual(
    folder: Path,
    *,
    threshold: int,
    across_index: dict[tuple[int, int], list[HashEntry]] | None,
    dry_run: bool,
    delete: bool,
    duplicates_root: Path,
) -> tuple[int, int]:
    scanned = 0
    removed = 0
    local_index: dict[tuple[int, int], list[HashEntry]] = {}

    def add_entry(entry: HashEntry) -> None:
        for key in index_keys(entry.value):
            local_index.setdefault(key, []).append(entry)
            if across_index is not None:
                across_index.setdefault(key, []).append(entry)

    for file_path in get_image_files(folder):
        scanned += 1
        try:
            hv = dhash(file_path)
        except (FileNotFoundError, PermissionError, OSError, ValueError):
            continue

        candidates: list[HashEntry] = []
        for key in index_keys(hv):
            candidates.extend(local_index.get(key, []))
            if across_index is not None:
                candidates.extend(across_index.get(key, []))

        seen_paths: set[Path] = set()
        duplicate_of: Path | None = None
        for cand in candidates:
            if cand.path in seen_paths:
                continue
            seen_paths.add(cand.path)
            if hamming(hv, cand.value) <= threshold:
                duplicate_of = cand.path
                break

        if duplicate_of is None:
            add_entry(HashEntry(path=file_path, value=hv))
            continue

        if dry_run:
            print(f"[DUP~] {file_path} ~= {duplicate_of}")
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
        description="Remove visually similar duplicates using perceptual hashing (dHash)."
    )
    parser.add_argument(
        "--data-path",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "datasets" / "tunisian",
        help="Folder containing dish subfolders (default: datasets/tunisian in this repository).",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=6,
        help="Hamming distance threshold (smaller = stricter). Typical: 4-10.",
    )
    parser.add_argument(
        "--across-folders",
        action="store_true",
        help="Also remove similar duplicates across different subfolders (keeps the first seen).",
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

    duplicates_root = data_path / "_duplicates_visual"
    if not args.delete and not args.dry_run:
        duplicates_root.mkdir(parents=True, exist_ok=True)

    across_index: dict[tuple[int, int], list[HashEntry]] | None = (
        {} if args.across_folders else None
    )

    total_scanned = 0
    total_removed = 0
    for folder in iter_dish_folders(data_path):
        scanned, removed = dedupe_folder_visual(
            folder,
            threshold=args.threshold,
            across_index=across_index,
            dry_run=args.dry_run,
            delete=args.delete,
            duplicates_root=duplicates_root,
        )
        total_scanned += scanned
        total_removed += removed
        print(f"{folder.name}: scanned={scanned} similar_dups={removed}")

    action = "would remove" if args.dry_run else ("deleted" if args.delete else "moved")
    print(f"Done. scanned={total_scanned} similar_dups {action}={total_removed}")
    if (not args.delete) and (not args.dry_run):
        print(f"Moved duplicates to: {duplicates_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
