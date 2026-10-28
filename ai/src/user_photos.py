from io import BytesIO
from pathlib import Path

from PIL import Image, ImageOps

from src.config import USER_PHOTOS_DIR
from src.images import crop_to_box

# Seules les photos dont la voiture est sûre servent à l'entraînement
CONFIRMED = {"carId": {"$type": "string"}}
FIELDS = {"carId": 1, "image": 1}


def confirmed_photos(db):
    """Voitures ajoutées à une bibliothèque, puis voitures choisies par
    l'utilisateur quand l'IA hésitait, pour les comptes qui l'ont accepté."""
    users = [user["_id"] for user in db.users.find({"trainingConsent": True}, {"_id": 1})]
    query = {**CONFIRMED, "user": {"$in": users}}

    yield from db.cars.find(query, FIELDS)
    yield from db.trainingphotos.find(query, FIELDS)


def collect_user_photos(db, catalog, detector, destination=USER_PHOTOS_DIR):
    """Enregistre chaque nouvelle photo, recadrée sur la voiture comme lors de
    la reconnaissance, dans destination/<voiture>/. Les photos supprimées ou
    dont l'auteur a retiré son accord sont effacées. Renvoie le nombre ajouté."""
    destination = Path(destination)
    added = 0
    kept = set()

    for document in confirmed_photos(db):
        car_id = document["carId"]
        if car_id not in catalog:
            continue
        # Une photo enregistrée sous un ancien identifiant va à la voiture actuelle
        path = destination / catalog.get(car_id).id / f"{document['_id']}.jpg"
        kept.add(path)
        if path.exists():
            continue

        try:
            data = BytesIO(document["image"]["data"])
            image = ImageOps.exif_transpose(Image.open(data)).convert("RGB")
        except (OSError, Image.DecompressionBombError):
            kept.discard(path)
            continue

        box = detector.detect(image)

        path.parent.mkdir(parents=True, exist_ok=True)
        (crop_to_box(image, box) if box else image).save(path, "JPEG", quality=92)
        added += 1

    for path in destination.glob("*/*.jpg"):
        if path not in kept:
            path.unlink()

    return added
