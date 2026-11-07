import csv
import tempfile
import unittest
import zipfile
from io import BytesIO
from pathlib import Path
from unittest import mock

from PIL import Image

from src.extra_datasets import ExtraDataset, dvm_label, vmmr_label


def jpeg(size=(200, 100)):
    buffer = BytesIO()
    Image.new("RGB", size, "red").save(buffer, "JPEG")
    return buffer.getvalue()


class FakeDetector:

    def detect(self, image):
        return {"x": 0.25, "y": 0.2, "width": 0.5, "height": 0.6}


class LabelTest(unittest.TestCase):

    def test_dvm_names(self):
        self.assertEqual(
            dvm_label("resized_DVM/Land Rover/Range Rover/2017/Black/a$$b$$image_1.jpg"),
            ("Land Rover", "Range Rover", 2017),
        )
        self.assertIsNone(dvm_label("resized_DVM/Abarth/124 Spider/"))

    def test_vmmr_names(self):
        self.assertEqual(vmmr_label("VMMRdb/honda_civic_2002/1.jpg"), ("honda", "civic", 2002))
        self.assertEqual(
            vmmr_label("VMMRdb/mercedes benz_c230_2003/1.jpg"), ("mercedes benz", "c230", 2003),
        )
        self.assertEqual(vmmr_label("VMMRdb/land rover_range_rover_2005/1.jpg"),
                         ("land rover", "range rover", 2005))
        self.assertIsNone(vmmr_label("VMMRdb/readme.jpg"))


class ExtraDatasetTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.archive = self.root / "VMMRdb.zip"
        self.destination = self.root / "extra"

        printer = mock.patch("builtins.print")
        printer.start()
        self.addCleanup(printer.stop)

        with zipfile.ZipFile(self.archive, "w") as archive:
            for year, count in ((2002, 8), (2004, 7)):
                for index in range(count):
                    archive.writestr(f"VMMRdb/honda_civic_{year}/{index}.jpg", jpeg())
            archive.writestr("VMMRdb/kia_rio_2010/0.jpg", jpeg())
            archive.writestr("VMMRdb/kia_rio_2010/1.jpg", b"pas une image")
            archive.writestr("VMMRdb/notes.txt", b"x")

    def convert(self, **options):
        return ExtraDataset("VMMR", self.archive, vmmr_label, self.destination, **options).convert()

    def images(self, split, folder):
        return sorted((self.destination / split / folder).glob("*.jpg"))

    def test_one_folder_per_model_with_every_year(self):
        rows = self.convert(max_images=10, test_share=0.2)

        self.assertEqual(rows, [
            {"folder": "VMMR_honda_civic", "brand": "honda", "model": "civic",
             "from_year": 2002, "to_year": 2004},
            {"folder": "VMMR_kia_rio", "brand": "kia", "model": "rio",
             "from_year": 2010, "to_year": 2010},
        ])
        self.assertEqual(len(self.images("train", "VMMR_honda_civic")), 8)
        self.assertEqual(len(self.images("test", "VMMR_honda_civic")), 2)
        with open(self.destination / "VMMR.csv", encoding="utf-8") as file:
            self.assertEqual(len(list(csv.DictReader(file))), 2)

    def test_skips_broken_images(self):
        self.convert()

        self.assertEqual(len(self.images("train", "VMMR_kia_rio")), 1)

    def test_crops_the_car_and_shrinks_big_photos(self):
        self.convert(detector=FakeDetector(), max_size=50)

        with Image.open(self.images("train", "VMMR_kia_rio")[0]) as image:
            self.assertEqual(image.size, (50, 30))

    def test_converted_models_are_not_redone(self):
        self.convert()
        for image in self.images("train", "VMMR_honda_civic"):
            image.unlink()

        self.convert()

        self.assertEqual(self.images("train", "VMMR_honda_civic"), [])

    def test_interrupted_models_are_redone(self):
        (self.destination / "train" / "VMMR_kia_rio.part").mkdir(parents=True)

        self.convert()

        self.assertFalse((self.destination / "train" / "VMMR_kia_rio.part").exists())
        self.assertEqual(len(self.images("train", "VMMR_kia_rio")), 1)


if __name__ == "__main__":
    unittest.main()
