from pathlib import Path

AI_DIR = Path(__file__).resolve().parent.parent

MODELS_DIR = AI_DIR / "models"
MODEL_PATH = MODELS_DIR / "spotit_classifier.keras"
CLASSES_PATH = MODELS_DIR / "classes.json"
CARS_PATH = MODELS_DIR / "cars.json"
THRESHOLDS_PATH = MODELS_DIR / "recognition.json"
DETECTOR_PATH = MODELS_DIR / "detector" / "detect.tflite"
EVALUATION_DIR = MODELS_DIR / "evaluation"
METRICS_PATH = EVALUATION_DIR / "metrics.json"

DATASET_DIR = AI_DIR / "dataset"
SMALL_DATASET_DIR = AI_DIR / "dataset_small"
# Photos confirmées dans l'application, récupérées par `main.py collect`
USER_PHOTOS_DIR = AI_DIR / "dataset_user"
SAMPLE_IMAGE = AI_DIR / "images" / "f12.jpg"

IMG_SIZE = (300, 300)

# Base MongoDB partagée avec le backend
DB_NAME = "spotit"

# Classe qui regroupe toutes les voitures absentes de cars.json
OTHER_CLASS = "autre"
