import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf

from tensorflow.keras import layers
from tensorflow.keras.applications import MobileNetV3Small


class MobileNetTrainer:

    def __init__(
        self,
        train_dir="dataset_small/train",
        test_dir="dataset_small/test",
        models_dir="models",
        img_size=(224, 224),
        batch_size=16,
        epochs=10
    ):
        self.train_dir = train_dir
        self.test_dir = test_dir
        self.models_dir = Path(models_dir)

        self.img_size = img_size
        self.batch_size = batch_size
        self.epochs = epochs

        self.train_dataset = None
        self.test_dataset = None

        self.class_names = []
        self.number_of_classes = 0

        self.model = None

    def load_datasets(self):
        self.train_dataset = (
            tf.keras.utils.image_dataset_from_directory(
                self.train_dir,
                image_size=self.img_size,
                batch_size=self.batch_size,
                shuffle=True
            )
        )

        self.test_dataset = (
            tf.keras.utils.image_dataset_from_directory(
                self.test_dir,
                image_size=self.img_size,
                batch_size=self.batch_size,
                shuffle=False
            )
        )

        self.class_names = self.train_dataset.class_names
        self.number_of_classes = len(self.class_names)

        print("\nClasses détectées :", self.class_names)
        print("Nombre de classes :", self.number_of_classes)

        autotune = tf.data.AUTOTUNE

        self.train_dataset = self.train_dataset.prefetch(
            buffer_size=autotune
        )

        self.test_dataset = self.test_dataset.prefetch(
            buffer_size=autotune
        )

    def build_model(self):
        data_augmentation = tf.keras.Sequential([
            layers.RandomFlip("horizontal"),
            layers.RandomRotation(0.05),
            layers.RandomZoom(0.1),
        ])

        base_model = MobileNetV3Small(
            input_shape=(
                self.img_size[0],
                self.img_size[1],
                3
            ),
            include_top=False,
            weights="imagenet"
        )

        base_model.trainable = False

        inputs = tf.keras.Input(
            shape=(
                self.img_size[0],
                self.img_size[1],
                3
            )
        )

        x = data_augmentation(inputs)

        x = base_model(
            x,
            training=False
        )

        x = layers.GlobalAveragePooling2D()(x)
        x = layers.Dropout(0.2)(x)

        outputs = layers.Dense(
            self.number_of_classes,
            activation="softmax"
        )(x)

        self.model = tf.keras.Model(
            inputs,
            outputs
        )

        self.model.compile(
            optimizer="adam",
            loss="sparse_categorical_crossentropy",
            metrics=["accuracy"]
        )

        self.model.summary()

    def train(self):
        print("\n========== ENTRAÎNEMENT ==========\n")

        return self.model.fit(
            self.train_dataset,
            epochs=self.epochs,
            validation_data=self.test_dataset
        )

    def evaluate(self):
        test_loss, test_accuracy = self.model.evaluate(
            self.test_dataset
        )

        print("\n========== RÉSULTATS ==========\n")

        print(f"Test loss : {test_loss:.4f}")
        print(
            f"Test accuracy : "
            f"{test_accuracy * 100:.2f} %"
        )

    def create_confusion_matrix(self):
        y_true = np.concatenate([
            labels.numpy()
            for _, labels in self.test_dataset
        ])

        predictions = self.model.predict(
            self.test_dataset
        )

        y_pred = np.argmax(
            predictions,
            axis=1
        )

        matrix = np.zeros(
            (
                self.number_of_classes,
                self.number_of_classes
            ),
            dtype=int
        )

        for true_class, predicted_class in zip(
            y_true,
            y_pred
        ):
            matrix[
                true_class,
                predicted_class
            ] += 1

        return matrix

    def save_confusion_matrix(self, matrix):
        fig, ax = plt.subplots(
            figsize=(10, 8)
        )

        ax.imshow(matrix)

        ax.set_xticks(
            np.arange(self.number_of_classes)
        )

        ax.set_yticks(
            np.arange(self.number_of_classes)
        )

        ax.set_xticklabels(
            self.class_names,
            rotation=45,
            ha="right"
        )

        ax.set_yticklabels(
            self.class_names
        )

        ax.set_xlabel("Classe prédite")
        ax.set_ylabel("Classe réelle")
        ax.set_title("Matrice de confusion")

        for i in range(self.number_of_classes):
            for j in range(self.number_of_classes):
                ax.text(
                    j,
                    i,
                    matrix[i, j],
                    ha="center",
                    va="center"
                )

        plt.tight_layout()

        plt.savefig(
            self.models_dir / "confusion_matrix.png"
        )

        plt.show()

    def save_model(self):
        self.models_dir.mkdir(
            parents=True,
            exist_ok=True
        )

        classes_path = (
            self.models_dir / "classes.json"
        )

        model_path = (
            self.models_dir /
            "spotit_mobilenet.keras"
        )

        with open(
            classes_path,
            "w",
            encoding="utf-8"
        ) as file:
            json.dump(
                self.class_names,
                file,
                indent=4
            )

        self.model.save(model_path)

        print(
            f"\n✅ Modèle sauvegardé dans "
            f"{model_path}"
        )

    def run(self):
        self.models_dir.mkdir(
            parents=True,
            exist_ok=True
        )

        self.load_datasets()
        self.build_model()
        self.train()
        self.evaluate()

        confusion_matrix = (
            self.create_confusion_matrix()
        )

        print("\nMatrice de confusion :")
        print(confusion_matrix)

        self.save_model()

        self.save_confusion_matrix(
            confusion_matrix
        )


if __name__ == "__main__":
    trainer = MobileNetTrainer()
    trainer.run()