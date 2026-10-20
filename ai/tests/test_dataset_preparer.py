import tempfile
import unittest
from pathlib import Path
from unittest import mock

from src.catalog import Car, CarCatalog
from src.config import OTHER_CLASS
from src.dataset_preparer import DatasetPreparer, family


def make_images(root, split, folder, count):
    target = Path(root) / split / folder
    target.mkdir(parents=True, exist_ok=True)
    for index in range(count):
        (target / f"{folder}_{index}.jpg").write_bytes(b"x")


def count_images(root, split, folder):
    path = Path(root) / split / folder
    return len(list(path.glob("*.jpg"))) if path.exists() else 0


class DatasetPreparerTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.source = root / "source"
        self.destination = root / "destination"
        self.addCleanup(self.tmp.cleanup)

        # La préparation affiche sa progression, inutile dans les tests
        printer = mock.patch("builtins.print")
        printer.start()
        self.addCleanup(printer.stop)

        for folder in ("RENAULT_Clio_2019Present", "RENAULT_Clio_RS_2013Present"):
            make_images(self.source, "train", folder, 6)
            make_images(self.source, "test", folder, 2)
        for folder in ("FORD_Focus_20122015", "BMW_M3_20102013", "RENAULT_Clio_V6_20032005"):
            make_images(self.source, "train", folder, 3)
            make_images(self.source, "test", folder, 1)

        self.catalog = CarCatalog([
            Car("clio", "Renault", "Clio", 2013, None, (
                "RENAULT_Clio_2019Present", "RENAULT_Clio_RS_2013Present",
            )),
        ])

    def preparer(self, **options):
        return DatasetPreparer(
            self.catalog, self.source, self.destination,
            min_train=5, other_train=10, other_test=10, **options,
        )

    def test_merges_sources_and_caps_images(self):
        self.preparer(max_train=8, max_test=3).prepare()

        self.assertEqual(count_images(self.destination, "train", "clio"), 8)
        self.assertEqual(count_images(self.destination, "test", "clio"), 3)

    def test_other_class_skips_known_families(self):
        self.preparer(max_train=50, max_test=50).prepare()

        # Seuls Ford Focus et BMW M3 : la Clio V6 appartient à la famille Clio.
        self.assertEqual(count_images(self.destination, "train", OTHER_CLASS), 2)
        names = [path.name for path in (self.destination / "train" / OTHER_CLASS).iterdir()]
        self.assertFalse(any(name.startswith("RENAULT") for name in names))

    def test_rejects_missing_source_folder(self):
        self.catalog = CarCatalog([
            Car("x", "X", "X", 2000, None, ("INEXISTANT_X_2000Present",)),
        ])

        with self.assertRaises(FileNotFoundError):
            self.preparer().prepare()

    def test_rejects_cars_with_too_few_images(self):
        with self.assertRaises(ValueError):
            DatasetPreparer(
                self.catalog, self.source, self.destination, min_train=100,
            ).prepare()

    def test_replaces_previous_destination(self):
        make_images(self.destination, "train", "ancienne_voiture", 2)

        self.preparer().prepare()

        self.assertFalse((self.destination / "train" / "ancienne_voiture").exists())

    def test_family_handles_both_folder_styles(self):
        self.assertEqual(family("RENAULT_Clio_2019Present"), ("renault", "clio"))
        self.assertEqual(family("2017_Dacia_Duster"), ("dacia", "duster"))


if __name__ == "__main__":
    unittest.main()
