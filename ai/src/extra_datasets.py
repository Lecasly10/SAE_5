import csv
import random
import re
import shutil
import zipfile
from collections import defaultdict
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageOps

from src.images import IMAGE_SUFFIXES, crop_to_box

# Une ligne par dossier créé, lue par catalog_builder
FIELDS = ["folder", "brand", "model", "from_year", "to_year"]
YEAR = re.compile(r"^(19|20)\d{2}$")


def dvm_label(name):
    """resized_DVM/Abarth/124 Spider/2017/Black/photo.jpg donne
    ("Abarth", "124 Spider", 2017)."""
    parts = name.split("/")
    if len(parts) < 6 or not YEAR.match(parts[-3]):
        return None
    return parts[-5], parts[-4], int(parts[-3])


def vmmr_label(name):
    """VMMRdb/honda_civic_2002/photo.jpg donne ("honda", "civic", 2002).
    Les espaces restent : mercedes benz_c230_2003."""
    parts = name.split("/")
    if len(parts) < 2:
        return None
    pieces = parts[-2].split("_")
    if len(pieces) < 3 or not YEAR.match(pieces[-1]):
        return None
    return pieces[0], " ".join(pieces[1:-1]), int(pieces[-1])


def slug(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


class ExtraDataset:
    """Convertit une archive zip (DVM-Car ou VMMRdb) au format du grand
    dataset : destination/train/<dossier>/ et destination/test/<dossier>/,
    un dossier par marque et modèle (toutes années confondues), plus
    destination/<nom>.csv qui décrit chaque dossier.

    Les photos restent dans le zip jusqu'à la conversion : rien n'est
    décompressé en entier. Un dossier déjà converti n'est pas refait."""

    # 700 photos suffisent : prepare en garde 500 pour l'entraînement par voiture
    def __init__(self, name, archive, label, destination, max_images=700,
                 test_share=0.1, detector=None, max_size=400, seed=42):
        self.name = name
        self.archive = Path(archive)
        self.label = label
        self.destination = Path(destination)
        self.max_images = max_images
        self.test_share = test_share
        # Recadre sur la voiture, comme le serveur avant la reconnaissance
        self.detector = detector
        self.max_size = max_size
        self.seed = seed

    def groups(self, names):
        groups = defaultdict(list)
        for name in names:
            label = self.label(name) if Path(name).suffix.lower() in IMAGE_SUFFIXES else None
            if label:
                brand, model, year = label
                groups[(brand, model)].append((name, year))
        return groups

    def convert(self):
        rows = []
        with zipfile.ZipFile(self.archive) as archive:
            groups = self.groups(archive.namelist())
            for (brand, model), entries in sorted(groups.items()):
                folder = f"{self.name}_{slug(brand)}_{slug(model)}"
                years = [year for _, year in entries]
                rows.append({"folder": folder, "brand": brand, "model": model,
                             "from_year": min(years), "to_year": max(years)})
                if not (self.destination / "train" / folder).is_dir():
                    self.convert_group(archive, folder, [name for name, _ in entries])

        self.destination.mkdir(parents=True, exist_ok=True)
        with open(self.destination / f"{self.name}.csv", "w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(file, fieldnames=FIELDS)
            writer.writeheader()
            writer.writerows(rows)
        print(f"{self.name} : {len(rows)} modèles")
        return rows

    def convert_group(self, archive, folder, names):
        # Même tirage d'une conversion à l'autre
        names = sorted(names)
        picker = random.Random(f"{self.seed}-{folder}")
        if len(names) > self.max_images:
            names = picker.sample(names, self.max_images)
        picker.shuffle(names)
        test_count = round(len(names) * self.test_share)

        # Écrit dans <dossier>.part puis renommé : un dossier coupé en plein
        # milieu sera refait à la prochaine conversion
        parts = {split: self.destination / split / f"{folder}.part" for split in ("train", "test")}
        for part in parts.values():
            shutil.rmtree(part, ignore_errors=True)
            part.mkdir(parents=True)

        saved = 0
        for index, name in enumerate(names):
            split = "test" if index < test_count else "train"
            saved += self.save(archive.read(name), parts[split] / f"{folder}_{index}.jpg")

        for split, part in parts.items():
            part.rename(self.destination / split / folder)
        print(f"{folder} : {saved} images")

    def save(self, data, target):
        try:
            image = ImageOps.exif_transpose(Image.open(BytesIO(data))).convert("RGB")
        except (OSError, Image.DecompressionBombError):
            return 0

        if self.detector:
            box = self.detector.detect(image)
            if box:
                image = crop_to_box(image, box)
        image.thumbnail((self.max_size, self.max_size))
        image.save(target, "JPEG", quality=90)
        return 1
