import tensorflow as tf
from tensorflow.keras.applications import MobileNetV3Small

model = MobileNetV3Small(
    weights="imagenet"
)

print("MobileNetV3 chargé !")
model.summary()