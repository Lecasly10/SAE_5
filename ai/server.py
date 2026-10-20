from io import BytesIO

from flask import Flask, jsonify, request
from PIL import Image, ImageOps, UnidentifiedImageError

from src.catalog import CarCatalog
from src.config import OTHER_CLASS
from src.detector import CarDetector
from src.predictor import CarPredictor
from src.recognition import Thresholds, decide

MAX_SUGGESTIONS = 3

app = Flask(__name__)
predictor = CarPredictor()
detector = CarDetector()
catalog = CarCatalog.load()
thresholds = Thresholds.load()

unknown_classes = set(predictor.class_names) - set(catalog.by_id) - {OTHER_CLASS}
if unknown_classes:
    raise RuntimeError(f"Classes absentes de cars.json : {sorted(unknown_classes)}")


def describe(label, confidence):
    return {**catalog.get(label).to_dict(), "confidence": round(float(confidence), 2)}


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.post("/predict")
def predict():
    data = request.get_data()

    if not data:
        return jsonify(error="Image manquante"), 400

    try:
        image = ImageOps.exif_transpose(Image.open(BytesIO(data)))
        ranked = predictor.predict(image)
    except UnidentifiedImageError:
        return jsonify(error="Image illisible"), 422

    box = detector.detect(image)
    decision = decide(ranked, thresholds, has_box=box is not None)

    return jsonify(
        recognized=decision.recognized,
        reason=decision.reason,
        confidence=round(float(ranked[0][1]), 2),
        car=catalog.get(ranked[0][0]).to_dict() if decision.recognized else None,
        suggestions=[
            describe(label, confidence)
            for label, confidence in ranked
            if label != OTHER_CLASS
        ][:MAX_SUGGESTIONS],
        box=box,
    )


if __name__ == "__main__":
    app.run(port=5000)
