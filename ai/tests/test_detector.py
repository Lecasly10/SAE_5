import threading
import unittest

import numpy as np
from PIL import Image

from src.detector import CarDetector

PERSON, CAR, TRUCK = 0, 2, 7


class FakeInterpreter:

    def __init__(self, detections):
        boxes, classes, scores = zip(*detections) if detections else ((), (), ())
        self.outputs = [np.array([boxes]), np.array([classes]), np.array([scores])]

    def set_tensor(self, index, value):
        pass

    def invoke(self):
        pass

    def get_tensor(self, index):
        return self.outputs[index]


def detector_seeing(*detections):
    detector = CarDetector.__new__(CarDetector)
    detector.min_score = 0.4
    detector.interpreter = FakeInterpreter(detections)
    detector.input_details = {"index": 0}
    detector.output_details = [{"index": index} for index in range(3)]
    detector.input_size = 8
    detector.lock = threading.Lock()
    return detector


IMAGE = Image.new("RGB", (32, 32))


class CarDetectorTest(unittest.TestCase):

    def test_picks_the_car_in_the_foreground(self):
        # Les boîtes sont (haut, gauche, bas, droite), la plus sûre en premier
        detector = detector_seeing(
            ([0.3, 0.6, 0.5, 1.0], CAR, 0.9),
            ([0.3, 0.1, 0.7, 0.7], CAR, 0.7),
            ([0.0, 0.0, 1.0, 1.0], PERSON, 0.95),
        )

        box = detector.detect(IMAGE)

        self.assertAlmostEqual(box["x"], 0.1)
        self.assertAlmostEqual(box["width"], 0.6)

    def test_trucks_count_but_unsure_vehicles_do_not(self):
        detector = detector_seeing(
            ([0.0, 0.0, 1.0, 1.0], CAR, 0.3),
            ([0.2, 0.2, 0.6, 0.6], TRUCK, 0.5),
        )

        self.assertAlmostEqual(detector.detect(IMAGE)["width"], 0.4)

    def test_no_vehicle(self):
        self.assertIsNone(detector_seeing(([0.0, 0.0, 1.0, 1.0], PERSON, 0.9)).detect(IMAGE))


if __name__ == "__main__":
    unittest.main()
