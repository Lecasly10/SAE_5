"""Évalue le modèle sauvegardé sur dataset_small/test, sans le réentraîner.

Lancement depuis le dossier ai : python main.py evaluate
"""
import csv
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf

from src.config import (
    AI_DIR,
    CLASSES_PATH,
    EVALUATION_DIR,
    IMG_SIZE,
    MODEL_PATH,
    OTHER_CLASS,
    SMALL_DATASET_DIR,
)
from src.recognition import Thresholds

TEST_DIR = SMALL_DATASET_DIR / "test"
BATCH_SIZE = 16
TOP_K = 3
MAX_ERROR_IMAGES = 12
MAX_CONFUSIONS = 15
# Au-delà, la matrice de confusion n'est plus lisible
MAX_CLASSES_FOR_MATRIX = 25


def load_class_names():
    with open(CLASSES_PATH, encoding="utf-8") as file:
        class_names = json.load(file)

    folders = {path.name for path in TEST_DIR.iterdir() if path.is_dir()}
    if folders != set(class_names):
        raise ValueError(
            "Les dossiers de test ne correspondent pas à classes.json.\n"
            f"Classes manquantes : {sorted(set(class_names) - folders)}\n"
            f"Dossiers en trop : {sorted(folders - set(class_names))}"
        )
    return class_names


def predict_test_set(model, class_names):
    dataset = tf.keras.utils.image_dataset_from_directory(
        str(TEST_DIR), class_names=class_names, image_size=IMG_SIZE,
        batch_size=BATCH_SIZE, shuffle=False, label_mode="int",
    )
    image_paths = dataset.file_paths

    labels, scores = [], []
    for images, batch_labels in dataset:
        labels.append(batch_labels.numpy())
        scores.append(model(images, training=False).numpy())

    return image_paths, np.concatenate(labels), np.concatenate(scores)


def confusion_matrix(y_true, y_pred, size):
    matrix = np.zeros((size, size), dtype=int)
    np.add.at(matrix, (y_true, y_pred), 1)
    return matrix


def per_class_report(matrix, class_names):
    support = matrix.sum(axis=1)
    predicted = matrix.sum(axis=0)
    correct = np.diag(matrix)

    precision = np.divide(correct, predicted, out=np.zeros(len(class_names)), where=predicted != 0)
    recall = np.divide(correct, support, out=np.zeros(len(class_names)), where=support != 0)
    f1 = np.divide(2 * precision * recall, precision + recall,
                   out=np.zeros(len(class_names)), where=(precision + recall) != 0)

    return [
        dict(classe=name, images=int(support[i]), precision=float(precision[i]),
             rappel=float(recall[i]), f1=float(f1[i]))
        for i, name in enumerate(class_names)
    ]


def top_confusions(matrix, class_names):
    pairs = [
        (class_names[real], class_names[predicted], int(matrix[real, predicted]))
        for real, predicted in zip(*np.nonzero(matrix)) if real != predicted
    ]
    return sorted(pairs, key=lambda pair: pair[2], reverse=True)[:MAX_CONFUSIONS]


def answer_stats(scores, y_true, y_pred, class_names):
    """Ce que verrait l'utilisateur : l'application ne répond que si les
    seuils de recognition.json sont respectés."""
    thresholds = Thresholds.load()
    names = np.array(class_names)

    best = scores[np.arange(len(y_true)), y_pred] * 100
    second = np.sort(scores, axis=1)[:, -2] * 100
    answered = (
        (names[y_pred] != OTHER_CLASS)
        & (best >= thresholds.min_confidence)
        & (best - second >= thresholds.min_margin)
    )
    is_car = names[y_true] != OTHER_CLASS
    correct = y_pred == y_true

    return dict(
        min_confidence=thresholds.min_confidence,
        min_margin=thresholds.min_margin,
        answers=int(answered.sum()),
        answer_precision=float((answered & correct).sum() / max(answered.sum(), 1)),
        cars_found=float((answered & is_car & correct).sum() / max(is_car.sum(), 1)),
        other_wrongly_answered=float((answered & ~is_car).sum() / max((~is_car).sum(), 1)),
    )


