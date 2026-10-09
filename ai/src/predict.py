import json
import numpy as np
import tensorflow as tf


# ============================================================
# CHEMINS
# ============================================================

MODEL_PATH = "models/spotit_mobilenet.keras"
CLASSES_PATH = "models/classes.json"
IMAGE_PATH = "images/f12.jpg"


# ============================================================
# CHARGEMENT DU MODÈLE
# ============================================================

# Chargement du modèle précédemment entraîné avec train.py.
model = tf.keras.models.load_model(MODEL_PATH)


# Chargement des noms des classes.
with open(CLASSES_PATH, "r") as f:
    class_names = json.load(f)


# ============================================================
# CHARGEMENT DE L'IMAGE
# ============================================================

# Chargement et redimensionnement de l'image
# dans le même format que celui utilisé pendant l'entraînement.
image = tf.keras.utils.load_img(
    IMAGE_PATH,
    target_size=(224, 224)
)


# Transformation de l'image en tableau de nombres.
image_array = tf.keras.utils.img_to_array(image)


# Le modèle attend un batch d'images.
#
# Une image seule :
# (224, 224, 3)
#
# devient un batch contenant une image :
# (1, 224, 224, 3)
image_array = np.expand_dims(
    image_array,
    axis=0
)


# ============================================================
# PRÉDICTION
# ============================================================

predictions = model.predict(image_array)


# Classement des classes de la probabilité
# la plus élevée à la plus faible.
top_indices = np.argsort(
    predictions[0]
)[::-1]


# ============================================================
# AFFICHAGE
# ============================================================

print("\nVoici les prédictions :\n")

for index in top_indices:

    car_class = class_names[index]

    confidence = predictions[0][index] * 100

    print(
        f"{car_class} : "
        f"{confidence:.2f} %"
    )