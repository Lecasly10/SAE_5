import random
import shutil
from pathlib import Path

from src.config import DATASET_DIR, OTHER_CLASS, SMALL_DATASET_DIR
from src.images import list_images

MIN_TRAIN_IMAGES = 50


def family(folder_name):
    """(marque, premier mot du modèle) d'un dossier du grand dataset.

    Les dossiers ressemblent à RENAULT_Clio_2019Present ou, pour certains,
    à 2017_Dacia_Duster (année en premier)."""
    parts = folder_name.split("_")
    if parts[0].isdigit():
        parts = parts[1:]
    return tuple(part.lower() for part in parts[:2])


class DatasetPreparer:
    """Construit dataset_small à partir du grand dataset et de cars.json :
    une voiture = un dossier regroupant plusieurs dossiers du grand dataset,
    plus une classe « autre » faite de voitures absentes de la liste."""

    def __init__(
        self,
        catalog,
        source=DATASET_DIR,
        destination=SMALL_DATASET_DIR,
        max_train=150,
        max_test=40,
        other_train=600,
        other_test=150,
        min_train=MIN_TRAIN_IMAGES,
        seed=42,
    ):
        self.catalog = catalog
        self.source = Path(source)
        self.destination = Path(destination)
        self.max_train = max_train
        self.max_test = max_test
        self.other_train = other_train
        self.other_test = other_test
        self.min_train = min_train
        self.random = random.Random(seed)

    def prepare(self):
        self.check_sources()

        if self.destination.exists():
            print(f"Remplacement de {self.destination}")
            shutil.rmtree(self.destination)

        for car in self.catalog:
            for split, limit in (("train", self.max_train), ("test", self.max_test)):
                files = [
                    image
                    for name in car.sources
                    for image in list_images(self.source / split / name)
                ]
                self.copy_class(split, car.id, self.sample(files, limit))

        self.prepare_other_class()

    def check_sources(self):
        missing = [
            f"{car.id} : {name}"
            for car in self.catalog
            for name in car.sources
            if not (self.source / "train" / name).is_dir()
        ]
        if missing:
            raise FileNotFoundError(
                "Dossiers introuvables dans le grand dataset :\n" + "\n".join(missing)
            )

        too_small = []
        for car in self.catalog:
            count = sum(
                len(list_images(self.source / "train" / name))
                for name in car.sources
            )
            if count < self.min_train:
                too_small.append(f"{car.id} : {count} images")
        if too_small:
            raise ValueError(
                f"Moins de {self.min_train} images d'entraînement :\n"
                + "\n".join(too_small)
            )

    def sample(self, files, limit):
        if len(files) <= limit:
            return files
        return sorted(self.random.sample(files, limit))

    def prepare_other_class(self):
        used = {name for car in self.catalog for name in car.sources}
        known_families = {family(name) for name in used}
        folders = sorted(
            folder.name
            for folder in (self.source / "train").iterdir()
            if folder.is_dir()
            and folder.name not in used
            and family(folder.name) not in known_families
        )

        for split, count in (("train", self.other_train), ("test", self.other_test)):
            files = self.one_image_per_folder(split, folders, count)
            self.copy_class(split, OTHER_CLASS, files)

    def one_image_per_folder(self, split, folders, count):
        files = []
        for name in self.random.sample(folders, min(count, len(folders))):
            images = list_images(self.source / split / name)
            if images:
                files.append(self.random.choice(images))
        return files

    def copy_class(self, split, class_name, files):
        target = self.destination / split / class_name
        target.mkdir(parents=True, exist_ok=True)

        for index, file in enumerate(files):
            destination = target / file.name
            if destination.exists():
                destination = target / f"{index}_{file.name}"
            shutil.copy2(file, destination)

        print(f"{split} - {class_name}: {len(files)} images")
