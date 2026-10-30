import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description="Historical VF.ipynb helper; works on the explicitly supplied notebook.")
parser.add_argument("notebook", type=Path, help="Path to a working copy of a notebook; VF.ipynb is not included.")
args = parser.parse_args()
nb_path = args.notebook.expanduser()
nb = json.loads(nb_path.read_text(encoding='utf-8'))

# Replacement implementations
make_cm_impl = '''def make_confusion_matrix(
    y_true,
    y_pred,
    classes=None,
    figsize=(20, 20),
    text_size=8,
    norm=True,
    savefig=False,
):

    import numpy as _np
    from sklearn.metrics import confusion_matrix as _confusion_matrix

    if classes:
        labels = classes
        cm = _confusion_matrix(y_true, y_pred, labels=_np.arange(len(classes)))
    else:
        labels = _np.arange(len(_np.unique(y_true)))
        cm = _confusion_matrix(y_true, y_pred)

    # counts and normalized per-row percentages
    cm_counts = cm.astype(int)
    with _np.errstate(divide='ignore', invalid='ignore'):
        cm_norm = cm.astype('float') / cm.sum(axis=1, keepdims=True)
        cm_norm = _np.nan_to_num(cm_norm)

    n_classes = cm.shape[0]

    fig, ax = plt.subplots(figsize=figsize)
    cax = ax.matshow(cm_counts, cmap=plt.cm.Blues)
    fig.colorbar(cax)

    ax.set(
        title='Confusion Matrix',
        xlabel='Predicted Label',
        ylabel='True Label',
        xticks=_np.arange(n_classes),
        yticks=_np.arange(n_classes),
        xticklabels=labels,
        yticklabels=labels
    )

    ax.xaxis.set_label_position('bottom')
    ax.xaxis.tick_bottom()
    plt.xticks(rotation=90)

    # Annotate each cell with count and percent
    for i in range(n_classes):
        for j in range(n_classes):
            count = cm_counts[i, j]
            pct = cm_norm[i, j] * 100
            text = f"{count}\n({pct:.1f}%)"
            ax.text(
                j,
                i,
                text,
                horizontalalignment='center',
                color='white' if cm_counts[i, j] > (cm_counts.max() / 2.) else 'black',
                size=text_size
            )

    plt.tight_layout()

    if savefig:
        output_dir = globals().get('PLOT_DIR', Path('.'))
        output_path = Path(output_dir) / 'confusion_matrix.png'

        plt.savefig(
            output_path,
            dpi=300,
            bbox_inches='tight'
        )

        print(f"[INFO] Confusion matrix saved to {output_path}")

    plt.show()
'''

