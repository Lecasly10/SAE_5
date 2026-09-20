import json
import tensorflow as tf
from tensorflow.keras import layers
from tensorflow.keras.applications import MobileNetV3Small

# Paramètres
IMG_SIZE = (224, 224)
BATCH_SIZE = 16
EPOCHS = 10

TRAIN_DIR = "dataset_small/train"
TEST_DIR = "dataset_small/test"

# Chargement des images d'entraînement
#indique quel dossier récuperer pour l'entrainement, met l'image dans un format que le modele peut comprendre, et indique la taille de l'image et le batch size
#ajoute le fait de mélanger pour mieux entrainer le modele
train_dataset = tf.keras.utils.image_dataset_from_directory(                                           
    TRAIN_DIR,                                                      
    image_size=IMG_SIZE,                                            
    batch_size=BATCH_SIZE,                                          
    shuffle=True
)

# Chargement des images de test
#ici pas besoin de mélanger les images de test, on veut juste voir comment le modèle se comporte sur des données qu'il n'a jamais vues
test_dataset = tf.keras.utils.image_dataset_from_directory(
    TEST_DIR,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=False
)

# On récupère les classes et le nombre de classes
class_names = train_dataset.class_names
number_of_classes = len(class_names)

print("Classes détectées :", class_names)
print("Nombre de classes :", number_of_classes)

# Optimisation du chargement des données
AUTOTUNE = tf.data.AUTOTUNE

train_dataset = train_dataset.prefetch(buffer_size=AUTOTUNE)
test_dataset = test_dataset.prefetch(buffer_size=AUTOTUNE)


# Data augmentation, on lui montre des images légèrement modifiées pour améliorer la robustesse du modèle exemple une image peut être retournée horizontalement, 
#ou légèrement zoomée, ou légèrement tournée
data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.05),
    layers.RandomZoom(0.1),
])


# Chargement de MobileNetV3 pré-entraîné 
# on utilise le modèle mobilenetv3small qui
base_model = MobileNetV3Small(
    input_shape=(224, 224, 3), #taille de l'image et nombre de canaux (3 pour RGB)
    include_top=False, #
    weights="imagenet" #chargement des poids pré-entraînés donc il connait déjà certaines caractéristiques des images.
)

# On gèle MobileNet pour le premier entraînement 
#on gèle le modèle pour ne pas modifier les poids pré-entraînés pendant l'entraînement, on veut juste utiliser les caractéristiques qu'il a déjà apprises.
base_model.trainable = False


# Construction de notre modèle
inputs = tf.keras.Input(shape=(224, 224, 3))

# on applique la data augmentation sur les images d'entrée pour améliorer la robustesse du modèle
x = data_augmentation(inputs)

x = base_model(
    x,
    training=False
)

#
x = layers.GlobalAveragePooling2D()(x)

# on évite le surapprentissage en ajoutant une couche de dropout qui va permettre de désactiver aléatoirement certaines connexions entre les neurones pendant l'entrainement,
# ce qui force le modèle à apprendre des choses précises et pas juste à mémoriser les images d'entraînement.
x = layers.Dropout(0.2)(x)

#on ajoute une couche dense avec le nombre de classes et une activation softmax pour obtenir les probabilités de chaque classe exemple : BMW Z4 : 0.8, Mazda MX5 : 0.2
outputs = layers.Dense(
    number_of_classes,
    activation="softmax"
)(x)

model = tf.keras.Model(inputs, outputs)


# Configuration de l'entraînement
model.compile( 
    optimizer="adam", #paramètre qui ajuste les poids du modèle pour minimiser la perte
    loss="sparse_categorical_crossentropy", # paramètre qui mesure la différence entre les prédictions du modèle et les vraies étiquettes
    metrics=["accuracy"] # permet d'afficher la précision du modèle pendant l'entraînement et l'évaluation
)

model.summary()

# Entraînement du modèle répète 10 
# 
# 444 images
#     ↓
# lots de 16
#     ↓
# MobileNet
#     ↓
# prédictions
#     ↓
# comparaison avec les vraies classes
#     ↓
# calcul de la loss
#     ↓
# Adam modifie les 3 462 paramètres
#     ↓
# prédictions légèrement meilleures

history = model.fit(
    train_dataset,
    epochs=EPOCHS,
    validation_data=test_dataset
)

with open("models/classes.json", "w") as f:
    json.dump(class_names, f)

#sauvegarde du modèle entraîné pour pouvoir le réutiliser plus tard sans avoir à le réentraîner
model.save("models/spotit_mobilenet.keras")