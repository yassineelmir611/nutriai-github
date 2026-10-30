import argparse
from pathlib import Path
import torch
parser = argparse.ArgumentParser(description="Inspect the GPU and a local ImageFolder dataset.")
parser.add_argument("--data-path", type=Path, default=Path(__file__).resolve().parents[1] / "datasets" / "tunisian")
p = parser.parse_args().data_path.expanduser()
print('CUDA_AVAILABLE:', torch.cuda.is_available())
print('CUDA_DEVICE_COUNT:', torch.cuda.device_count())
print('DATASET_ROOT:', p)
print('DATASET_ROOT_EXISTS:', p.exists())
if p.exists():
    classes = [c.name for c in sorted(p.iterdir()) if c.is_dir()]
    print('NUM_CLASSES:', len(classes))
    print('FIRST_CLASSES_SAMPLE:', classes[:20])
else:
    print('NO_DATASET')