plot_roc_impl = '''def plot_multiclass_roc_auc(
    y_true,
    y_score,
    classes,
    savefig=True
):
    import numpy as _np
    from sklearn.metrics import roc_curve as _roc_curve, auc as _auc
    from sklearn.preprocessing import label_binarize as _label_binarize

    n_classes = len(classes)
    y_true = _np.array(y_true)
    y_score = _np.array(y_score)

    # Ensure y_score is probability-like with shape (n_samples, n_classes)
    if y_score.ndim == 1 or y_score.shape[1] != n_classes:
        raise ValueError('y_score must be of shape (n_samples, n_classes) with class probabilities')

    # Binarize y_true
    y_true_bin = _label_binarize(y_true, classes=_np.arange(n_classes))

    fpr = dict()
    tpr = dict()
    roc_auc = dict()
    valid_class_indices = []

    for i in range(n_classes):
        # Need at least one positive and one negative sample
        if len(_np.unique(y_true_bin[:, i])) < 2:
            continue

        fpr[i], tpr[i], _ = _roc_curve(y_true_bin[:, i], y_score[:, i])
        roc_auc[i] = _auc(fpr[i], tpr[i])
        valid_class_indices.append(i)

    if not valid_class_indices:
        print('[WARN] ROC/AUC could not be computed: no class has both positive and negative samples')
        return {}

    # micro-average
    fpr['micro'], tpr['micro'], _ = _roc_curve(y_true_bin.ravel(), y_score[:, valid_class_indices].ravel())
    roc_auc['micro'] = _auc(fpr['micro'], tpr['micro'])

    # macro-average: interpolate
    all_fpr = _np.unique(_np.concatenate([fpr[i] for i in valid_class_indices]))
    mean_tpr = _np.zeros_like(all_fpr)
    for i in valid_class_indices:
        mean_tpr += _np.interp(all_fpr, fpr[i], tpr[i])
    mean_tpr /= len(valid_class_indices)

    fpr['macro'] = all_fpr
    tpr['macro'] = mean_tpr
    roc_auc['macro'] = _auc(fpr['macro'], tpr['macro'])

    plt.figure(figsize=(10, 8))

    # Plot per-class ROC with low alpha
    for i in valid_class_indices:
        plt.plot(fpr[i], tpr[i], lw=1, alpha=0.4, label=f"{classes[i]} (AUC = {roc_auc[i]:.3f})")

    # Plot micro and macro
    plt.plot(fpr['micro'], tpr['micro'], color='deeppink', linestyle=':', linewidth=3, label=f"Micro-average (AUC = {roc_auc['micro']:.3f})")
    plt.plot(fpr['macro'], tpr['macro'], color='navy', linestyle=':', linewidth=3, label=f"Macro-average (AUC = {roc_auc['macro']:.3f})")

    plt.plot([0, 1], [0, 1], color='gray', linestyle='--', lw=1)
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Curves and AUC')
    plt.legend(loc='lower right', fontsize=8)
    plt.grid(alpha=0.3)
    plt.tight_layout()

    if savefig:
        roc_curve_path = Path(globals().get('PLOT_DIR', Path('.'))) / 'roc_auc_curve.png'
        plt.savefig(roc_curve_path, dpi=300, bbox_inches='tight')
        print(f"[INFO] ROC curve saved to {roc_curve_path}")

    plt.show()

    auc_scores = {'micro_average': float(roc_auc['micro']), 'macro_average': float(roc_auc['macro'])}
    auc_scores.update({classes[i]: float(roc_auc[i]) for i in valid_class_indices})

    # Save scores to MODEL_DIR
    roc_scores_path = Path(globals().get('MODEL_DIR', Path('models'))) / 'roc_auc_scores.json'
    with open(roc_scores_path, 'w') as f:
        json.dump(auc_scores, f, indent=4)

    print(f"[INFO] AUC scores saved to {roc_scores_path}")
    return auc_scores
'''

# Find cells and replace implementations
made_changes = 0
for cell in nb.get('cells', []):
    if 'source' not in cell:
        continue
    src = ''.join(cell['source'])
    if 'def make_confusion_matrix(' in src and 'Confusion Matrix' in src:
        start = src.find('def make_confusion_matrix(')
        # naive: replace from start to next double newline after function
        end_marker = '\n\n    plt.show()\n'
        end = src.find(end_marker, start)
        if end != -1:
            end += len(end_marker)
            new_src = src[:start] + make_cm_impl + src[end:]
            cell['source'] = [line + '\n' for line in new_src.splitlines()]
            made_changes += 1
    if 'def plot_multiclass_roc_auc(' in src and 'ROC Curves and AUC' in src:
        start = src.find('def plot_multiclass_roc_auc(')
        end_marker = "    return auc_scores\n"
        end = src.find(end_marker, start)
        if end != -1:
            end += len(end_marker)
            new_src = src[:start] + plot_roc_impl + src[end:]
            cell['source'] = [line + '\n' for line in new_src.splitlines()]
            made_changes += 1

if made_changes:
    nb_path.write_text(json.dumps(nb, ensure_ascii=False, indent=1), encoding='utf-8')
    print(f'Updated {made_changes} function implementations in', nb_path)
else:
    print('No target functions found; no changes made')
