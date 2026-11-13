import os
from pathlib import Path

AI_DIR = Path(__file__).resolve().parent.parent

MODELS_DIR = AI_DIR / "models"
MODEL_PATH = MODELS_DIR / "spotit_classifier.keras"
CLASSES_PATH = MODELS_DIR / "classes.json"
CARS_PATH = MODELS_DIR / "cars.json"
THRESHOLDS_PATH = MODELS_DIR / "recognition.json"
# Prix neuf et fréquence de chaque voiture, faits par `main.py market`
MARKET_PATH = MODELS_DIR / "market.json"
DETECTOR_PATH = MODELS_DIR / "detector" / "detect.tflite"
EVALUATION_DIR = MODELS_DIR / "evaluation"
METRICS_PATH = EVALUATION_DIR / "metrics.json"

DATASET_DIR = AI_DIR / "dataset"
# Les gros fichiers peuvent aller sur un autre disque (voir docker-compose.yml)
DOWNLOADS_DIR = Path(os.environ.get("SPOTIT_DOWNLOADS_DIR", AI_DIR / "downloads"))
# DVM-Car et VMMRdb convertis par `main.py extra`, à côté du grand dataset
EXTRA_DATASET_DIR = Path(os.environ.get("SPOTIT_EXTRA_DIR", AI_DIR / "dataset_extra"))
SMALL_DATASET_DIR = Path(os.environ.get("SPOTIT_SMALL_DIR", AI_DIR / "dataset_small"))
# Sauvegarde à chaque tour, pour reprendre un entraînement interrompu
TRAINING_BACKUP_DIR = SMALL_DATASET_DIR.parent / "training_backup"
# Photos confirmées dans l'application, récupérées par `main.py collect`
USER_PHOTOS_DIR = AI_DIR / "dataset_user"
SAMPLE_IMAGE = AI_DIR / "images" / "f12.jpg"

IMG_SIZE = (300, 300)

# Base MongoDB partagée avec le backend
DB_NAME = "spotit"

# Classe qui regroupe toutes les voitures absentes de cars.json
OTHER_CLASS = "autre"
