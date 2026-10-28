import tempfile
import unittest
from io import BytesIO
from pathlib import Path

from PIL import Image

from src.catalog import Car, CarCatalog
from src.user_photos import collect_user_photos

ALICE, BOB = "alice", "bob"


def jpeg(size=(200, 100)):
    buffer = BytesIO()
    Image.new("RGB", size, "red").save(buffer, "JPEG")
    return buffer.getvalue()


def photo(_id, car_id="clio", user=ALICE, data=None):
    return {"_id": _id, "carId": car_id, "user": user, "image": {"data": data or jpeg()}}


class FakeCollection:
    """Comprend seulement les requêtes utilisées par user_photos."""

    def __init__(self, documents):
        self.documents = documents

    def find(self, query, fields):
        if "trainingConsent" in query:
            return iter(d for d in self.documents if d["trainingConsent"])
        users = query["user"]["$in"]
        return iter(d for d in self.documents if d["user"] in users and isinstance(d["carId"], str))


class FakeDb:

    def __init__(self, cars, trainingphotos, consenting):
        self.users = FakeCollection([
            {"_id": user, "trainingConsent": user in consenting} for user in (ALICE, BOB)
        ])
        self.cars = FakeCollection(cars)
        self.trainingphotos = FakeCollection(trainingphotos)


class FakeDetector:

    def __init__(self, box):
        self.box = box

    def detect(self, image):
        return self.box


class CollectUserPhotosTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.destination = Path(self.tmp.name)
        self.catalog = CarCatalog([Car("clio", "Renault", "Clio", 2019, None, ("x",))])

    def collect(self, cars=(), corrections=(), consenting=(ALICE,), box=None):
        db = FakeDb(list(cars), list(corrections), consenting)
        return collect_user_photos(db, self.catalog, FakeDetector(box), self.destination)

    def saved(self):
        return sorted(path.name for path in self.destination.glob("*/*.jpg"))

    def test_saves_library_cars_and_corrections_of_consenting_users(self):
        added = self.collect(
            cars=[photo("a"), photo("c", user=BOB), photo("d", car_id=None)],
            corrections=[photo("b")],
        )

        self.assertEqual(added, 2)
        self.assertEqual(self.saved(), ["a.jpg", "b.jpg"])

    def test_crops_the_car_like_the_server(self):
        box = {"x": 0.25, "y": 0.2, "width": 0.5, "height": 0.6}
        self.collect(cars=[photo("a")], box=box)

        with Image.open(self.destination / "clio" / "a.jpg") as image:
            self.assertEqual(image.size, (120, 72))

    def test_skips_unknown_cars_broken_images_and_known_photos(self):
        (self.destination / "clio").mkdir()
        (self.destination / "clio" / "old.jpg").write_bytes(jpeg())

        added = self.collect(cars=[
            photo("old"),
            photo("c", car_id="inconnue"),
            photo("d", data=b"pas une image"),
            photo("e", data=jpeg()[:200]),
        ])

        self.assertEqual(added, 0)
        self.assertEqual(self.saved(), ["old.jpg"])

    def test_forgets_photos_when_consent_is_withdrawn(self):
        self.collect(cars=[photo("a")])
        self.collect(cars=[photo("a")], consenting=())

        self.assertEqual(self.saved(), [])


if __name__ == "__main__":
    unittest.main()
