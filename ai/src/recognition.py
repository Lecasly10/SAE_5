import json
from dataclasses import dataclass

import numpy as np

from src.config import OTHER_CLASS, THRESHOLDS_PATH

REASON_NO_CAR = "no_car"
REASON_UNKNOWN = "unknown"


@dataclass(frozen=True)
class Thresholds:
    # En pourcentage : confiance minimale de la meilleure réponse, et écart
    # minimal avec la deuxième.
    min_confidence: float
    min_margin: float

    @classmethod
    def load(cls, path=THRESHOLDS_PATH):
        with open(path, "r", encoding="utf-8") as file:
            data = json.load(file)

        return cls(
            min_confidence=float(data["min_confidence"]),
            min_margin=float(data["min_margin"]),
        )

    def accepts(self, is_car, best, second):
        """Vrai si l'IA peut donner sa réponse. Marche avec des nombres comme
        avec des tableaux numpy (une valeur par image)."""
        return is_car & (best >= self.min_confidence) & (best - second >= self.min_margin)

    def save(self, path, stats):
        with open(path, "w", encoding="utf-8") as file:
            json.dump(
                {
                    "min_confidence": self.min_confidence,
                    "min_margin": self.min_margin,
                    "calibration": stats,
                },
                file,
                indent=2,
            )


@dataclass(frozen=True)
class Decision:
    recognized: bool
    reason: str | None = None


def decide(ranked, thresholds, has_box):
    """ranked : liste (classe, confiance en %), de la plus à la moins probable.

    Refuse la voiture si la meilleure réponse est "autre", pas assez sûre ou
    trop proche de la deuxième. Sans cadre détecté, aucune voiture n'a été vue.
    """
    best_class, best_confidence = ranked[0]
    second_confidence = ranked[1][1] if len(ranked) > 1 else 0.0

    if thresholds.accepts(best_class != OTHER_CLASS, best_confidence, second_confidence):
        return Decision(recognized=True)

    return Decision(
        recognized=False,
        reason=REASON_UNKNOWN if has_box else REASON_NO_CAR,
    )


def top_two(scores):
    """Classe prédite, puis meilleure et deuxième confiance (en %) de chaque
    image. scores : probabilités (images, classes)."""
    scores = np.asarray(scores)
    second = np.partition(scores, -2, axis=1)[:, -2]
    return scores.argmax(axis=1), scores.max(axis=1) * 100, second * 100


def choose_thresholds(
    scores,
    labels,
    other_index,
    target_precision=0.9,
    confidence_grid=range(30, 100),
    margin_grid=range(0, 42, 2),
):
    """Cherche les seuils qui gardent le plus de bonnes réponses tout en ayant
    raison au moins `target_precision` du temps.

    scores : probabilités (images, classes), labels : classes réelles.
    """
    labels = np.asarray(labels)
    predicted, best, second = top_two(scores)
    is_car = predicted != other_index
    is_correct = predicted == labels

    candidates = []
    for min_confidence in confidence_grid:
        for min_margin in margin_grid:
            accepted = Thresholds(min_confidence, min_margin).accepts(is_car, best, second)
            count = int(accepted.sum())
            correct = int((accepted & is_correct).sum())
            precision = correct / count if count else 0.0
            candidates.append((min_confidence, min_margin, count, correct, precision))

    reliable = [c for c in candidates if c[2] and c[4] >= target_precision]
    if reliable:
        # Le plus de bonnes réponses ; à égalité, les seuils les plus stricts
        chosen = max(reliable, key=lambda c: (c[3], c[0], c[1]))
    else:
        chosen = max(candidates, key=lambda c: (c[4], c[3], c[0], c[1]))

    min_confidence, min_margin, count, correct, precision = chosen
    car_images = int((labels != other_index).sum())
    stats = {
        "target_precision": target_precision,
        "images": int(len(labels)),
        "accepted": count,
        "precision": round(precision, 4),
        "found": round(correct / car_images, 4) if car_images else 0.0,
    }
    return Thresholds(float(min_confidence), float(min_margin)), stats
