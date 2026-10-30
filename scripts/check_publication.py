"""Check the files Git would publish without displaying any matched secret."""
from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TOKEN = re.compile(
    rb"\b(?:gsk_[A-Za-z0-9]{16,}|sk-[A-Za-z0-9_-]{16,}|"
    rb"gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{16,}|"
    rb"hf_[A-Za-z0-9]{16,}|AIza[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16})"
)
LITERAL = re.compile(
    rb'''(?i)(?:api[_-]?key|access[_-]?token|auth[_-]?token|password)\s*[=:]\s*["']([^"'\r\n]{8,})["']'''
)
EXAMPLE_VALUES = {b"your_groq_api_key_here", b"YOUR_API_KEY", b"example", b"placeholder"}
FORBIDDEN_DIRS = {
    ".venv", "venv", "__pycache__", ".dart_tool", "build", "run_logs",
    "android-ndk-r27d-windows", ".idea", ".qodo", ".sixth", "datasets",
}


def main() -> int:
    git_root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], cwd=ROOT)
    if Path(git_root.decode().strip()).resolve() != ROOT.resolve():
        print("Publication checks FAILED: initialize an independent Git repository here first.")
        return 1
    result = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT, check=True, capture_output=True,
    )
    names = sorted(set(result.stdout.decode("utf-8").split("\0")) - {""})
    # Inspect staged bytes as well as the working copy. Editing a secret out of
    # a file after git add must not hide the copy still held in Git's index.
    entries = subprocess.check_output(["git", "ls-files", "--stage", "-z"], cwd=ROOT)
    staged = {}
    for entry in entries.decode().split("\0"):
        if entry:
            metadata, name = entry.split("\t", 1)
            _, object_id, _ = metadata.split()
            staged[name] = object_id
    object_ids = sorted(set(staged.values()))
    objects = {}
    if object_ids:
        batch = subprocess.run(
            ["git", "cat-file", "--batch"], cwd=ROOT,
            input=("\n".join(object_ids) + "\n").encode(),
            capture_output=True, check=True,
        )
        stream = BytesIO(batch.stdout)
        for object_id in object_ids:
            header = stream.readline().split()
            objects[object_id] = stream.read(int(header[2]))
            stream.read(1)
    errors = []
    for name in names:
        relative = Path(name)
        path = ROOT / relative
        versions = []
        if name in staged:
            versions.append(objects[staged[name]])
        if path.is_file():
            working = path.read_bytes()
            if working not in versions:
                versions.append(working)
        for content in versions:
            reasons = inspect_content(name, relative, content)
            if reasons:
                errors.append(f"{name}: {', '.join(reasons)}")
    if errors:
        print("Publication checks FAILED:")
        print("\n".join(sorted(set(errors))))
        return 1
    print(f"Publication checks passed: {len(names)} files; index and working copies checked.")
    return 0


def inspect_content(name: str, relative: Path, content: bytes) -> list[str]:
    reason = []
    if (relative.name.startswith(".env") and relative.name != ".env.example") or relative.name in {
        "kaggle.json", "credentials.json", "token.json", "local.properties", "key.properties",
    }:
        reason.append("private configuration file")
    if set(relative.parts) & FORBIDDEN_DIRS or name.startswith("train/data/"):
        reason.append("generated files or raw dataset")
    if len(content) >= 100 * 1024 * 1024:
        reason.append("file at or above 100 MiB")
    if TOKEN.search(content) or (b"-----BEGIN " + b"PRIVATE KEY-----") in content or (b"-----BEGIN RSA " + b"PRIVATE KEY-----") in content:
        reason.append("possible credential; value withheld")
    if any(m.group(1) not in EXAMPLE_VALUES for m in LITERAL.finditer(content)):
        reason.append("credential literal to review; value withheld")
    if re.search(rb"(?i)[a-z]:[\\/]+Users[\\/]+[^\\/\r\n]+", content):
        reason.append("machine-specific user path")
    if (b"https://" + b"drive.google.com/drive/folders/") in content:
        reason.append("personal Drive folder link to review")
    if relative.suffix == ".ipynb":
        notebook = json.loads(content)
        if any(c.get("outputs") or c.get("execution_count") is not None for c in notebook["cells"]):
            reason.append("notebook outputs or execution history")
    return reason


if __name__ == "__main__":
    sys.exit(main())
