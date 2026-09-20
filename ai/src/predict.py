import tensorflow as tf
import json
import numpy as np

# Chemins
MODEL_PATH = "models/spotit_mobilenet.keras"
CLASSES_PATH = "models/classes.json"
IMAGE_PATH = "images/mx5.jpg"

# Chargement du modèle entraîné
model = tf.keras.models.load_model(MODEL_PATH)

# Chargement des noms des classes
with open(CLASSES_PATH, "r") as f:
    class_names = json.load(f)

# Chargement de l'image
image = tf.keras.utils.load_img(
    IMAGE_PATH,
    target_size=(224, 224)
)

# Transformation de l'image en tableau de nombres
image_array = tf.keras.utils.img_to_array(image)

# Ajout d'une dimension pour créer un batch de 1 image
image_array = np.expand_dims(image_array, axis=0)

# Prédiction
predictions = model.predict(image_array)

# Classe ayant la probabilité la plus élevée
# Récupération des 3 meilleures prédictions
top_indices = np.argsort(predictions[0])[-len(class_names):][::-1]

print("\nVoici les prédictions :")

for index in top_indices:
    car_class = class_names[index]
    confidence = predictions[0][index] * 100

    print(f"{car_class} : {confidence:.2f} %")

