import json
from collections import Counter
from pathlib import Path

import numpy as np
import tensorflow as tf

from tensorflow.keras import layers
from tensorflow.keras.applications import MobileNetV3Large

from src.config import (
    CLASSES_PATH,
    IMG_SIZE,
    MODEL_PATH,
    OTHER_CLASS,
    SMALL_DATASET_DIR,
    THRESHOLDS_PATH,
)
from src.recognition import choose_thresholds


class MobileNetTrainer:

    def __init__(
        self,
        train_dir=SMALL_DATASET_DIR / "train",
        test_dir=SMALL_DATASET_DIR / "test",
        img_size=IMG_SIZE,
        batch_size=32,
        head_epochs=10,
        fine_tune_epochs=15,
        fine_tune_layers=60,
        validation_split=0.15,
        target_precision=0.9,
        seed=42
    ):
        self.train_dir = train_dir
        self.test_dir = test_dir

        self.img_size = img_size
        self.batch_size = batch_size
        self.head_epochs = head_epochs
        self.fine_tune_epochs = fine_tune_epochs
        self.fine_tune_layers = fine_tune_layers
        self.validation_split = validation_split
        self.target_precision = target_precision
        self.seed = seed

        self.train_dataset = None
        self.validation_dataset = None
        self.test_dataset = None

        self.class_names = []
        self.number_of_classes = 0
        self.class_weights = {}

        self.base_model = None
        self.model = None

    def load_datasets(self):
        options = dict(
            image_size=self.img_size,
            batch_size=self.batch_size,
            label_mode="categorical",
            validation_split=self.validation_split,
            seed=self.seed
        )

        self.train_dataset = (
            tf.keras.utils.image_dataset_from_directory(
                str(self.train_dir),
                subset="training",
                shuffle=True,
                **options
            )
        )

        self.validation_dataset = (
            tf.keras.utils.image_dataset_from_directory(
                str(self.train_dir),
                subset="validation",
                shuffle=True,
                **options
            )
        )

        self.test_dataset = (
            tf.keras.utils.image_dataset_from_directory(
                str(self.test_dir),
                class_names=self.train_dataset.class_names,
                image_size=self.img_size,
                batch_size=self.batch_size,
                label_mode="categorical",
                shuffle=False
            )
        )

        self.class_names = self.train_dataset.class_names
        self.number_of_classes = len(self.class_names)
        self.class_weights = self.compute_class_weights()

        print("\nNombre de classes :", self.number_of_classes)

        autotune = tf.data.AUTOTUNE

        self.train_dataset = self.train_dataset.prefetch(
            buffer_size=autotune
        )

        self.validation_dataset = self.validation_dataset.prefetch(
            buffer_size=autotune
        )

        self.test_dataset = self.test_dataset.prefetch(
            buffer_size=autotune
        )

    def compute_class_weights(self):
        counts = Counter(
            self.class_names.index(Path(path).parent.name)
            for path in self.train_dataset.file_paths
        )
        total = sum(counts.values())

        return {
            index: total / (self.number_of_classes * counts[index])
            for index in range(self.number_of_classes)
        }

    def build_model(self):
        data_augmentation = tf.keras.Sequential([
            layers.RandomFlip("horizontal"),
            layers.RandomRotation(0.05),
            layers.RandomZoom(0.15),
            layers.RandomTranslation(0.1, 0.1),
            layers.RandomContrast(0.15),
        ])

        self.base_model = MobileNetV3Large(
            input_shape=(
                self.img_size[0],
                self.img_size[1],
                3
            ),
            include_top=False,
            weights="imagenet"
        )

        self.base_model.trainable = False

        inputs = tf.keras.Input(
            shape=(
                self.img_size[0],
                self.img_size[1],
                3
            )
        )

        x = data_augmentation(inputs)

        x = self.base_model(
            x,
            training=False
        )

        x = layers.GlobalAveragePooling2D()(x)
        x = layers.Dropout(0.3)(x)

        outputs = layers.Dense(
            self.number_of_classes,
            activation="softmax"
        )(x)

        self.model = tf.keras.Model(
            inputs,
            outputs
        )

        self.compile(learning_rate=1e-3)

    def compile(self, learning_rate):
        self.model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate),
            loss=tf.keras.losses.CategoricalCrossentropy(
                label_smoothing=0.1
            ),
            metrics=[
                "accuracy",
                tf.keras.metrics.TopKCategoricalAccuracy(
                    k=3,
                    name="top3"
                )
            ]
        )

    def fit(self, epochs, patience):
        return self.model.fit(
            self.train_dataset,
            epochs=epochs,
            validation_data=self.validation_dataset,
            class_weight=self.class_weights,
            callbacks=[
                tf.keras.callbacks.EarlyStopping(
                    monitor="val_loss",
                    patience=patience,
                    restore_best_weights=True
                ),
                tf.keras.callbacks.ReduceLROnPlateau(
                    monitor="val_loss",
                    factor=0.3,
                    patience=2
                )
            ]
        )

    def unfreeze_top_layers(self):
        self.base_model.trainable = True

        for layer in self.base_model.layers[:-self.fine_tune_layers]:
            layer.trainable = False

        # Les couches de normalisation restent figées pour garder leurs statistiques.
        for layer in self.base_model.layers:
            if isinstance(layer, layers.BatchNormalization):
                layer.trainable = False

    def train(self):
        print("\n========== ENTRAÎNEMENT : NOUVELLE TÊTE ==========\n")

        self.fit(self.head_epochs, patience=3)

        print("\n========== ENTRAÎNEMENT : AFFINAGE ==========\n")

        self.unfreeze_top_layers()
        self.compile(learning_rate=1e-4)

        return self.fit(self.fine_tune_epochs, patience=4)

    def evaluate(self):
        results = self.model.evaluate(
            self.test_dataset,
            return_dict=True
        )

        print("\n========== RÉSULTATS ==========\n")

        print(f"Test loss : {results['loss']:.4f}")
        print(f"Test accuracy : {results['accuracy'] * 100:.2f} %")
        print(f"Test top-3 : {results['top3'] * 100:.2f} %")

    def calibrate(self):
        score_batches, label_batches = [], []

        # Une seule passe : le jeu de validation est mélangé, scores et labels
        # doivent venir des mêmes images.
        for images, batch_labels in self.validation_dataset:
            score_batches.append(self.model(images, training=False).numpy())
            label_batches.append(np.argmax(batch_labels.numpy(), axis=1))

        scores = np.concatenate(score_batches)
        labels = np.concatenate(label_batches)

        thresholds, stats = choose_thresholds(
            scores,
            labels,
            other_index=self.class_names.index(OTHER_CLASS),
            target_precision=self.target_precision
        )

        print("\n========== SEUILS « NON RECONNU » ==========\n")
        print(thresholds)
        print(stats)

        thresholds.save(THRESHOLDS_PATH, stats)

    def save_model(self):
        with open(CLASSES_PATH, "w", encoding="utf-8") as file:
            json.dump(self.class_names, file, indent=4)

        self.model.save(MODEL_PATH)

        print(f"\nModèle sauvegardé dans {MODEL_PATH}")

    def run(self):
        tf.keras.utils.set_random_seed(self.seed)

        self.load_datasets()
        self.build_model()
        self.train()
        self.evaluate()
        self.calibrate()
        self.save_model()
