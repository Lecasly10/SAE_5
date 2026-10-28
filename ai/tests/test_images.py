import unittest

from PIL import Image

from src.images import crop_to_box


class CropToBoxTest(unittest.TestCase):

    def setUp(self):
        self.image = Image.new("RGB", (200, 100))

    def test_keeps_the_car_with_a_margin(self):
        box = {"x": 0.25, "y": 0.2, "width": 0.5, "height": 0.6}

        self.assertEqual(crop_to_box(self.image, box).size, (120, 72))

    def test_stays_inside_the_photo(self):
        box = {"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0}

        self.assertEqual(crop_to_box(self.image, box).size, (200, 100))


if __name__ == "__main__":
    unittest.main()
