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
        self.user_photos = root / "user"
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
        options = {"other_train": 10, "other_test": 10, **options}
        return DatasetPreparer(
            self.catalog, self.source, self.destination, self.user_photos,
            min_train=5, **options,
        )

    def test_merges_sources_and_caps_images(self):
        self.preparer(max_train=8, max_test=3).prepare()

        self.assertEqual(count_images(self.destination, "train", "clio"), 8)
        self.assertEqual(count_images(self.destination, "test", "clio"), 3)

    def test_unused_test_photos_and_user_photos_go_to_training(self):
        make_images(self.user_photos, ".", "clio", 2)

        self.preparer(max_test=1).prepare()

        # 12 photos d'entraînement + 3 photos de test non tirées + 2 de l'application
        self.assertEqual(count_images(self.destination, "train", "clio"), 17)
        self.assertEqual(count_images(self.destination, "test", "clio"), 1)

    def test_other_class_skips_known_families(self):
        self.preparer(max_train=50, max_test=50).prepare()

        # Les 3 photos de Ford Focus et de BMW M3 : la Clio V6 appartient à la famille Clio.
        self.assertEqual(count_images(self.destination, "train", OTHER_CLASS), 6)
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

    def test_links_images_instead_of_copying(self):
        self.preparer().prepare()

        source = self.source / "train" / "RENAULT_Clio_2019Present" / "RENAULT_Clio_2019Present_0.jpg"
        linked = self.destination / "train" / "clio" / source.name
        self.assertTrue(linked.samefile(source))

    @mock.patch("src.dataset_preparer.os.link", side_effect=OSError)
    def test_copies_when_links_are_impossible(self, _):
        self.preparer().prepare()

        self.assertEqual(count_images(self.destination, "train", "clio"), 12)

    def test_reads_folders_of_other_datasets(self):
        extra = Path(self.tmp.name) / "extra"
        make_images(extra, "train", "DVM_renault_clio", 4)
        make_images(extra, "test", "DVM_renault_clio", 2)
        self.catalog = CarCatalog([
            Car("clio", "Renault", "Clio", 2013, None, ("RENAULT_Clio_2019Present", "DVM_renault_clio")),
        ])

        self.preparer(extra=extra, max_test=50).prepare()

        self.assertEqual(count_images(self.destination, "train", "clio"), 10)
        self.assertEqual(count_images(self.destination, "test", "clio"), 4)

    def test_other_class_skips_cars_known_by_name(self):
        self.catalog = CarCatalog([
            Car("focus", "Ford", "Focus", 2012, None, ("RENAULT_Clio_2019Present",)),
        ])

        self.preparer(max_train=50, max_test=50).prepare()

        names = [path.name for path in (self.destination / "train" / OTHER_CLASS).iterdir()]
        self.assertFalse(any(name.startswith("FORD") for name in names))

    def test_other_class_mixes_cars_before_taking_more_photos(self):
        self.preparer(max_train=50, max_test=50, other_train=2).prepare()

        names = sorted(path.name.split("_")[0] for path in (self.destination / "train" / OTHER_CLASS).iterdir())
        self.assertEqual(names, ["BMW", "FORD"])

    def test_other_class_uses_small_models_of_other_datasets(self):
        extra = Path(self.tmp.name) / "extra"
        make_images(extra, "train", "VMMR_lotus_esprit", 2)
        make_images(extra, "train", "DVM_renault_clio_rs", 2)

        self.preparer(extra=extra, max_train=50, max_test=50).prepare()

        names = [path.name for path in (self.destination / "train" / OTHER_CLASS).iterdir()]
        self.assertEqual(sum(name.startswith("VMMR_lotus") for name in names), 2)
        # Une Clio RS reste une Clio, même dans un autre dataset
        self.assertFalse(any(name.startswith("DVM_renault") for name in names))

    def test_family_handles_both_folder_styles(self):
        self.assertEqual(family("RENAULT_Clio_2019Present"), ("renault", "clio"))
        self.assertEqual(family("2017_Dacia_Duster"), ("dacia", "duster"))


if __name__ == "__main__":
    unittest.main()
