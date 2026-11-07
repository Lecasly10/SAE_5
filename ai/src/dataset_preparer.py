import os
import random
import re
import shutil
from pathlib import Path

from src.config import DATASET_DIR, OTHER_CLASS, SMALL_DATASET_DIR, USER_PHOTOS_DIR
from src.images import list_images

MIN_TRAIN_IMAGES = 50
# Assez pour bien apprendre une voiture, sans que l'entraînement dure plus de
# deux nuits avec DVM-Car et VMMRdb
MAX_TRAIN_IMAGES = 500


def link_or_copy(source, destination):
    """Un lien physique ne prend pas de place sur le disque. Copie seulement si
    les deux dossiers ne sont pas sur le même disque."""
    try:
        os.link(source, destination)
    except OSError:
        shutil.copy2(source, destination)


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
    plus une classe « autre » faite de voitures absentes de la liste.

    max_train=None garde toutes les photos. Les photos de test non tirées et
    les photos confirmées dans l'application vont aussi à l'entraînement.
    Les dossiers d'une voiture peuvent aussi venir de `extra` (DVM-Car, VMMRdb)."""

    def __init__(
        self,
        catalog,
        source=DATASET_DIR,
        destination=SMALL_DATASET_DIR,
        user_photos=USER_PHOTOS_DIR,
        extra=None,
        max_train=MAX_TRAIN_IMAGES,
        max_test=60,
        other_train=2000,
        other_test=300,
        min_train=MIN_TRAIN_IMAGES,
        seed=42,
    ):
        self.catalog = catalog
        self.source = Path(source)
        self.destination = Path(destination)
        self.user_photos = Path(user_photos)
        self.roots = [self.source] + ([Path(extra)] if extra else [])
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
            test_pool = self.dataset_images(car, "test")
            test = self.sample(test_pool, self.max_test)
            unused_test = sorted(set(test_pool) - set(test))
            train = self.sample(self.dataset_images(car, "train") + unused_test, self.max_train)

            self.copy_class("train", car.id, train + self.user_images(car))
            self.copy_class("test", car.id, test)

        self.prepare_other_class()

    def check_sources(self):
        missing = [
            f"{car.id} : {name}"
            for car in self.catalog
            for name in car.sources
            if not self.folder("train", name).is_dir()
        ]
        if missing:
            raise FileNotFoundError(
                "Dossiers introuvables dans le grand dataset :\n" + "\n".join(missing)
            )

        too_small = []
        for car in self.catalog:
            count = sum(
                len(list_images(self.folder("train", name)))
                for name in car.sources
            )
            if count < self.min_train:
                too_small.append(f"{car.id} : {count} images")
        if too_small:
            raise ValueError(
                f"Moins de {self.min_train} images d'entraînement :\n"
                + "\n".join(too_small)
            )

    def folder(self, split, name):
        """Dossier `name` dans le grand dataset ou dans `extra`."""
        for root in self.roots:
            if (root / "train" / name).is_dir():
                return root / split / name
        return self.source / split / name

    def dataset_images(self, car, split):
        return [
            image
            for name in car.sources
            if self.folder(split, name).is_dir()
            for image in list_images(self.folder(split, name))
        ]

    def user_images(self, car):
        folder = self.user_photos / car.id
        return list_images(folder) if folder.is_dir() else []

    def sample(self, files, limit):
        if limit is None or len(files) <= limit:
            return files
        return sorted(self.random.sample(files, limit))

    def prepare_other_class(self):
        used = {name for car in self.catalog for name in car.sources}
        # Aussi par nom : une voiture venue de DVM-Car ne doit pas finir dans
        # « autre » avec les photos du grand dataset
        known_families = {family(name) for name in used} | {
            (re.split(r"[\s-]", car.brand)[0].lower(), car.model.split()[0].lower())
            for car in self.catalog
        }
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
            link_or_copy(file, destination)

        print(f"{split} - {class_name}: {len(files)} images")
