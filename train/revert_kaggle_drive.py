import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description="Historical VF.ipynb helper; works on the explicitly supplied notebook.")
parser.add_argument("notebook", type=Path, help="Path to a working copy of a notebook; VF.ipynb is not included.")
args = parser.parse_args()
nb_path = args.notebook.expanduser()
nb = json.loads(nb_path.read_text(encoding='utf-8'))

replaced = False
for cell in nb.get('cells', []):
    if 'source' not in cell:
        continue
    src = ''.join(cell['source'])
    if 'KAGGLE_DATASET_ROOT' in src or 'DRIVE_DATASET_ROOT' in src:
        src = src.replace('KAGGLE_DATASET_ROOT = Path.home() / "Desktop" / "data"', 'KAGGLE_DATASET_ROOT = None')
        src = src.replace('DRIVE_DATASET_ROOT = Path.home() / "Desktop" / "data"', 'DRIVE_DATASET_ROOT = None')
        cell['source'] = [line + '\n' for line in src.splitlines()]
        replaced = True

if replaced:
    nb_path.write_text(json.dumps(nb, ensure_ascii=False, indent=1), encoding='utf-8')
    print('Reverted KAGGLE_DATASET_ROOT and DRIVE_DATASET_ROOT to None in', nb_path)
else:
    print('No matching lines found; no changes made')
