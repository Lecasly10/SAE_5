import threading

import numpy as np
import tensorflow as tf

from src.config import DETECTOR_PATH


class CarDetector:

    # Identifiants des classes du dataset COCO : 2 = voiture, 7 = camion
    VEHICLE_CLASS_IDS = {2, 7}

    def __init__(self, model_path=DETECTOR_PATH, min_score=0.4):
        self.min_score = min_score

        self.interpreter = tf.lite.Interpreter(model_path=str(model_path))
        self.interpreter.allocate_tensors()

        self.input_details = self.interpreter.get_input_details()[0]
        self.output_details = self.interpreter.get_output_details()
        self.input_size = self.input_details["shape"][1]

        self.lock = threading.Lock()

    def detect(self, image):
        resized = image.convert("RGB").resize((self.input_size, self.input_size))
        batch = np.expand_dims(np.asarray(resized, dtype=np.uint8), axis=0)

        with self.lock:
            self.interpreter.set_tensor(self.input_details["index"], batch)
            self.interpreter.invoke()

            boxes, classes, scores = (
                self.interpreter.get_tensor(detail["index"])[0]
                for detail in self.output_details[:3]
            )

        for box, class_id, score in zip(boxes, classes, scores):
            if score >= self.min_score and int(class_id) in self.VEHICLE_CLASS_IDS:
                return self.to_relative_box(box)

        return None

    @staticmethod
    def to_relative_box(box):
        y_min, x_min, y_max, x_max = np.clip(box, 0, 1)

        return {
            "x": float(x_min),
            "y": float(y_min),
            "width": float(x_max - x_min),
            "height": float(y_max - y_min),
        }
