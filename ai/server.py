from io import BytesIO
from pathlib import Path

from flask import Flask, jsonify, request
from PIL import Image, ImageOps, UnidentifiedImageError

from src.detector import CarDetector
from src.predictor import CarPredictor

AI_DIR = Path(__file__).resolve().parent

app = Flask(__name__)
predictor = CarPredictor(
    model_path=AI_DIR / "models/spotit_mobilenet.keras",
    classes_path=AI_DIR / "models/classes.json",
)
detector = CarDetector(model_path=AI_DIR / "models/detector/detect.tflite")


@app.post("/predict")
def predict():
    data = request.get_data()

    if not data:
        return jsonify(error="Image manquante"), 400

    try:
        image = ImageOps.exif_transpose(Image.open(BytesIO(data)))
        label, confidence = predictor.predict(BytesIO(data))[0]
    except UnidentifiedImageError:
        return jsonify(error="Image illisible"), 422

    return jsonify(
        label=label,
        confidence=round(float(confidence), 2),
        box=detector.detect(image),
    )


if __name__ == "__main__":
    app.run(port=5000)
