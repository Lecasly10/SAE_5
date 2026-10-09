"""Évalue le modèle sauvegardé sans le réentraîner.

Exécution depuis la racine du projet : python evaluate.py
Dépendances : tensorflow, numpy, matplotlib (comme train.py).
"""
import csv
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # Sauvegarde les graphiques sans ouvrir de fenêtre.
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf

# Chemins relatifs au dossier contenant ce script.
ROOT = Path(__file__).resolve().parent.parent
MODEL_PATH = ROOT / "models/spotit_mobilenet.keras"
CLASSES_PATH = ROOT / "models/classes.json"
TEST_DIR = ROOT / "dataset_small/test"
OUTPUT_DIR = ROOT / "models/evaluation"
IMG_SIZE = (224, 224)
BATCH_SIZE = 16
MAX_ERROR_IMAGES = 12


def main():
    for path in (MODEL_PATH, CLASSES_PATH, TEST_DIR):
        if not path.exists():
            raise FileNotFoundError(f"Chemin introuvable : {path}")

    with CLASSES_PATH.open(encoding="utf-8") as file:
        class_names = json.load(file)
    if (not isinstance(class_names, list) or not class_names
            or not all(isinstance(name, str) for name in class_names)
            or len(set(class_names)) != len(class_names)):
        raise ValueError("classes.json doit contenir une liste de noms uniques.")

    # L'ordre doit être celui de classes.json, pas un ordre supposé.
    folder_names = {path.name for path in TEST_DIR.iterdir() if path.is_dir()}
    if folder_names != set(class_names):
        raise ValueError(
            "Les dossiers de test ne correspondent pas à classes.json.\n"
            f"Classes manquantes : {sorted(set(class_names) - folder_names)}\n"
            f"Dossiers supplémentaires : {sorted(folder_names - set(class_names))}"
        )

    dataset = tf.keras.utils.image_dataset_from_directory(
        str(TEST_DIR), class_names=class_names, image_size=IMG_SIZE,
        batch_size=BATCH_SIZE, shuffle=False, label_mode="int",
    )
    # Conserver les chemins avant prefetch pour associer scores et fichiers.
    image_paths = dataset.file_paths
    dataset = dataset.prefetch(tf.data.AUTOTUNE)
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    if tuple(model.input_shape[1:]) != (224, 224, 3):
        raise ValueError(f"Format d'entrée inattendu : {model.input_shape}")
    if model.output_shape[-1] != len(class_names):
        raise ValueError("Le nombre de sorties du modèle diffère de classes.json.")

    # Une seule passe : images, labels et scores restent alignés.
    true_batches, score_batches = [], []
    for images, labels in dataset:
        true_batches.append(labels.numpy())
        # Pas de division par 255 : le modèle fourni contient le prétraitement.
        score_batches.append(model(images, training=False).numpy())
    y_true = np.concatenate(true_batches)
    scores = np.concatenate(score_batches)
    if (not np.isfinite(scores).all() or np.any(scores < 0)
            or np.any(scores > 1)
            or not np.allclose(scores.sum(axis=1), 1, atol=1e-4)):
        raise ValueError("Les sorties attendues sont des scores softmax valides.")
    y_pred = scores.argmax(axis=1)
    top_indices = np.argsort(-scores, axis=1, kind="stable")[:, :min(3, len(class_names))]
    accuracy = float(np.mean(y_pred == y_true))
    top3_accuracy = float(np.mean(np.any(top_indices == y_true[:, None], axis=1)))
    loss = float(np.mean(tf.keras.losses.sparse_categorical_crossentropy(y_true, scores).numpy()))

    cm = np.zeros((len(class_names), len(class_names)), dtype=int)
    np.add.at(cm, (y_true, y_pred), 1)
    support = cm.sum(axis=1)
    predicted_counts = cm.sum(axis=0)
    correct = np.diag(cm)
    precision = np.divide(correct, predicted_counts, out=np.zeros(len(class_names)), where=predicted_counts != 0)
    recall = np.divide(correct, support, out=np.zeros(len(class_names)), where=support != 0)
    f1 = np.divide(2 * precision * recall, precision + recall,
                   out=np.zeros(len(class_names)), where=(precision + recall) != 0)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"\nImages de test : {len(y_true)}")
    print(f"Accuracy : {accuracy:.2%}")
    print(f"Accuracy top-{top_indices.shape[1]} : {top3_accuracy:.2%}")
    print(f"Loss : {loss:.4f}\n")
    per_class = []
    for i, name in enumerate(class_names):
        row = dict(classe=name, images=int(support[i]), precision=float(precision[i]),
                   rappel=float(recall[i]), f1=float(f1[i]))
        per_class.append(row)
        print(f"{name} : {support[i]} images | précision {precision[i]:.2%} | rappel {recall[i]:.2%} | F1 {f1[i]:.2%}")
        if support[i] == 0:
            print("  Attention : aucune image de test pour cette classe.")

    report = dict(images=len(y_true), accuracy=accuracy, top_k=top_indices.shape[1],
                  top_k_accuracy=top3_accuracy, loss=loss, classes=per_class,
                  confusion_matrix=cm.tolist())
    with (OUTPUT_DIR / "metrics.json").open("w", encoding="utf-8") as file:
        json.dump(report, file, ensure_ascii=False, indent=2)
    with (OUTPUT_DIR / "metrics_by_class.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=list(per_class[0]))
        writer.writeheader()
        writer.writerows(per_class)

    # Toutes les erreurs, avec leurs trois meilleures prédictions.
    errors = np.flatnonzero(y_pred != y_true)
    fields = ["image", "classe_reelle", "classe_predite", "score_pct"]
    for rank in range(top_indices.shape[1]):
        fields.extend([f"top{rank + 1}_classe", f"top{rank + 1}_score_pct"])
    with (OUTPUT_DIR / "errors.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()
        for index in errors:
            row = dict(image=str(Path(image_paths[index]).relative_to(ROOT)),
                       classe_reelle=class_names[y_true[index]],
                       classe_predite=class_names[y_pred[index]],
                       score_pct=round(float(scores[index, y_pred[index]]) * 100, 2))
            for rank, class_index in enumerate(top_indices[index], start=1):
                row[f"top{rank}_classe"] = class_names[class_index]
                row[f"top{rank}_score_pct"] = round(float(scores[index, class_index]) * 100, 2)
            writer.writerow(row)

    fig, ax = plt.subplots(figsize=(max(10, len(class_names)), max(8, len(class_names))))
    chart = ax.imshow(cm, cmap="Blues")
    fig.colorbar(chart, ax=ax)
    ax.set_xticks(range(len(class_names)), labels=class_names, rotation=45, ha="right")
    ax.set_yticks(range(len(class_names)), labels=class_names)
    ax.set(xlabel="Classe prédite", ylabel="Classe réelle", title="Matrice de confusion — test")
    for i in range(len(class_names)):
        for j in range(len(class_names)):
            ax.text(j, i, str(cm[i, j]), ha="center", va="center",
                    color="white" if cm[i, j] > cm.max() / 2 else "black")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "confusion_matrix.png", dpi=160)
    plt.close(fig)

    # Montrer en priorité les erreurs avec les scores les plus élevés.
    selected = sorted(errors, key=lambda i: float(scores[i, y_pred[i]]), reverse=True)[:MAX_ERROR_IMAGES]
    if selected:
        fig, axes = plt.subplots((len(selected) + 2) // 3, 3,
                                 figsize=(18, 4 * ((len(selected) + 2) // 3)), squeeze=False)
        for ax in axes.flat:
            ax.axis("off")
        for ax, index in zip(axes.flat, selected):
            image = tf.keras.utils.load_img(image_paths[index], target_size=IMG_SIZE)
            ax.imshow(image)
            title = f"Réelle : {class_names[y_true[index]]}\n"
            title += "\n".join(f"{rank}. {class_names[c]} : {scores[index, c]:.1%}"
                               for rank, c in enumerate(top_indices[index], start=1))
            ax.set_title(title, fontsize=9)
        fig.tight_layout()
        fig.savefig(OUTPUT_DIR / "error_examples.png", dpi=140)
        plt.close(fig)
    else:
        # Supprimer une éventuelle galerie issue d'une précédente évaluation.
        (OUTPUT_DIR / "error_examples.png").unlink(missing_ok=True)

    print(f"\nErreurs : {len(errors)} / {len(y_true)}")
    print(f"Résultats sauvegardés dans : {OUTPUT_DIR}")
    print("Les scores softmax ne garantissent pas que la prédiction est correcte.")


if __name__ == "__main__":
    main()