def write_errors(image_paths, y_true, y_pred, scores, top_indices, class_names):
    fields = ["image", "classe_reelle", "classe_predite", "score_pct"]
    for rank in range(top_indices.shape[1]):
        fields += [f"top{rank + 1}_classe", f"top{rank + 1}_score_pct"]

    with open(EVALUATION_DIR / "errors.csv", "w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()

        for index in np.flatnonzero(y_pred != y_true):
            row = dict(
                image=str(Path(image_paths[index]).relative_to(AI_DIR)),
                classe_reelle=class_names[y_true[index]],
                classe_predite=class_names[y_pred[index]],
                score_pct=round(float(scores[index, y_pred[index]]) * 100, 2),
            )
            for rank, class_index in enumerate(top_indices[index], start=1):
                row[f"top{rank}_classe"] = class_names[class_index]
                row[f"top{rank}_score_pct"] = round(float(scores[index, class_index]) * 100, 2)
            writer.writerow(row)


def save_confusion_matrix(matrix, class_names):
    path = EVALUATION_DIR / "confusion_matrix.png"
    size = len(class_names)
    if size > MAX_CLASSES_FOR_MATRIX:
        path.unlink(missing_ok=True)
        return

    fig, ax = plt.subplots(figsize=(max(10, size), max(8, size)))
    chart = ax.imshow(matrix, cmap="Blues")
    fig.colorbar(chart, ax=ax)
    ax.set_xticks(range(size), labels=class_names, rotation=45, ha="right")
    ax.set_yticks(range(size), labels=class_names)
    ax.set(xlabel="Classe prédite", ylabel="Classe réelle", title="Matrice de confusion")
    for i in range(size):
        for j in range(size):
            ax.text(j, i, str(matrix[i, j]), ha="center", va="center",
                    color="white" if matrix[i, j] > matrix.max() / 2 else "black")
    fig.tight_layout()
    fig.savefig(path, dpi=160)
    plt.close(fig)


def save_error_gallery(image_paths, y_true, y_pred, scores, top_indices, class_names):
    path = EVALUATION_DIR / "error_examples.png"
    errors = np.flatnonzero(y_pred != y_true)
    # On montre d'abord les erreurs où l'IA était la plus sûre d'elle
    worst = sorted(errors, key=lambda i: scores[i, y_pred[i]], reverse=True)[:MAX_ERROR_IMAGES]
    if not worst:
        path.unlink(missing_ok=True)
        return

    rows = (len(worst) + 2) // 3
    fig, axes = plt.subplots(rows, 3, figsize=(18, 4 * rows), squeeze=False)
    for ax in axes.flat:
        ax.axis("off")
    for ax, index in zip(axes.flat, worst):
        ax.imshow(tf.keras.utils.load_img(image_paths[index], target_size=IMG_SIZE))
        lines = [f"Réelle : {class_names[y_true[index]]}"]
        lines += [f"{rank}. {class_names[c]} : {scores[index, c]:.1%}"
                  for rank, c in enumerate(top_indices[index], start=1)]
        ax.set_title("\n".join(lines), fontsize=9)
    fig.tight_layout()
    fig.savefig(path, dpi=140)
    plt.close(fig)


def main():
    class_names = load_class_names()
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    image_paths, y_true, scores = predict_test_set(model, class_names)

    y_pred = scores.argmax(axis=1)
    top_indices = np.argsort(-scores, axis=1, kind="stable")[:, :TOP_K]
    accuracy = float(np.mean(y_pred == y_true))
    top_k_accuracy = float(np.mean(np.any(top_indices == y_true[:, None], axis=1)))

    matrix = confusion_matrix(y_true, y_pred, len(class_names))
    classes = per_class_report(matrix, class_names)
    confusions = top_confusions(matrix, class_names)
    answers = answer_stats(scores, y_true, y_pred, class_names)

    EVALUATION_DIR.mkdir(parents=True, exist_ok=True)
    report = dict(images=len(y_true), accuracy=accuracy, top_k=TOP_K,
                  top_k_accuracy=top_k_accuracy, classes=classes,
                  recognition=answers, top_confusions=confusions)
    with open(EVALUATION_DIR / "metrics.json", "w", encoding="utf-8") as file:
        json.dump(report, file, ensure_ascii=False, indent=2)
    with open(EVALUATION_DIR / "metrics_by_class.csv", "w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=list(classes[0]))
        writer.writeheader()
        writer.writerows(classes)

    write_errors(image_paths, y_true, y_pred, scores, top_indices, class_names)
    save_confusion_matrix(matrix, class_names)
    save_error_gallery(image_paths, y_true, y_pred, scores, top_indices, class_names)

    print(f"\nImages de test : {len(y_true)}")
    print(f"Bonne réponse en premier : {accuracy:.2%}")
    print(f"Bonne réponse dans les {TOP_K} premières : {top_k_accuracy:.2%}\n")
    for row in classes:
        print(f"{row['classe']} : {row['images']} images | précision {row['precision']:.2%} "
              f"| rappel {row['rappel']:.2%} | F1 {row['f1']:.2%}")

    print("\nPlus grosses confusions (réelle -> prédite) :")
    for real, predicted, count in confusions:
        print(f"  {count:3d} x {real} -> {predicted}")

    print("\nCe que fait l'application avec les seuils de recognition.json :")
    print(f"  Réponses données : {answers['answers']} / {len(y_true)}")
    print(f"  Réponses justes quand elle répond : {answers['answer_precision']:.2%}")
    print(f"  Voitures trouvées et justes : {answers['cars_found']:.2%}")
    print(f"  Voitures hors liste prises pour une voiture connue : {answers['other_wrongly_answered']:.2%}")
    print(f"\nRésultats dans {EVALUATION_DIR}")
