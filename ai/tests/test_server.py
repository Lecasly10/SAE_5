import unittest

from src.catalog import CarCatalog
from src.config import AI_DIR

# Charge le vrai modèle : ce test est un peu plus long que les autres
from server import app


def post_image(client, name):
    with open(AI_DIR / "images" / name, "rb") as file:
        return client.post("/predict", data=file.read())


class ServerTest(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()

    def test_health(self):
        self.assertEqual(self.client.get("/health").get_json(), {"status": "ok"})

    def test_lists_every_car_sorted_by_brand(self):
        cars = self.client.get("/cars").get_json()

        self.assertEqual(len(cars), len(list(CarCatalog.load())))
        self.assertEqual(cars, sorted(cars, key=lambda car: (car["brand"], car["model"], car["from_year"])))
        self.assertIn({"id": "ferrari_f12_berlinetta", "brand": "Ferrari", "model": "F12 Berlinetta",
                       "from_year": 2012, "to_year": 2015}, cars)

    def test_suggestions_are_distinct_cars(self):
        suggestions = post_image(self.client, "z4.jpg").get_json()["suggestions"]
        ids = [car["id"] for car in suggestions]

        self.assertEqual(len(ids), len(set(ids)))

    def test_known_car_is_recognized(self):
        answer = post_image(self.client, "f12.jpg").get_json()

        self.assertTrue(answer["recognized"])
        self.assertEqual(answer["car"]["brand"], "Ferrari")
        self.assertEqual(answer["car"]["to_year"], 2015)
        self.assertIsNotNone(answer["box"])

    def test_unsure_answer_comes_with_suggestions(self):
        answer = post_image(self.client, "mx5.jpg").get_json()

        self.assertFalse(answer["recognized"])
        self.assertIsNone(answer["car"])
        self.assertEqual(len(answer["suggestions"]), 5)

    def test_empty_body_is_rejected(self):
        self.assertEqual(self.client.post("/predict", data=b"").status_code, 400)

    def test_unreadable_image_is_rejected(self):
        with open(AI_DIR / "images" / "f12.jpg", "rb") as file:
            cut = file.read()[:2000]

        for data in (b"pas une image", cut):
            self.assertEqual(self.client.post("/predict", data=data).status_code, 422)

    def test_huge_upload_is_rejected(self):
        self.assertEqual(self.client.post("/predict", data=b"x" * (9 * 1024 * 1024)).status_code, 413)


if __name__ == "__main__":
    unittest.main()
