import argparse
import json
from pathlib import Path
import re
parser = argparse.ArgumentParser(description="Historical VF.ipynb helper; works on the explicitly supplied notebook.")
parser.add_argument("notebook", type=Path, help="Path to a working copy of a notebook; VF.ipynb is not included.")
args = parser.parse_args()
path = args.notebook.expanduser()
nb = json.loads(path.read_text(encoding='utf-8'))
for i, cell in enumerate(nb['cells']):
    src = ''.join(cell.get('source', []))
    if re.search(r'P100|KAGGLE|COLAB|CUDA available|torch\.cuda\.is_available|device = "cuda"|torch\.cuda\.get_arch_list|sm_60|FORCE_REINSTALL_P100_TORCH|INPUT_DIR|WORKING_DIR|MODEL_DIR', src, re.I):
        print('CELL', i)
        print(src)
        print('---')
