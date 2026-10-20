import unittest

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

    def test_known_car_is_recognized(self):
        answer = post_image(self.client, "f12.jpg").get_json()

        self.assertTrue(answer["recognized"])
        self.assertEqual(answer["car"]["brand"], "Ferrari")
        self.assertEqual(answer["car"]["to_year"], 2015)
        self.assertIsNotNone(answer["box"])

    def test_car_outside_the_list_comes_with_suggestions(self):
        answer = post_image(self.client, "mx5.jpg").get_json()

        self.assertFalse(answer["recognized"])
        self.assertIsNone(answer["car"])
        self.assertEqual(len(answer["suggestions"]), 3)

    def test_empty_body_is_rejected(self):
        self.assertEqual(self.client.post("/predict", data=b"").status_code, 400)

    def test_unreadable_image_is_rejected(self):
        self.assertEqual(self.client.post("/predict", data=b"pas une image").status_code, 422)


if __name__ == "__main__":
    unittest.main()
