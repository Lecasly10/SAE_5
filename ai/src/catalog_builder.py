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

# Carrosseries, finitions et versions d'un même modèle : 5 portes, break, RS,
# xDrive, Carrera 4S, Turbo S, GTS...
VARIANT_WORDS = re.compile(
    r"\b(\d\s*doors?|estate|sedan|saloon|coupe|cabrio|cabriolet|convertible|wagon|"
    r"hatch|hatchback|sw|tourer|touring|sportback|break|lwb|swb|gt|gti|rs|st|4x4|"
    r"limousine|van|variant|avant|tmodell|kombi|sportwagon|sports|shooting|brake|"
    r"spider|spyder|roadster|targa|hardtop|gran|lci|facelift|single|double|crew|"
    r"extended|cab|competition|xdrive|sdrive|quattro|4matic|4motion|awd|volante|"
    r"carrera(?:\s+4s?|\s+s)?|turbo(?:\s+s)?|4s|gt2|gt3|gts|gtc|gtd|gte|alltrack|"
    r"speed|supersports|shelby|stingray|amg|cs|csl|diesel|e-?hybrid|type\s*-?r|si|us|"
    r"tdi|allroad|v8|v10|v12|performance|rwd)\b",
    re.IGNORECASE,
)
YEARS_FOLDER = re.compile(r"\d{8}|\d{4}Present")
# Codes de génération et lettres de version : "3 Series E90" et "3 Series F30",
# "911 997" et "911 991", "Golf VI" et "Golf VII", "X5" et "X5 M" sont la même voiture
GENERATION_CODES = (
    re.compile(r"\s+[A-Z]{1,2}\s?\d{1,3}[A-Z]?$"),
    re.compile(r"(?<=\s)9\d{2,3}\b"),
    re.compile(r"\b(?:II|III|IV|VI|VII|VIII|IX)\b"),
    re.compile(r"(?<=\w)\s+[MSL]$"),
)
# Versions sportives d'Audi : "RS 3" et "S3" sont des A3
AUDI_SPORT = re.compile(r"\bR?S\s*(\d)\b")


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


def clean_model(model):
    """Nom commun à toutes les versions et générations d'un modèle :
    "911 Carrera 4S 991" donne "911", "3 Series Touring E91" donne "3 Series"."""
    text = VARIANT_WORDS.sub(" ", model)
    for code in GENERATION_CODES:
        text = code.sub(" ", " ".join(text.split()))
    return " ".join(text.split()) or model.strip()


def base_model(raw_brand, raw_model):
    """Nom du modèle sans la marque, la carrosserie ni la génération :
    "ALFA ROMEO Giulia Sedan" donne "Giulia"."""
    brand = r"[\s-]*".join(re.escape(letter) for letter in raw_brand)
    model = re.sub(rf"^(?:{brand}\s*)+", "", raw_model, flags=re.IGNORECASE)
    if brand_name(raw_brand) == "Audi":
        model = AUDI_SPORT.sub(r"A\1", model)
    return clean_model(model)


def model_key(model):
    """Clé qui rassemble les noms d'un même modèle : "GLK-Klasse X204" et "GLK",
    "C-Class" et "CClass"."""
    text = re.sub(r"(klasse|class)\b", "", clean_model(model), flags=re.IGNORECASE)
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


def group_models(variants, known):
    """Regroupe les dossiers d'une même marque et d'un même modèle, toutes
    générations confondues. Les dossiers d'une voiture déjà connue restent
    ensemble."""
    parent = {}

    def root(item):
        parent.setdefault(item, item)
        while parent[item] != item:
            parent[item] = parent[parent[item]]
            item = parent[item]
        return item

    def join(first, second):
        parent[root(first)] = root(second)

    for variant in variants.values():
        join(variant.folder, (variant.brand, model_key(variant.model)))
    for car in known:
        for name in car["sources"]:
            join(name, (car["brand"], model_key(car["model"])))

    groups = defaultdict(list)
    for folder, variant in variants.items():
        groups[root(folder)].append(variant)
    return list(groups.values())


def slug(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def describe(group):
    biggest = max(group, key=lambda v: v.images)
    model = clean_model(biggest.model)
    ended = [v.to_year for v in group]

    return {
        "id": slug(f"{biggest.brand} {model}"),
        "brand": biggest.brand,
        "model": model,
        "from_year": min(v.from_year for v in group),
        "to_year": None if None in ended else max(ended),
        "sources": sorted(v.folder for v in group),
    }


def known_variants(known, train_dir):
    """Dossiers des voitures déjà connues, dont ceux absents du CSV."""
    return {
        name: Variant(name, car["brand"], car["model"], car["from_year"], car["to_year"],
                      len(list_images(Path(train_dir) / name)))
        for car in known
        for name in car["sources"]
        if (Path(train_dir) / name).is_dir()
    }


def build_catalog(csv_path, train_dir, min_images, known=()):
    """Une voiture par marque et modèle, quelle que soit la génération, si elle
    a assez d'images. Les identifiants des voitures déjà connues qu'elle
    remplace sont gardés dans « aliases », pour retrouver les anciennes photos."""
    variants = known_variants(known, train_dir)
    variants.update((v.folder, v) for v in read_variants(csv_path, train_dir))
    cars = {}

    for group in group_models(variants, known):
        if sum(v.images for v in group) < min_images:
            continue
        car = describe(group)
        if car["id"] in cars:
            car["id"] = f"{car['id']}_{car['from_year']}"
        folders = set(car["sources"])
        car["aliases"] = sorted(
            {old for known_car in known if folders & set(known_car["sources"])
             for old in (known_car["id"], *known_car.get("aliases", ()))} - {car["id"]}
        )
        cars[car["id"]] = car

    return sorted(cars.values(), key=lambda car: car["id"])


def save_catalog(cars, path=CARS_PATH):
    with open(path, "w", encoding="utf-8") as file:
        json.dump({"cars": cars}, file, ensure_ascii=False, indent=2)
        file.write("\n")
