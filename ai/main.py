import argparse
import os
import shutil
from pathlib import Path

from src.config import (
    DATASET_DIR,
    DOWNLOADS_DIR,
    EXTRA_DATASET_DIR,
    SAMPLE_IMAGE,
    TRAINING_BACKUP_DIR,
)

# Les modules qui utilisent TensorFlow sont importés au dernier moment pour que
# l'analyse et la préparation du dataset marchent sans TensorFlow installé.


def analyze(args):
    from src.dataset_analyzer import DatasetAnalyzer
    from src.dataset_preparer import MIN_TRAIN_IMAGES

    DatasetAnalyzer(args.source, MIN_TRAIN_IMAGES).display_classes()


def catalog(args):
    from src.catalog import load_entries
    from src.catalog_builder import build_catalog, save_catalog
    from src.dataset_preparer import MIN_TRAIN_IMAGES

    cars = build_catalog(
        Path(args.source) / "data_full.csv",
        Path(args.source) / "train",
        MIN_TRAIN_IMAGES,
        known=load_entries(),
        extra_dir=extra_dir(),
    )
    save_catalog(cars)
    print(f"{len(cars)} voitures de {len({car['brand'] for car in cars})} marques")


def extra_dir():
    """DVM-Car et VMMRdb convertis, s'ils existent."""
    return EXTRA_DATASET_DIR if (EXTRA_DATASET_DIR / "train").is_dir() else None


def extra(args):
    import csv
    import io
    import zipfile

    from src.detector import CarDetector
    from src.extra_datasets import ExtraDataset, dvm_label, vmmr_label

    downloads = Path(args.downloads)
    dvm = downloads / "dvm" / "resized_DVM_v2.zip"
    vmmr = downloads / "vmmr" / "VMMRdb.zip"

    if dvm.exists():
        # Photos refusées par le contrôle qualité des auteurs de DVM-Car
        with zipfile.ZipFile(downloads / "dvm" / "tables_V2.0.zip") as tables:
            rows = csv.reader(io.TextIOWrapper(tables.open("Image_table.csv"), encoding="utf-8"))
            refused = {row[2].strip() for row in rows if row[4].strip() == "N"}

        def label(name):
            return None if name.rsplit("/", 1)[-1] in refused else dvm_label(name)

        ExtraDataset("DVM", dvm, label, EXTRA_DATASET_DIR).convert()

    if vmmr.exists():
        # Photos prises dans la rue : la voiture est recadrée comme dans l'application
        ExtraDataset("VMMR", vmmr, vmmr_label, EXTRA_DATASET_DIR, detector=CarDetector()).convert()


def market(args):
    from src.catalog import CarCatalog
    from src.market import build_market, dvm_market, save_market, vmmr_counts

    downloads = Path(args.downloads)
    tables = downloads / "dvm" / "tables_V2.0.zip"
    vmmr = downloads / "vmmr" / "VMMRdb.zip"
    dvm = dvm_market(tables) if tables.exists() else {}
    counts = vmmr_counts(vmmr) if vmmr.exists() else {}

    market = build_market(CarCatalog.load(), dvm, counts)
    save_market(market)
    known = sum(1 for car in market.values() if car["price"] is not None)
    print(f"{len(market)} voitures, {known} avec un prix neuf")


def collect(args):
    from pymongo import MongoClient
    from pymongo.errors import PyMongoError

    from src.catalog import CarCatalog
    from src.config import DB_NAME
    from src.detector import CarDetector
    from src.user_photos import collect_user_photos

    uri = os.environ.get("MONGODB_URI")
    if not uri:
        print("MONGODB_URI absent : pas de photos de l'application")
        return

    # Une base injoignable ne doit pas empêcher l'entraînement de la nuit
    try:
        with MongoClient(uri, serverSelectionTimeoutMS=15000) as client:
            added = collect_user_photos(client[DB_NAME], CarCatalog.load(), CarDetector())
    except PyMongoError as error:
        print(f"Base injoignable, photos de l'application ignorées : {error}")
        return

    print(f"{added} nouvelle(s) photo(s) de l'application")


def prepare(args):
    from src.catalog import CarCatalog
    from src.dataset_preparer import DatasetPreparer

    DatasetPreparer(CarCatalog.load(), source=args.source, extra=extra_dir()).prepare()
    # Un entraînement commencé sur les anciennes photos ne peut pas reprendre
    shutil.rmtree(TRAINING_BACKUP_DIR, ignore_errors=True)


def train(args):
    from src.trainer import CarTrainer

    CarTrainer().run()


def retrain(args):
    """Tout l'entraînement d'une nuit : photos de l'application, dataset complet,
    entraînement, puis évaluation si le nouveau modèle est meilleur."""
    from src.trainer import CarTrainer

    collect(args)
    prepare(args)
    if CarTrainer().run():
        evaluate(args)


def evaluate(args):
    from src.evaluate import main

    main()


def predict(args):
    from src.predictor import CarPredictor

    CarPredictor().display_predictions(args.image)


COMMANDS = {
    "analyze": ("Analyser le dataset", analyze),
    "extra": ("Convertir DVM-Car et VMMRdb téléchargés", extra),
    "catalog": ("Créer la liste des voitures (cars.json)", catalog),
    "market": ("Prix neuf et fréquence de chaque voiture (market.json)", market),
    "collect": ("Récupérer les photos confirmées dans l'application", collect),
    "prepare": ("Préparer dataset_small", prepare),
    "train": ("Entraîner le modèle", train),
    "retrain": ("Tout réentraîner (collect, prepare, train, evaluate)", retrain),
    "evaluate": ("Évaluer le modèle", evaluate),
    "predict": ("Tester une image", predict),
}


def build_parser():
    parser = argparse.ArgumentParser(description="Outils IA de Spot'It")
    subparsers = parser.add_subparsers(dest="command")

    for name, (help_text, function) in COMMANDS.items():
        command = subparsers.add_parser(name, help=help_text)
        command.set_defaults(function=function)

        if name in ("analyze", "catalog", "prepare", "retrain"):
            command.add_argument(
                "--source", default=DATASET_DIR,
                help="dossier du grand dataset, avec train/, test/ et data_full.csv",
            )
        if name in ("extra", "market"):
            command.add_argument(
                "--downloads", default=DOWNLOADS_DIR,
                help="dossier avec dvm/resized_DVM_v2.zip, dvm/tables_V2.0.zip et vmmr/VMMRdb.zip",
            )
        if name == "predict":
            command.add_argument("image", nargs="?", default=SAMPLE_IMAGE)

    return parser


def run_menu(parser):
    names = list(COMMANDS)

    while True:
        print("\n========== SPOT'IT IA ==========\n")
        for number, name in enumerate(names, start=1):
            print(f"{number} - {COMMANDS[name][0]}")
        print("0 - Quitter")

        choice = input("\nChoix : ")

        if choice == "0":
            return
        if choice.isdigit() and 1 <= int(choice) <= len(names):
            arguments = parser.parse_args([names[int(choice) - 1]])
            arguments.function(arguments)
        else:
            print("\nChoix invalide.")


def main():
    parser = build_parser()
    arguments = parser.parse_args()

    if arguments.command:
        arguments.function(arguments)
    else:
        run_menu(parser)


if __name__ == "__main__":
    main()
