import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description="Historical VF.ipynb helper; works on the explicitly supplied notebook.")
parser.add_argument("notebook", type=Path, help="Path to a working copy of a notebook; VF.ipynb is not included.")
parser.add_argument("--data-path", type=Path, required=True, help="ImageFolder dataset to reference.")
args = parser.parse_args()
nb_path = args.notebook.expanduser()
nb = json.loads(nb_path.read_text(encoding='utf-8'))

old_line = 'DATASET_ROOT = None'
new_line = 'DATASET_ROOT = Path(' + repr(str(args.data_path.expanduser().resolve())) + ')'

changed = False
for cell in nb.get('cells', []):
    if 'source' not in cell:
        continue
    # source can be list of strings
    src = ''.join(cell['source'])
    if old_line in src:
        src = src.replace(old_line, new_line)
        # split back into lines preserving newlines
        cell['source'] = [line + '\n' for line in src.splitlines()]
        changed = True
        break

if not changed:
    print('No change made: target line not found')
else:
    nb_path.write_text(json.dumps(nb, ensure_ascii=False, indent=1), encoding='utf-8')
    print('Updated DATASET_ROOT in', nb_path)
