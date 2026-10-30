import argparse
import time
from pathlib import Path


VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
RENAME_RETRIES = 8
RENAME_SLEEP_SECONDS = 0.35


def get_image_files(folder: Path) -> list[Path]:
    return sorted(
        [
            path
            for path in folder.iterdir()
            if path.is_file() and path.suffix.lower() in VALID_EXTENSIONS
        ],
        key=lambda p: p.name.casefold(),
    )


def safe_rename(src: Path, dst: Path) -> None:
    for attempt in range(RENAME_RETRIES):
        try:
            src.rename(dst)
            return
        except FileNotFoundError:
            raise
        except PermissionError:
            if attempt < RENAME_RETRIES - 1:
                time.sleep(RENAME_SLEEP_SECONDS)
                continue
            raise
        except OSError:
            if attempt < RENAME_RETRIES - 1:
                time.sleep(RENAME_SLEEP_SECONDS)
                continue
            raise


def renumber_images_in_folder(
    folder: Path,
    *,
    start: int = 1,
    padding: int = 6,
    dry_run: bool = False,
) -> int:
    images = get_image_files(folder)
    if not images:
        return 0

    run_id = time.time_ns()
    staged: list[tuple[Path, str]] = []

    for idx, path in enumerate(images):
        suffix = path.suffix.lower()
        tmp = folder / f".renum_tmp_{run_id}_{idx:06d}{suffix}"
        if dry_run:
            staged.append((tmp, suffix))
            continue
        safe_rename(path, tmp)
        staged.append((tmp, suffix))

    for i, (tmp, suffix) in enumerate(staged, start=start):
        dest = folder / f"{i:0{padding}d}{suffix}"
        if dest.exists():
            raise FileExistsError(f"Destination already exists: {dest}")
        if dry_run:
            continue
        safe_rename(tmp, dest)

    return len(staged)


def iter_target_folders(data_path: Path) -> list[Path]:
    return sorted([p for p in data_path.iterdir() if p.is_dir()], key=lambda p: p.name)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Renumber images in each subfolder (1..N)."
    )
    parser.add_argument(
        "--data-path",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "datasets" / "tunisian",
        help="Folder containing dish subfolders (default: datasets/tunisian in this repository).",
    )
    parser.add_argument("--start", type=int, default=1, help="Starting number.")
    parser.add_argument("--padding", type=int, default=6, help="Zero padding width.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would happen without renaming files.",
    )
    args = parser.parse_args()

    data_path = args.data_path.expanduser()
    if not data_path.exists():
        raise FileNotFoundError(f"Not found: {data_path}")
    if not data_path.is_dir():
        raise NotADirectoryError(f"Not a directory: {data_path}")

    total = 0
    for folder in iter_target_folders(data_path):
        count = renumber_images_in_folder(
            folder, start=args.start, padding=args.padding, dry_run=args.dry_run
        )
        total += count
        print(f"{folder.name}: {count} image(s) renumbered")

    print(f"Done. Total: {total} image(s) processed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
