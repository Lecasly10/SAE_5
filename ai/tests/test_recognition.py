import json
import tempfile
import unittest
from pathlib import Path

import numpy as np

from src.config import OTHER_CLASS
from src.recognition import (
    REASON_NO_CAR,
    REASON_UNKNOWN,
    Thresholds,
    choose_thresholds,
    decide,
)

THRESHOLDS = Thresholds(min_confidence=60, min_margin=15)


class DecideTest(unittest.TestCase):

    def test_confident_answer_is_recognized(self):
        decision = decide([("clio", 90.0), ("twingo", 5.0)], THRESHOLDS, has_box=True)

        self.assertTrue(decision.recognized)
        self.assertIsNone(decision.reason)

    def test_low_confidence_is_unknown(self):
        decision = decide([("clio", 40.0), ("twingo", 5.0)], THRESHOLDS, has_box=True)

        self.assertFalse(decision.recognized)
        self.assertEqual(decision.reason, REASON_UNKNOWN)

    def test_close_second_answer_is_unknown(self):
        decision = decide([("clio", 65.0), ("twingo", 60.0)], THRESHOLDS, has_box=True)

        self.assertFalse(decision.recognized)

    def test_other_class_is_never_recognized(self):
        decision = decide([(OTHER_CLASS, 99.0), ("clio", 1.0)], THRESHOLDS, has_box=True)

        self.assertFalse(decision.recognized)

    def test_no_box_means_no_car_seen(self):
        decision = decide([("clio", 20.0), ("twingo", 10.0)], THRESHOLDS, has_box=False)

        self.assertFalse(decision.recognized)
        self.assertEqual(decision.reason, REASON_NO_CAR)

    def test_confident_answer_without_box_is_still_recognized(self):
        # Le détecteur rate des voitures : une réponse sûre reste acceptée.
        decision = decide([("clio", 95.0), ("twingo", 2.0)], THRESHOLDS, has_box=False)

        self.assertTrue(decision.recognized)


class ChooseThresholdsTest(unittest.TestCase):

    def setUp(self):
        # Classes : 0 = voiture A, 1 = voiture B, 2 = autre.
        # Réponses sûres et justes, réponses hésitantes et souvent fausses.
        self.scores = np.array([
            [0.95, 0.03, 0.02],
            [0.92, 0.05, 0.03],
            [0.04, 0.93, 0.03],
            [0.90, 0.06, 0.04],
            [0.45, 0.40, 0.15],
            [0.42, 0.44, 0.14],
            [0.50, 0.30, 0.20],
            [0.03, 0.02, 0.95],
        ])
        self.labels = np.array([0, 0, 1, 0, 1, 0, 1, 2])

    def test_picks_thresholds_reaching_target_precision(self):
        thresholds, stats = choose_thresholds(
            self.scores, self.labels, other_index=2, target_precision=0.9,
        )

        self.assertGreaterEqual(stats["precision"], 0.9)
        self.assertEqual(stats["accepted"], 4)
        self.assertGreater(thresholds.min_confidence, 50)

    def test_falls_back_to_best_precision_when_target_is_unreachable(self):
        scores = np.array([[0.6, 0.4, 0.0], [0.6, 0.4, 0.0]])
        labels = np.array([1, 1])

        _, stats = choose_thresholds(scores, labels, other_index=2, target_precision=0.9)

        self.assertEqual(stats["precision"], 0.0)

    def test_thresholds_roundtrip_through_json(self):
        thresholds, stats = choose_thresholds(
            self.scores, self.labels, other_index=2,
        )

        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "recognition.json"
            thresholds.save(path, stats)

            self.assertEqual(Thresholds.load(path), thresholds)
            self.assertIn("calibration", json.loads(path.read_text(encoding="utf-8")))

    def test_missing_file_is_an_error(self):
        with self.assertRaises(FileNotFoundError):
            Thresholds.load("inexistant.json")


if __name__ == "__main__":
    unittest.main()
