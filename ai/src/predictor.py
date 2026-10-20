import json

import numpy as np
import tensorflow as tf
from PIL import Image, ImageOps

from src.config import CLASSES_PATH, IMG_SIZE, MODEL_PATH


class CarPredictor:

    def __init__(self, model_path=MODEL_PATH, classes_path=CLASSES_PATH):
        self.model = tf.keras.models.load_model(model_path)

        with open(classes_path, "r", encoding="utf-8") as file:
            self.class_names = json.load(file)

    @staticmethod
    def load_image(source):
        if not isinstance(source, Image.Image):
            source = Image.open(source)

        image = ImageOps.exif_transpose(source).convert("RGB")

        # Même redimensionnement (bilinéaire) que pendant l'entraînement
        resized = tf.image.resize(np.asarray(image), IMG_SIZE)

        return np.expand_dims(resized.numpy(), axis=0)

    def predict(self, source):
        """Retourne toutes les classes avec leur confiance en %, la plus
        probable en premier."""
        scores = self.model(self.load_image(source), training=False).numpy()[0]

        return [
            (self.class_names[index], scores[index] * 100)
            for index in np.argsort(scores)[::-1]
        ]

    def display_predictions(self, source, limit=5):
        print("\nVoici les prédictions :\n")

        for car_class, confidence in self.predict(source)[:limit]:
            print(f"{car_class} : {confidence:.2f} %")
