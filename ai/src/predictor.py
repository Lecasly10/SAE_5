import json
from pathlib import Path

import numpy as np
import tensorflow as tf


class CarPredictor:

    IMG_SIZE = (224, 224)

    def __init__(
        self,
        model_path="models/spotit_mobilenet.keras",
        classes_path="models/classes.json"
    ):
        self.model_path = Path(model_path)
        self.classes_path = Path(classes_path)

        self.model = self.load_model()
        self.class_names = self.load_classes()

    def load_model(self):
        return tf.keras.models.load_model(
            self.model_path
        )

    def load_classes(self):
        with open(
            self.classes_path,
            "r",
            encoding="utf-8"
        ) as file:
            return json.load(file)

    def load_image(self, image_path):
        image = tf.keras.utils.load_img(
            image_path,
            target_size=self.IMG_SIZE
        )

        image_array = tf.keras.utils.img_to_array(image)

        return np.expand_dims(
            image_array,
            axis=0
        )

    def predict(self, image_path):
        image = self.load_image(image_path)

        predictions = self.model.predict(
            image,
            verbose=0
        )[0]

        top_indices = np.argsort(predictions)[::-1]

        results = []

        for index in top_indices:
            results.append(
                (
                    self.class_names[index],
                    predictions[index] * 100
                )
            )

        return results

    def display_predictions(self, image_path):
        predictions = self.predict(image_path)

        print("\nVoici les prédictions :\n")

        for car_class, confidence in predictions:
            print(
                f"{car_class} : "
                f"{confidence:.2f} %"
            )


if __name__ == "__main__":
    predictor = CarPredictor()

    predictor.display_predictions(
        "images/f12.jpg"
    )