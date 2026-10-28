import json
from collections import Counter
from pathlib import Path

import numpy as np
import tensorflow as tf

from tensorflow.keras import layers
from tensorflow.keras.applications import EfficientNetV2B3

from src.config import (
    CLASSES_PATH,
    IMG_SIZE,
    METRICS_PATH,
    MODEL_PATH,
    OTHER_CLASS,
    SMALL_DATASET_DIR,
    THRESHOLDS_PATH,
)
from src.recognition import choose_thresholds


def use_gpu_if_available():
    """TensorFlow place les calculs sur la carte graphique s'il en trouve une.
    La mémoire est réservée au fur et à mesure plutôt que d'un seul coup."""
    gpus = tf.config.list_physical_devices("GPU")

    for gpu in gpus:
        tf.config.experimental.set_memory_growth(gpu, True)

    if gpus:
        print(f"Entraînement sur la carte graphique ({len(gpus)} trouvée(s))")
    else:
        print("Aucune carte graphique trouvée : entraînement sur le processeur")

    return bool(gpus)


def phone_like():
    """Photos de presse rendues plus proches de photos prises au téléphone :
    cadrage, angle, lumière, couleurs et netteté varient."""
    return tf.keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.05),
        layers.RandomZoom((-0.3, 0.2)),
        layers.RandomTranslation(0.1, 0.1),
        layers.RandomPerspective(factor=0.5, scale=0.2),
        layers.RandomBrightness(0.25),
        layers.RandomContrast(0.25),
        layers.RandomSaturation((0.3, 0.7)),
        layers.RandomHue(0.05),
        # Pas de version 16 bits du flou en précision mixte
        layers.RandomGaussianBlur(
            factor=0.5, kernel_size=5, sigma=(0.1, 2.0), dtype="float32"
        ),
    ])


class Sometimes(layers.Layer):
    """Applique `layer` à une partie des images seulement (`rate`) : les autres
    restent intactes, pour que l'IA apprenne aussi sur des photos nettes."""

    def __init__(self, layer, rate, **kwargs):
        super().__init__(**kwargs)
        self.layer = layer
        self.rate = rate

    def call(self, images, training=None):
        if not training:
            return images
        changed = tf.cast(self.layer(images, training=True), images.dtype)
        keep = tf.random.uniform([tf.shape(images)[0], 1, 1, 1]) >= self.rate
        return tf.where(keep, images, changed)


class CarTrainer:

    def __init__(
        self,
        train_dir=SMALL_DATASET_DIR / "train",
        test_dir=SMALL_DATASET_DIR / "test",
        img_size=IMG_SIZE,
        batch_size=32,
        head_epochs=6,
        fine_tune_epochs=40,
        validation_split=0.15,
        target_precision=0.9,
        augmented_share=0.5,
        seed=42
    ):
        self.train_dir = train_dir
        self.test_dir = test_dir

        self.img_size = img_size
        self.batch_size = batch_size
        self.head_epochs = head_epochs
        self.fine_tune_epochs = fine_tune_epochs
        self.validation_split = validation_split
        self.target_precision = target_precision
        self.augmented_share = augmented_share
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

    def create_network(self, base_weights, augment=True):
        """Le réseau d'entraînement transforme une partie des photos ; celui
        qui est sauvegardé (augment=False) les prend telles quelles."""
        base_model = EfficientNetV2B3(
            input_shape=(
                self.img_size[0],
                self.img_size[1],
                3
            ),
            include_top=False,
            weights=base_weights
        )

        base_model.trainable = False

        inputs = tf.keras.Input(
            shape=(
                self.img_size[0],
                self.img_size[1],
                3
            )
        )

        x = inputs
        if augment:
            x = Sometimes(phone_like(), self.augmented_share)(x)

        x = base_model(
            x,
            training=False
        )

        x = layers.GlobalAveragePooling2D()(x)
        x = layers.Dropout(0.4)(x)

        # En float32 même en précision mixte, pour des probabilités exactes.
        # Nommée pour retrouver ses poids dans le réseau sauvegardé.
        outputs = layers.Dense(
            self.number_of_classes,
            activation="softmax",
            dtype="float32",
            name="classifier"
        )(x)

        return tf.keras.Model(inputs, outputs), base_model

    def build_model(self):
        self.model, self.base_model = self.create_network(base_weights="imagenet")
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

    def unfreeze_base_model(self):
        self.base_model.trainable = True

        # Les couches de normalisation restent figées pour garder leurs statistiques.
        for layer in self.base_model.layers:
            if isinstance(layer, layers.BatchNormalization):
                layer.trainable = False

    def train(self):
        print("\n========== ENTRAÎNEMENT : NOUVELLE TÊTE ==========\n")

        self.fit(self.head_epochs, patience=3)

        print("\n========== ENTRAÎNEMENT : AFFINAGE ==========\n")

        self.unfreeze_base_model()
        self.compile(learning_rate=5e-5)

        return self.fit(self.fine_tune_epochs, patience=6)

    def evaluate(self):
        results = self.model.evaluate(
            self.test_dataset,
            return_dict=True
        )

        print("\n========== RÉSULTATS ==========\n")

        print(f"Test loss : {results['loss']:.4f}")
        print(f"Test accuracy : {results['accuracy'] * 100:.2f} %")
        print(f"Test top-3 : {results['top3'] * 100:.2f} %")

        return results["accuracy"]

    def is_better_than_current(self, accuracy):
        """Compare au modèle actuel quand il connaît les mêmes voitures : sinon
        les deux scores ne sont pas comparables et le nouveau modèle est gardé."""
        try:
            with open(CLASSES_PATH, encoding="utf-8") as file:
                current_classes = json.load(file)
            with open(METRICS_PATH, encoding="utf-8") as file:
                current_accuracy = json.load(file)["accuracy"]
        except FileNotFoundError:
            return True

        if current_classes != self.class_names:
            return True

        print(f"Modèle actuel : {current_accuracy * 100:.2f} %, nouveau : {accuracy * 100:.2f} %")
        return accuracy >= current_accuracy

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

        # Copie en float32, sans l'état de l'optimiseur : fichier 3 fois plus
        # petit, et le serveur calcule sur le processeur.
        training_policy = tf.keras.mixed_precision.global_policy()
        tf.keras.mixed_precision.set_global_policy("float32")
        inference_model, inference_base = self.create_network(base_weights=None, augment=False)
        tf.keras.mixed_precision.set_global_policy(training_policy)

        inference_base.set_weights(self.base_model.get_weights())
        inference_model.get_layer("classifier").set_weights(
            self.model.get_layer("classifier").get_weights()
        )
        inference_model.save(MODEL_PATH)

        print(f"\nModèle sauvegardé dans {MODEL_PATH}")

    def run(self):
        """Renvoie True si le nouveau modèle remplace l'ancien."""
        if use_gpu_if_available():
            # Calculs en 16 bits sur la carte graphique : environ deux fois plus rapide
            tf.keras.mixed_precision.set_global_policy("mixed_float16")
        tf.keras.utils.set_random_seed(self.seed)

        self.load_datasets()
        self.build_model()
        self.train()

        if not self.is_better_than_current(self.evaluate()):
            print("\nLe nouveau modèle est moins bon : l'ancien est gardé.")
            return False

        self.save_model()
        self.calibrate()
        return True
