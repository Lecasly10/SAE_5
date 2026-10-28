import csv
import json
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from src.config import CARS_PATH
from src.images import list_images

BRAND_NAMES = {
    "ALFAROMEO": "Alfa Romeo",
    "ASTONMARTIN": "Aston Martin",
    "CITROEN": "Citroën",
    "DSAUTOMOBILES": "DS Automobiles",
    "KIA": "Kia",
    "LANDROVER": "Land Rover",
    "MARUTISUZUKI": "Maruti Suzuki",
    "MCLAREN": "McLaren",
    "MERCEDESBENZ": "Mercedes-Benz",
    "MercedesAMG": "Mercedes-AMG",
    "RAMTrucks": "RAM",
    "ROLLSROYCE": "Rolls-Royce",
    "SEAT": "SEAT",
    "SSANGYONG": "SsangYong",
    "TATAMOTORS": "Tata",
}

# Carrosseries et finitions d'un même modèle : 5 portes, break, RS...
VARIANT_WORDS = re.compile(
    r"\b(\d\s*doors?|estate|sedan|saloon|coupe|cabrio|cabriolet|convertible|wagon|"
    r"hatch|hatchback|sw|tourer|touring|sportback|break|lwb|swb|gt|gti|rs|st|4x4|"
    r"limousine|van|variant|avant|tmodell|kombi|sportwagon|sports|shooting|brake|"
    r"spider|spyder|roadster|targa|hardtop|gran|lci|facelift|single|double|crew|"
    r"extended|cab)\b",
    re.IGNORECASE,
)
YEARS_FOLDER = re.compile(r"\d{8}|\d{4}Present")
# Code de châssis en fin de nom : "3 Series E90" et "3 Series E91" sont la même voiture
CHASSIS_CODE = re.compile(r"\s+[A-Z]{1,2}\d{1,3}[A-Z]?$")

# Deux variantes sorties à 2 ans d'écart au plus font partie de la même génération
GENERATION_SPAN = 2


@dataclass(frozen=True)
class Variant:
    folder: str
    brand: str
    model: str
    from_year: int
    to_year: int | None
    images: int


def brand_name(raw):
    if raw in BRAND_NAMES:
        return BRAND_NAMES[raw]
    if not raw.isupper() or len(raw) <= 3:
        return raw
    return raw.capitalize()


def base_model(raw_brand, raw_model):
    """Nom du modèle sans la marque ni la carrosserie : "ALFA ROMEO Giulia
    Sedan" donne "Giulia"."""
    brand = r"[\s-]*".join(re.escape(letter) for letter in raw_brand)
    model = re.sub(rf"^(?:{brand}\s*)+", "", raw_model, flags=re.IGNORECASE)
    base = " ".join(VARIANT_WORDS.sub(" ", model).split())
    return base or model.strip()


def model_key(model):
    """Clé qui rassemble les noms d'un même modèle : "GLK-Klasse X204" et "GLK",
    "C-Class" et "CClass"."""
    text = CHASSIS_CODE.sub("", model)
    text = re.sub(r"(klasse|class)\b", "", text, flags=re.IGNORECASE)
    return re.sub(r"[^a-z0-9]", "", text.lower()) or model.lower()


def read_variants(csv_path, train_dir):
    """Une variante par dossier du dataset dont les années sont dans le nom
    (RENAULT_Clio_RS_20092013 ou RENAULT_Clio_2019Present)."""
    csv.field_size_limit(10**8)
    variants = {}

    with open(csv_path, encoding="utf-8") as file:
        for row in csv.DictReader(file):
            _, _, model_dir, years_dir = row["dir_path"].split("/")
            folder = f"{model_dir}_{years_dir}"
            years = [int(year) for year in re.findall(r"\d{4}", row["production_years"])]

            if folder in variants or not YEARS_FOLDER.fullmatch(years_dir) or not years:
                continue
            if not (Path(train_dir) / folder).is_dir():
                continue

            variants[folder] = Variant(
                folder=folder,
                brand=brand_name(row["brand"]),
                model=base_model(row["brand"], row["model"]),
                from_year=min(years),
                to_year=None if years_dir.endswith("Present") else max(years),
                images=len(list_images(Path(train_dir) / folder)),
            )

    return list(variants.values())


def group_generations(variants):
    models = defaultdict(list)
    for variant in variants:
        models[(variant.brand, model_key(variant.model))].append(variant)

    generations = []
    for same_model in models.values():
        current = []
        for variant in sorted(same_model, key=lambda v: (v.from_year, v.folder)):
            if current and variant.from_year - current[0].from_year > GENERATION_SPAN:
                generations.append(current)
                current = []
            current.append(variant)
        generations.append(current)

    return generations


def slug(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def describe(generation):
    first = generation[0]
    model = max(generation, key=lambda v: v.images).model
    ended = [v.to_year for v in generation if v.to_year is not None]
    to_year = max(ended) if ended else None

    return {
        "id": slug(f"{first.brand} {model} {first.from_year} {to_year or 'present'}"),
        "brand": first.brand,
        "model": model,
        "from_year": first.from_year,
        "to_year": to_year,
        "sources": sorted(v.folder for v in generation),
    }


def build_catalog(csv_path, train_dir, min_images, known=()):
    """Ajoute aux voitures déjà connues chaque génération du dataset qui a
    assez d'images et dont aucun dossier n'est déjà utilisé."""
    cars = list(known)
    used = {name for car in cars for name in car["sources"]}

    for generation in group_generations(read_variants(csv_path, train_dir)):
        enough = sum(v.images for v in generation) >= min_images
        if enough and not used & {v.folder for v in generation}:
            cars.append(describe(generation))

    return sorted(cars, key=lambda car: car["id"])


def save_catalog(cars, path=CARS_PATH):
    with open(path, "w", encoding="utf-8") as file:
        json.dump({"cars": cars}, file, ensure_ascii=False, indent=2)
        file.write("\n")
