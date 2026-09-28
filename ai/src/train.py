import json
import numpy as np
import matplotlib.pyplot as plt
import tensorflow as tf

from tensorflow.keras import layers
from tensorflow.keras.applications import MobileNetV3Small


# ============================================================
# PARAMÈTRES
# ============================================================

IMG_SIZE = (224, 224)
BATCH_SIZE = 16
EPOCHS = 10

TRAIN_DIR = "dataset_small/train"
TEST_DIR = "dataset_small/test"


# ============================================================
# CHARGEMENT DES DONNÉES
# ============================================================

train_dataset = tf.keras.utils.image_dataset_from_directory(
    TRAIN_DIR,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=True
)

test_dataset = tf.keras.utils.image_dataset_from_directory(
    TEST_DIR,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=False
)

class_names = train_dataset.class_names
number_of_classes = len(class_names)

print("Classes détectées :", class_names)
print("Nombre de classes :", number_of_classes)


# ============================================================
# OPTIMISATION DU CHARGEMENT
# ============================================================

AUTOTUNE = tf.data.AUTOTUNE

train_dataset = train_dataset.prefetch(buffer_size=AUTOTUNE)
test_dataset = test_dataset.prefetch(buffer_size=AUTOTUNE)


# ============================================================
# DATA AUGMENTATION
# ============================================================

data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.05),
    layers.RandomZoom(0.1),
])


# ============================================================
# MOBILENETV3
# ============================================================

base_model = MobileNetV3Small(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet"
)

# MobileNet reste entièrement gelé.
base_model.trainable = False


# ============================================================
# CONSTRUCTION DU MODÈLE
# ============================================================

inputs = tf.keras.Input(shape=(224, 224, 3))

x = data_augmentation(inputs)

x = base_model(
    x,
    training=False
)

x = layers.GlobalAveragePooling2D()(x)

x = layers.Dropout(0.2)(x)

outputs = layers.Dense(
    number_of_classes,
    activation="softmax"
)(x)

model = tf.keras.Model(inputs, outputs)


# ============================================================
# CONFIGURATION
# ============================================================

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()


# ============================================================
# ENTRAÎNEMENT
# ============================================================

history = model.fit(
    train_dataset,
    epochs=EPOCHS,
    validation_data=test_dataset
)


# ============================================================
# ÉVALUATION
# ============================================================

test_loss, test_accuracy = model.evaluate(test_dataset)

print("\n========== RÉSULTATS ==========\n")

print(f"Test loss : {test_loss:.4f}")
print(f"Test accuracy : {test_accuracy * 100:.2f} %")


# ============================================================
# MATRICE DE CONFUSION
# ============================================================

y_true = np.concatenate([
    labels.numpy()
    for images, labels in test_dataset
])

predictions = model.predict(test_dataset)

y_pred = np.argmax(
    predictions,
    axis=1
)

cm = np.zeros(
    (number_of_classes, number_of_classes),
    dtype=int
)

for true_class, predicted_class in zip(y_true, y_pred):
    cm[true_class, predicted_class] += 1

print("\nMatrice de confusion :")
print(cm)


# ============================================================
# SAUVEGARDE
# ============================================================

with open("models/classes.json", "w") as f:
    json.dump(class_names, f)

model.save(
    "models/spotit_mobilenet.keras"
)

print("\nModèle sauvegardé.")


# ============================================================
# AFFICHAGE DE LA MATRICE
# ============================================================

fig, ax = plt.subplots(figsize=(10, 8))

ax.imshow(cm)

ax.set_xticks(np.arange(number_of_classes))
ax.set_yticks(np.arange(number_of_classes))

ax.set_xticklabels(
    class_names,
    rotation=45,
    ha="right"
)

ax.set_yticklabels(class_names)

ax.set_xlabel("Classe prédite")
ax.set_ylabel("Classe réelle")
ax.set_title("Matrice de confusion")

for i in range(number_of_classes):
    for j in range(number_of_classes):
        ax.text(
            j,
            i,
            cm[i, j],
            ha="center",
            va="center"
        )

plt.tight_layout()

plt.savefig(
    "models/confusion_matrix.png"
)

plt.show()